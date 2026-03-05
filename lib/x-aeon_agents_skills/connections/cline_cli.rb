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
          prompt_file = "#{temp_dir}/prompt.txt"
          File.write(prompt_file, payload[:messages].to_json)

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
            log_debug "Cline CLI exited with status: #{wait_thr.value.exitstatus}"
          end
          {
            body: stdout_lines.join("\n"),
            model: payload[:model]
          }
        end
      end

      private

      def log_debug(msg)
        puts "[DEBUG] - #{msg}" if @debug
      end

    end

  end

end
