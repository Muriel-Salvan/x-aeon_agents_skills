require 'x-aeon_agents_skills/cline'

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
        @cline = Cline.new(api_key, debug:)
      end

      # Method called by RubyLLM providers to send a payload
      #
      # Parameters::
      # * *url* (String): URL to post the payload to
      # * *payload* (Hash): Payload to be sent
      # * Proc: Code called to set additional HTTP request parameters in case of a web API call
      def post(url, payload, &)
        last_message = nil
        @cline.prompt(
          payload[:messages],
          model: payload[:model],
          config: payload[:cline][:config],
          skills: payload[:cline][:skills],
          skillkit_agents: true,
          cli_args: payload[:cline][:cli_args],
          on_message: proc do |message|
            last_message = message
          end
        )
        {
          body: last_message.to_json,
          model: payload[:model]
        }
      end

    end

  end

end
