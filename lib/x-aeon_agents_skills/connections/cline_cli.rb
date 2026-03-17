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

        completion_result = nil
        artifacts = {}
        plan_mode = payload[:cline][:plan_mode]
        full_prompt = <<~EO_Prompt
          #{payload[:messages].select { |message| message.role == :system }.map(&:content).join("\n\n")}

        EO_Prompt
        user_prompt = payload[:messages].select { |message| message.role == :user }.map(&:content).join("\n\n").strip
        unless user_prompt.empty?
          full_prompt << <<~EO_Prompt
            # Instructions
            
            #{user_prompt}

          EO_Prompt
        end
        unless payload[:artifacts][:input].empty?
          log_debug "Adding #{payload[:artifacts][:input].size} artifacts to the prompt: #{payload[:artifacts][:input].keys.join(', ')}"
          full_prompt << <<~EO_Prompt
            # Artifacts
            
            #{payload[:artifacts][:input].keys.map { |name| "<artifact:#{name}>\n#{payload[:artifacts][:store][name]}\n</artifact:#{name}>" }.join("\n\n")}

          EO_Prompt
        end
        @cline.prompt(
          full_prompt,
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

                      #{Agents.instructions_artifacts_header}
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
                    #{missing_input_artifacts.map { |name, description| "* #{name}: #{description}" }.join("\n")}
                    
                    If some of those artifacts are empty, leave their content empty.

                    #{Agents.instructions_artifacts_header}
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
