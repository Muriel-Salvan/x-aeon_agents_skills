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
        plan_mode = payload[:cline][:plan_mode]
        @cline.prompt(
          payload[:messages],
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
                  plan_match = JSON.parse(message[:text], symbolize_names: true)[:response].match(/<plan>(.+)<\/plan>/m)
                  if plan_match.nil?
                    @cline.user_feedback('Tell the plan to the user between `<plan>...</plan>` tags as completion and stop this task.')
                  else
                    completion_result = plan_match[1]
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
              else
                raise "Unknown ask from Cline: #{message}"
              end
            elsif message[:type] == 'say' && message[:say] == 'completion_result'
              completion_result = message[:text]
            end
          end,
          ignore_partials: true
        )
        {
          body: completion_result,
          model: payload[:model]
        }
      end

    end

  end

end
