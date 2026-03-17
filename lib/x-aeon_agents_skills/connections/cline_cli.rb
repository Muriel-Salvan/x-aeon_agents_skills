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

        # Create a JSON prompt to keep the full structure
        prompt_json = {}
        prompt_json[:role] = payload[:agent][:role] unless payload[:agent][:role].empty?
        prompt_json[:objective] = payload[:agent][:objective] unless payload[:agent][:objective].empty?
        context = ''
        unless payload[:artifacts][:input].empty? && payload[:artifacts][:output].empty?
          context << <<~EO_Context
            # Artifacts

            Artifacts are text documents that you can get as input and produce as output.
            Each artifact is identified by a name.
            #{payload[:artifacts][:input].empty? ? '' : 'You must read all artifacts given in the `artifacts` JSON property: they are given to you by the user.'}
            #{payload[:artifacts][:output].empty? ? '' : 'You must produce all artifacts given in the `output.artifacts` JSON property when completing your task.'}
          EO_Context
        end
        prompt_json[:context] = context unless context.empty?
        unless payload[:artifacts][:input].empty?
          prompt_json[:artifacts] = payload[:artifacts][:input].to_h do |name, description|
            [
              name,
              {
                description:,
                content: payload[:artifacts][:store][name]
              }
            ]
          end
        end
        prompt_json[:instructions] = payload[:messages].map(&:content).select { |content| !content.strip.empty? }
        constraints = <<~EO_Constraints
          - Do NOT ask for user confirmation. 
          - Do NOT call the tool `plan_mode_respond`.
        EO_Constraints
        constraints << payload[:agent][:constraints] unless payload[:agent][:constraints].empty?
        prompt_json[:constraints] = constraints
        output = {}
        output_format = ''
        unless payload[:artifacts][:output].empty?
          output[:artifacts] = payload[:artifacts][:output]
          output_format << <<~EO_Output_Format
            # Artifacts
            
            You must produce your artifacts by including their content between `<artifact:name>...</artifact:name>` tags in any of your responses. For example the artifact named `plan` should be returned to the user between `<artifact:plan>...</artifact:plan>` tags.
          EO_Output_Format
        end
        unless output_format.empty?
          output[:format] = output_format
          prompt_json[:output] = output
        end

        completion_result = nil
        artifacts = {}
        plan_mode = payload[:cline][:plan_mode]
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
                  artifacts.merge!(artifacts_from(response))
                  if artifacts.key?(:plan)
                    completion_result = response
                    @cline.user_feedback(:exit)
                  else
                    @cline.user_feedback <<~EO_Prompt
                      Tell the plan to the user in an artifact named `plan` and stop this task.

                      Artifacts are text documents that you can get as input and produce as output.
                      Each artifact is identified by a name.
                      You must produce your artifacts by including their content between `<artifact:name>...</artifact:name>` tags in any of your responses. For example the artifact named `plan` should be returned to the user between `<artifact:plan>...</artifact:plan>` tags.
                    EO_Prompt
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
              else
                raise "Unknown ask from Cline: #{message}"
              end
            elsif message[:type] == 'say'
              case message[:say]
              when 'completion_result'
                completion_result = message[:text]
                artifacts.merge!(artifacts_from(completion_result))
                # Check for expected artifacts and eventually ask to continue if some are missing
                missing_output_artifacts = payload[:artifacts][:output].select { |name, _description| artifacts.key?(name) }
                unless missing_output_artifacts.empty?
                  @cline.user_feedback <<~EO_Prompt
                    Some output artifacts are missing in your reponse.

                    You must return the following artifacts to the user:
                    #{missing_input_artifacts.map { |name, description| "- #{name}: #{description}" }.join("\n")}
                    
                    If some of those artifacts are empty, leave their content empty.

                    Artifacts are text documents that you can get as input and produce as output.
                    Each artifact is identified by a name.
                    You must produce your artifacts by including their content between `<artifact:name>...</artifact:name>` tags in any of your responses. For example the artifact named `plan` should be returned to the user between `<artifact:plan>...</artifact:plan>` tags.
                  EO_Prompt
                end
              when 'text'
                artifacts.merge!(artifacts_from(message[:text]))
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

      # Parse artifacts from a text.
      # Artifacts defined several times will concatenate.
      #
      # Parameters::
      # * *text* (String): Text to look for artifacts
      # Result::
      # * Hash<Symbol,String>: Set of artifacts
      def artifacts_from(text)
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

    end

  end

end
