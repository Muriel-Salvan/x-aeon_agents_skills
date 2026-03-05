require 'agents'
require 'ruby_llm/model/info'
require 'x-aeon_agents_skills/helpers'
require 'x-aeon_agents_skills/providers/cline_cli'
require 'x-aeon_agents_skills/providers/cline'

# Patch RubyLLM to be able to register models
module RubyLLM

  class Models

    # Register a new model from a Hash (same structure as the models.json file)
    #
    # Parameters::
    # * *model_def* (Hash): Model definition
    def register!(model_def)
      @models << RubyLLM::Model::Info.new(model_def)
    end

  end

end

module XAeonAgentsSkills

  module Agents

    class << self

      attr_reader :config

      # Configure agents
      #
      # Parameters::
      # * *cline_api_key* (String): Cline API key to be used [default: ENV['CLINE_API_KEY']]
      # * *default_cline_model* (String): Default Cline model [default: 'kwaipilot/kat-coder-pro']
      # * *default_cline_config* (Hash): Default Cline config [default: See signature]
      # * *default_cline_cli_args* (String): Default Cline CLI arguments [default: '--thinking 1024']
      # * *debug* (Boolean): Do we activate debug mode? [default: false]
      def configure(
        cline_api_key: ENV['CLINE_API_KEY'],
        default_cline_model: 'kwaipilot/kat-coder-pro',
        default_cline_config: {
          actModeReasoningEffort: 'xhigh',
          autoApprovalSettings: {
            actions: {
              readFiles: true,
              readFilesExternally: true,
              editFiles: true,
              editFilesExternally: true,
              executeSafeCommands: true,
              executeAllCommands: true,
              useBrowser: true,
              useMcp: true
            },
            enabled: true
          },
          clineWebToolsEnabled: true,
          customPrompt: 'compact',
          defaultTerminalProfile: 'powershell-legacy',
          doubleCheckCompletionEnabled: true,
          enableParallelToolCalling: true,
          focusChainSettings: {
            enabled: true,
            remindClineInterval: 3
          },
          multiRootEnabled: false,
          nativeToolCallEnabled: true,
          planModeReasoningEffort: 'xhigh',
          planModeThinkingBudgetTokens: 1024,
          strictPlanModeEnabled: true,
          subagentsEnabled: true,
          telemetrySetting: 'disabled',
          useAutoCondense: true
        },
        default_cline_cli_args: '--thinking 1024',
        debug: false
      )
        @config = {
          cline_api_key: cline_api_key,
          default_cline_model: default_cline_model,
          default_cline_config: default_cline_config,
          default_cline_cli_args: default_cline_cli_args,
          debug: debug
        }

        # Register our providers
        RubyLLM::Provider.register(:clinecli, XAeonAgentsSkills::Providers::ClineCli)
        RubyLLM::Provider.register(:cline, XAeonAgentsSkills::Providers::Cline)

        # Register our models
        RubyLLM::Models.register!(
          id: 'kwaipilot/kat-coder-pro',
          name: 'Cline CLI - kwaipilot/kat-coder-pro',
          provider: 'cline',
          family: 'cline',
          # TODO: Find those parameters from cline cli itself
          created_at: '2026-03-03 00:00:00 UTC',
          context_window: 200000,
          max_output_tokens: 8192,
          knowledge_cutoff: '2024-07-31',
          modalities: {
            input: [
              'text',
              'image',
              'pdf'
            ],
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
                input_per_million: 0.8,
                output_per_million: 4,
                cached_input_per_million: 0.08
              }
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
              input: 0.8,
              output: 4,
              cache_read: 0.08,
              cache_write: 1
            },
            limit: {
              context: 200000,
              output: 8192
            },
            knowledge: '2024-07-31'
          }
        )

        # Initialize our dependencies
        ENV['RUBYLLM_DEBUG'] = '1' if config[:debug]
        ::Agents.configure do |ai_agents_config|
          ai_agents_config.cline_api_key = config[:cline_api_key]
          ai_agents_config.debug = config[:debug]
        end
      end

      # Implement some requirements, given a classic dev cycle:
      # 1. Planning
      # 2. Development
      # 3. Testing
      # 4. Documentation
      # 5. Releasing
      #
      # Parameters::
      # * *requirements* (String): Requirements to be implemented
      def implement_requirements(requirements)
        plan_file = "PLAN_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.md"
        manager_agent = cline_agent(
          name: 'Manager',
          instructions: <<~EO_Instructions
            Coordinate the work of other agents to fully implement a Github issue
          EO_Instructions
        )
        planner_agent = cline_agent(
          name: 'Planner',
          config: Helpers.deep_merge(
            config[:default_cline_config],
            # Planning still needs to create the PLAN.md file
            {
              autoApprovalSettings: {
                actions: {
                  readFiles: true,
                  readFilesExternally: true,
                  editFiles: true,
                  editFilesExternally: false,
                  executeSafeCommands: true,
                  executeAllCommands: false,
                  useBrowser: true,
                  useMcp: true
                }
              },
              strictPlanModeEnabled: false
            }
          ),
          instructions: <<~EO_Instructions
            1. Read the requirements.
            2. Analyze the project files.
            3. Devise a **step-by-step implementation plan**.
            4. Output **only the implementation plan** in a file named #{plan_file}.

            You are in read-only mode.
            Do NOT modify or write any file other than #{plan_file}.
            You may only analyze and propose plans.
          EO_Instructions
        )
        developer_agent = cline_agent(
          name: 'Developer',
          instructions: <<~EO_Instructions
            Implement a task by following an implementation plan.
          EO_Instructions
        )
        tester_agent = cline_agent(
          name: 'Tester',
          instructions: <<~EO_Instructions
            Verify regressions by running unit tests and fix any issue that unit tests are surfacing.
          EO_Instructions
        )
        documenter_agent = cline_agent(
          name: 'Documenter',
          instructions: <<~EO_Instructions
            Update relevant documentation when a task is being implemented
          EO_Instructions
        )
        releaser_agent = cline_agent(
          name: 'Releaser',
          instructions: <<~EO_Instructions
            Release a new feature or bugfix to its branch on Github, with a Pull Request
          EO_Instructions
        )

        runner = ::Agents::Runner.new

        puts '===== 1. Plan...'
        planner_result = runner.run(
          planner_agent,
          <<~PROMPT
            # Task requirements for which we need the implementation plan

            #{requirements}
          PROMPT
        )
        raise "Plan file #{plan_file} hasn't been created" unless File.exist?(plan_file)

        puts '===== 2. Develop...'
        developer_result = runner.run(
          developer_agent,
          <<~PROMPT
            Follow the implementation plan.

            #{File.read(plan_file)}
          PROMPT
        )
        puts "===== OUTPUT:\n#{developer_result.output}\n====="
        puts "===== ERROR:\n#{developer_result.error}\n====="
      end

      private

      # Create a Cline agent
      #
      # Parameters::
      # * *name* (String): Agent name
      # * *instructions* (String): Agent's system instructions
      # * *model* (String): Model to be used [default: Agents.config[:default_cline_model]]
      # * *config* (Hash): Cline config to be used [default: Agents.config[:default_cline_config]]
      # * *cli_args* (String): Cline CLI additional arguments [default: Agents.config[:default_cline_cli_args]]
      def cline_agent(
        name:,
        instructions:,
        model: Agents.config[:default_cline_model],
        config: Agents.config[:default_cline_config],
        cli_args: Agents.config[:default_cline_cli_args]
      )
        ::Agents::Agent.new(
          model:,
          provider: 'clinecli',
          name:,
          params: {
            clinecli: {
              config: config,
              cli_args: cli_args
            }
          },
          instructions: <<~EO_System_Prompt
            You are a #{name} agent.

            You are working in a headless environment.
            Do NOT ask for user confirmation. 
            Do NOT call the tool plan_mode_respond.

            Your task:
            #{instructions}
          EO_System_Prompt
        )
      end

    end

  end

end
