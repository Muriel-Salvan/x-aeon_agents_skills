require 'ellipsized'
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
        completion_result = nil
        @cline.prompt(
          payload[:messages],
          model: payload[:model],
          config: payload[:cline][:config],
          skills: payload[:cline][:skills],
          skillkit_agents: true,
          cli_args: payload[:cline][:cli_args],
          on_message: proc do |message, last, _previous_version|
            log_debug { Cline.human_message(message).ellipsized(128) }
            if message[:type] == 'ask' && last
              case message[:ask]
              when 'plan_mode_respond'
                # Cline just got its plan done.
                # TODO: Save the plan and exit if we are in a plan task.
                # Otherwise just tell it to continue (check how it is done when switching to Act mode).
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
            elsif message[:type] == 'say' && message[:say] == 'completion_result'
              completion_result = message[:text]
            end
          end
        )
        {
          body: completion_result,
          model: payload[:model]
        }
      end

    end

  end

end
