require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require 'x-aeon_agents_skills/helpers'

module XAeonAgentsSkills

  module Connections

    # Connection object that can be used by RubyLLM providers to provide an API on top of the Cline CLI
    class ClineCli

      # Constructor
      #
      # Parameters::
      # * *api_key* (String): The Cline API key
      # * *debug* (Boolean): Do we activate debug mode? [default: false]
      def initialize(api_key, debug: false)
        @api_key = api_key
        @debug = debug
      end

      # Method called by RubyLLM providers to send a payload
      #
      # Parameters::
      # * *url* (String): URL to post the payload to
      # * *payload* (Hash): Payload to be sent
      # * Proc: Code called to set additional HTTP request parameters in case of a web API call
      def post(url, payload, &)
        Dir.mktmpdir do |temp_dir|
          config_dir = "#{temp_dir}/cline_config"
          log_debug "Temporary Cline config dir: #{config_dir}"

          # Authenticate and generate the configuration directory
          system "cline auth --config #{config_dir} --provider cline --apikey #{@api_key} --modelid #{payload[:model]}", exception: true
          log_debug 'Cline CLI authenticated successfully'

          # Merge configuration options from payload into the globalState.json file
          global_state_path = "#{config_dir}/data/globalState.json"
          File.write(
            global_state_path,
            JSON.pretty_generate(
              Helpers.deep_merge(
                JSON.parse(File.read(global_state_path)),
                payload[:clinecli][:config]
              )
            )
          )

          # Generate prompt
          prompt_file = "#{temp_dir}/prompt.json"
          File.write(prompt_file, JSON.pretty_generate(payload[:messages]))

          # Select the skills to be hidden, so that only the selected ones are available to our agent
          selected_skills = payload[:clinecli][:skills].dup
          payload[:clinecli][:skills].each do |skill|
            dependent_skills(skill, selected_skills)
          end
          log_debug "#{selected_skills.size} selected skills: #{selected_skills.join(', ')}"
          all_skills = Dir['.cline/skills/*'].map { |skill_dir| File.basename(skill_dir) }
          missing_skills = selected_skills - all_skills
          raise "#{missing_skills.size} missing skills: #{missing_skills.join(', ')}" unless missing_skills.empty?
          hidden_skills = all_skills - selected_skills
          log_debug "#{hidden_skills.size} skills to disable: #{hidden_skills.join(', ')}"

          # We have to replace the AGENTS.md file with another version that is specific to this run and only has the selected skills.
          unique_idx = 0
          temp_agents_file = nil
          loop do
            temp_agents_file = ".clinerules/x-aeon-agents/AGENTS-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}-#{unique_idx}.md"
            break unless File.exist?(temp_agents_file)
            unique_idx += 1
          end
          agents_content = File.read('AGENTS.md')
          hidden_skills.each do |skill|
            escaped_skill = Regexp.escape(skill)
            agents_content.gsub!(/- \*\*#{escaped_skill}\*\*: [^\n]+\n/, '')
            agents_content.gsub!(/<skill>\n<name>#{escaped_skill}<\/name>.+?<\/skill>\n\n/m, '')
          end
          FileUtils.mkdir_p File.dirname(temp_agents_file)
          File.write(temp_agents_file, agents_content)
          begin
            # Create the workspace configuration file to disable hidden skills and AGENTS.md
            File.write(
              "#{Dir["#{config_dir}/data/workspaces/*"].first}/workspaceState.json",
              JSON.pretty_generate(
                {
                  localClineRulesToggles: {
                    canonize_path(temp_agents_file) => true
                  },
                  localAgentsRulesToggles: {
                    canonize_path('AGENTS.md') => false
                  },
                  localSkillsToggles: hidden_skills.to_h do |skill|
                    [
                      canonize_path(".cline/skills/#{skill}/SKILL.md"),
                      false
                    ]
                  end
                }
              )
            )

            # Run the agent
            cmd = "cline --config #{config_dir} --act #{@debug ? '--verbose' : ''} --json #{payload[:clinecli][:cli_args]} < #{prompt_file}"
            log_debug "Cline CLI: #{cmd}"
            stdout_lines = []
            Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
              stdin.close
              [
                Thread.new do
                  stdout.each_line do |line|
                    stdout_lines << line
                    $stdout.puts line if @debug
                  end
                end,
                Thread.new do
                  stderr.each_line do |line|
                    $stderr.puts line
                  end
                end
              ].each(&:join)
              exit_status = wait_thr.value.exitstatus
              log_debug "Cline CLI exited with status: #{exit_status}"
              raise "Cline CLI #{cmd} exited with status #{exit_status}" unless exit_status == 0
            end
            {
              body: stdout_lines.join("\n"),
              model: payload[:model]
            }
          ensure
            FileUtils.rm_f(temp_agents_file)
          end
        end
      end

      private

      def log_debug(msg)
        puts "[DEBUG] - #{msg}" if @debug
      end

      # Get all skills dependencies recursively from a skill.
      # Handle cyclic dependencies.
      #
      # Parameters::
      # * *skill* (String): Skill
      # * *found_skills* (Array<String>): In place array of skills that have already been found as dependencies
      def dependent_skills(skill, found_skills)
        deps = FrontMatterParser::Parser.parse_file(".cline/skills/#{skill}/SKILL.md").front_matter.dig('metadata', 'dependencies')
        unless deps.nil?
          deps.each do |skill_dep|
            skill_dep_name = skill_dep.include?(':') ? skill_dep.match(/^[^:]+:(.+)$/)[1] : skill_dep
            unless found_skills.include?(skill_dep_name)
              found_skills << skill_dep_name
              dependent_skills(skill_dep_name, found_skills)
            end
          end
        end
      end

      # Get a full file path as Cline config file is expecting it
      #
      # Parameters::
      # * *path* (String): A file path
      # Result::
      # * String: The corresponding file path that can be included in Cline config files
      def canonize_path(path)
        File.expand_path(path).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
      end

    end

  end

end
