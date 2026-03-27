require 'ruby_llm/message'
require 'ruby_llm/provider'
require 'x-aeon_agents_skills/connections/cline_cli'

module XAeonAgentsSkills

  module Providers

    class ClineCli < RubyLLM::Provider

      def initialize(config)
        super
        @connection = Connections::ClineCli.new(config.cline_api_key)
      end

      def api_base
        # CLI tools don't have a REST API endpoint
        '.'
      end

      def completion_url
        '.'
      end

      def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil, thinking: nil, tool_prefs: nil)
        {
          model: model.id,
          messages:,
          stream: stream
        }
      end

      def parse_completion_response(response)
        RubyLLM::Message.new(
          role: :assistant,
          content: response[:body],
          # TODO: Implement those attributes from the CLI output
          # thinking: Thinking.build(text: thinking_text, signature: thinking_signature),
          # tool_calls: parse_tool_calls(message_data['tool_calls']),
          # input_tokens: usage['prompt_tokens'],
          # output_tokens: usage['completion_tokens'],
          # cached_tokens: cached_tokens,
          # cache_creation_tokens: 0,
          # thinking_tokens: thinking_tokens,
          model_id: response[:model],
          raw: response
        )
      end

      class << self

        def local?
          true
        end

        def configuration_requirements
          %i[cline_api_key]
        end

        def configuration_options
          %i[cline_api_key]
        end

      end

    end

  end

end
