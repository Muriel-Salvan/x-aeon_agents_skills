require 'ruby_llm/message'
require 'ruby_llm/thinking'
require 'ruby_llm/providers/openai'
require 'ruby_llm/providers/openrouter/chat'
require 'ruby_llm/providers/openrouter/models'
require 'ruby_llm/providers/openrouter/streaming'
require 'ruby_llm/providers/openrouter/images'

module XAeonAgentsSkills

  module Providers

    # Cline API integration.
    class Cline < RubyLLM::Providers::OpenAI

      def api_base
        @config.cline_api_base || 'https://api.cline.bot/api/v1'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.cline_api_key}"
        }
      end

      def parse_completion_response(response)
        data = response.body
        return if data.empty?

        raise Error.new(response, data.dig('error')) if data.dig('error')

        message_data = data.dig('data', 'choices', 0, 'message')
        return unless message_data

        usage = data.dig('data', 'usage') || {}
        cached_tokens = usage.dig('prompt_tokens_details', 'cached_tokens')
        thinking_tokens = usage.dig('completion_tokens_details', 'reasoning_tokens')
        content, thinking_from_blocks = extract_content_and_thinking(message_data['content'])
        thinking_text = thinking_from_blocks || extract_thinking_text(message_data)
        thinking_signature = extract_thinking_signature(message_data)

        RubyLLM::Message.new(
          role: :assistant,
          content: content,
          thinking: RubyLLM::Thinking.build(text: thinking_text, signature: thinking_signature),
          tool_calls: parse_tool_calls(message_data['tool_calls']),
          input_tokens: usage['prompt_tokens'],
          output_tokens: usage['completion_tokens'],
          cached_tokens: cached_tokens,
          cache_creation_tokens: 0,
          thinking_tokens: thinking_tokens,
          model_id: data.dig('data', 'model'),
          raw: response
        )
      end

      private

      class << self

        def configuration_requirements
          %i[cline_api_base cline_api_key]
        end

        def configuration_options
          %i[cline_api_base cline_api_key]
        end

      end

    end

  end

end
