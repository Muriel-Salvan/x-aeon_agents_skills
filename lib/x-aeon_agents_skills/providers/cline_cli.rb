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

      def list_models
        JSON.parse(File.read("#{ENV['VSCODE_PORTABLE'] ? "#{ENV['VSCODE_PORTABLE']}/user-data" : "#{ENV['APPDATA']}/Code"}/User/globalStorage/saoudrizwan.claude-dev/cache/cline_models.json"), symbolize_names: true).map do |name, info|
          RubyLLM::Model::Info.new(
            id: name.to_s,
            name: "Cline - #{name}",
            provider: 'clinecli',
            family: 'cline',
            created_at: '2026-01-01 00:00:00 UTC',
            context_window: info[:contextWindow],
            max_output_tokens: info[:maxTokens],
            knowledge_cutoff: '2026-01-01',
            modalities: {
              input: [
                'text'
              ] + (info[:supportsImages] ? ['image'] : []),
              output: [
                'text'
              ]
            },
            capabilities: [
              'function_calling',
              'vision'
            ],
            pricing: {
              text_tokens: {
                standard: {
                  input_per_million: info[:inputPrice],
                  output_per_million: info[:outputPrice]
                }.merge(info.key?(:cacheReadsPrice) ? { cached_input_per_million: info[:cacheReadsPrice] } : {})
              }
            },
            metadata: {
              source: 'models.dev',
              provider_id: 'cline',
              open_weights: false,
              attachment: true,
              temperature: true,
              last_updated: '2024-10-22',
              cost: {
                input: info[:inputPrice],
                output: info[:outputPrice]
              }.
                merge(info.key?(:cacheReadsPrice) ? { cache_read: info[:cacheReadsPrice] } : {}).
                merge(info.key?(:cacheWritesPrice) ? { cache_write: info[:cacheWritesPrice] } : {}),
              limit: {
                context: info[:contextWindow],
                output: info[:maxTokens]
              },
              knowledge: '2026-01-01'
            }
          )
        end
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
