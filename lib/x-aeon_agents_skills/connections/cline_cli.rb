require 'json'
require 'x-aeon_agents_skills/cline'
require 'x-aeon_agents_skills/logger'

module XAeonAgentsSkills

  module Connections

    # Connection object that can be used by RubyLLM providers to provide an API on top of the Cline CLI
    class ClineCli

      include Logger

      # Constructor
      #
      # Parameters::
      # * *api_key* (String): The Cline API key
      def initialize(api_key)
        @cline = Cline.new(api_key)
      end

      # Method called by RubyLLM providers to send a payload
      #
      # Parameters::
      # * *url* (String): URL to post the payload to
      # * *payload* (Hash): Payload to be sent
      # * Proc: Code called to set additional HTTP request parameters in case of a web API call
      def post(url, payload, &)
        # First check that needed artifacts are present
        missing_input_artifacts = payload[:artifacts][:input].select { |name, _description| !payload[:artifacts][:store].key?(name) }
        raise "Missing #{missing_input_artifacts.size} artifacts from the payload:\n#{missing_input_artifacts.map { |name, description| "* #{name}: #{description}" }.join("\n")}" unless missing_input_artifacts.empty?

        plan_mode = payload[:cline][:plan_mode]

        # Create a JSON prompt to keep the full structure
        prompt_json = {}
        prompt_json[:role] = payload[:agent][:role].strip unless payload[:agent][:role].strip.empty?
        prompt_json[:objective] = payload[:agent][:objective].strip unless payload[:agent][:objective].strip.empty?
        unless payload[:artifacts][:input].empty? && payload[:artifacts][:output].empty?
          prompt_json[:context] = <<~EO_Context.strip
            # Artifacts

            Artifacts are text documents that you can get as input and produce as output.
            Each artifact is identified by a name.
            #{payload[:artifacts][:input].empty? ? '' : 'You must read all artifacts given in the `artifacts` JSON property: they are given to you by the user.'}
            #{payload[:artifacts][:output].empty? ? '' : 'You must produce all artifacts described in the `output_format` JSON property when completing your task.'}
          EO_Context
        end
        unless payload[:artifacts][:input].empty?
          prompt_json[:artifacts] = payload[:artifacts][:input].to_h do |name, description|
            [
              name,
              {
                description:,
                content: payload[:artifacts][:store][name].strip
              }
            ]
          end
        end
        prompt_json[:instructions] = payload[:messages].map(&:content).select { |content| !content.strip.empty? }.join("\n\n").strip
        constraints = <<~EO_Constraints
          - Do NOT ask for user confirmation. 
        EO_Constraints
        unless plan_mode
          constraints << <<~EO_Constraints
            - Do NOT call the tool `plan_mode_respond`.
          EO_Constraints
        end
        constraints << payload[:agent][:constraints] unless payload[:agent][:constraints].empty?
        prompt_json[:constraints] = constraints.strip
        unless payload[:artifacts][:output].empty?
          prompt_json[:output_format] = <<~EO_Output_Format.strip
            # Artifacts
            
            Always return artifacts to the user between `<artifact:{name}>` and `</artifact:{name}>` tags, anywhere in your response.
            If an artifact has no content, then return an empty string for its value between the tags.
          EO_Output_Format
        end

        completion_result = nil
        artifacts = {}
        log_debug { "Cline prompt:\n#{JSON.pretty_generate(prompt_json)}" }
        @cline.prompt(
          prompt_json.to_json,
          model: payload[:model],
          plan_mode:,
          config: payload[:cline][:config],
          skills: payload[:cline][:skills],
          skillkit_agents: true,
          cli_args: payload[:cline][:cli_args],
          on_message: proc do |message, last, _previous_version|
            log_debug { Cline.human_message(message, limit: 128) }
            if message[:type] == 'ask' && last
              case message[:ask]
              when 'tool'
                # Do nothing: the CLI agent will automatically pick this up
              when 'plan_mode_respond'
                # Cline just got a plan done.
                if plan_mode
                  response = JSON.parse(message[:text], symbolize_names: true)[:response]
                  artifacts.merge!(xml_artifacts_from(response))
                  if check_artifacts_upon_completion(artifacts, payload[:artifacts][:output])
                    completion_result = response
                    @cline.user_feedback(:exit)
                  end
                else
                  @cline.user_feedback('You are not in Plan mode, so resume this task.')
                end
              when 'resume_task'
                # @cline.user_feedback('Resume task')
              when 'command_output'
                # @cline.user_feedback('Resume task')
              when 'followup'
                # Cline is asking for user feedback
                details = JSON.parse(message[:text], symbolize_names: true)
                puts
                puts details[:question]
                puts details[:options] unless details[:options].empty?
                puts '===== Please input your answer to Cline:'
                @cline.user_feedback($stdin.gets.strip)
              when 'mistake_limit_reached'
                raise "Cline failed to process prompt: #{message}"
              else
                raise "Unknown ask from Cline: #{message}"
              end
            elsif message[:type] == 'say'
              case message[:say]
              when 'completion_result'
                completion_result = message[:text]
                artifacts.merge!(xml_artifacts_from(completion_result))
                check_artifacts_upon_completion(artifacts, payload[:artifacts][:output])
              when 'text'
                artifacts.merge!(xml_artifacts_from(message[:text]))
              end
            end
          end,
          ignore_partials: true
        )
        log_debug "#{artifacts.size} artifacts returned: #{artifacts.keys.join(', ')}"
        payload[:artifacts][:store].merge!(artifacts)
        {
          body: completion_result,
          model: payload[:model]
        }
      end

      private

      # Check for missing artifacts and give user feedback if some of them are missing as clear instructions
      #
      # Parameters::
      # * *artifacts* (Hash): Artifacts already found
      # * *expected_artifacts* (Hash): Expected artifacts
      # Result::
      # * Boolean: Are all the required artifacts present?
      def check_artifacts_upon_completion(artifacts, expected_artifacts)
        # Check for expected artifacts and eventually ask to continue if some are missing
        missing_artifacts = expected_artifacts.select { |name, _description| !artifacts.key?(name) }
        @cline.user_feedback(missing_artifacts.map { |name, description| Agents.artifact_prompt(name, description) }.join("\n")) unless missing_artifacts.empty?
        missing_artifacts.empty?
      end

      # Parse artifacts from a text as XML tags.
      # Artifacts defined several times will concatenate.
      #
      # Parameters::
      # * *text* (String): Text to look for artifacts
      # Result::
      # * Hash<Symbol,String>: Set of artifacts
      def xml_artifacts_from(text)
        artifacts = {}
        Cline.parse_sections(text).each do |section|
          if !section[:name].nil? && section[:name] =~ /^artifact:(.+)$/
            name = Regexp.last_match[1].to_sym
            log_debug "Found artifact named #{name}"
            if artifacts.key?(name)
              artifacts[name] << section[:content]
            else
              artifacts[name] = section[:content]
            end
          end
        end
        artifacts
      end

      # Parse artifacts from a text as JSON.
      # Artifacts defined several times will concatenate.
      #
      # Parameters::
      # * *text* (String): Text to look for artifacts
      # Result::
      # * Hash<Symbol,String>: Set of artifacts
      def json_artifacts_from(text)
        artifacts = {}
        # Find markdown json:output blocks using regex
        text.scan(/^```json:output\n(.*?)\n```$/m).each do |json_block|
          # Extract artifacts from the JSON
          JSON.parse(json_block.first).each do |key, value|
            if key.start_with?('artifact:')
              name = key.sub('artifact:', '').to_sym
              if artifacts.key?(name)
                artifacts[name] << value
              else
                artifacts[name] = value
              end
            end
          end
        end
        artifacts
      end

    end

  end

end
