require 'agents'
require 'front_matter_parser'
require 'ruby_llm/model/info'
require 'x-aeon_agents_skills/helpers'
require 'x-aeon_agents_skills/logger'
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
      # * *default_cline_skills* (Array<string>): Default Cline skills [default: []]
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
        default_cline_skills: [],
        debug: false
      )
        @config = {
          cline_api_key:,
          default_cline_model:,
          default_cline_config:,
          default_cline_cli_args:,
          default_cline_skills:,
          debug:
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
        Logger.debug = config[:debug]
        ::Agents.configure do |ai_agents_config|
          ai_agents_config.cline_api_key = config[:cline_api_key]
          ai_agents_config.debug = config[:debug]
        end
      end

      # Execute a simple task
      #
      # Parameters::
      # * *prompt* (String): The prompt for this task
      def execute_simple_task(prompt)
        with_runner { puts run(cline_agent, prompt) }
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
        plan_file = "tmp/plans/PLAN_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.md"
        FileUtils.mkdir_p File.dirname(plan_file)
        manager_agent = cline_agent(
          name: 'Manager',
          instructions: <<~EO_Instructions
            Coordinate the work of other agents to fully implement a Github issue
          EO_Instructions
        )
        planner_agent = cline_agent(
          name: 'Planner',
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            enforcing-project-rules
          ],
          plan_mode: true,
          config: Helpers.deep_merge(
            config[:default_cline_config],
            {
              autoApprovalSettings: {
                actions: {
                  readFiles: true,
                  readFilesExternally: true,
                  editFiles: false,
                  editFilesExternally: false,
                  executeSafeCommands: true,
                  executeAllCommands: false,
                  useBrowser: true,
                  useMcp: true
                }
              },
              strictPlanModeEnabled: true
            }
          ),
          instructions: <<~EO_Instructions
            1. Read the requirements.
            2. Analyze the project files.
            3. Devise a **step-by-step implementation plan**.
            4. Output **only the implementation plan** between `<plan>...</plan>` tags.
            5. Do NOT execute the plan yourself.

            You are in read-only mode.
            Do NOT modify or write any file.
            You may only analyze and propose plans.
          EO_Instructions
        )
        developer_agent = cline_agent(
          name: 'Developer',
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Implement a task by following all the steps of an implementation plan.
          EO_Instructions
        )
        tester_agent = cline_agent(
          name: 'Tester',
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Fix any regression that has been induced by new features or fixes.

            1. Read the initial requirements were implemented.
            2. Read the implementation plan that was followed.
            3. Check all files modifications to understand what was the intent of the developer implementing those requirements.
            4. Analyze the full output of unit tests run, and check every error reported in it.
            5. Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements.
            6. Make sure all tests are running without issue after your fixes.
            
            You can run tests again using the provided tests command to test your own fixes.
          EO_Instructions
        )
        documenter_agent = cline_agent(
          name: 'Documenter',
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
            updating-doc
          ],
          instructions: <<~EO_Instructions
            Update relevant documentation when a task is being implemented.

            1. Read the initial requirements were implemented.
            2. Read the implementation plan that was followed.
            3. Check all files modifications to understand what was the intent of the developer implementing those requirements.
            4. Update documentation files accordingly.

            Only update documentation files.
            Do NOT change any code or test.
          EO_Instructions
        )
        releaser_agent = cline_agent(
          name: 'Releaser',
          instructions: <<~EO_Instructions
            Release a new feature or bugfix to its branch on Github, with a Pull Request
          EO_Instructions
        )

        with_runner do
          plan = run(
            planner_agent,
            <<~EO_Prompt
              # Task requirements for which we need the implementation plan

              #{requirements}
            EO_Prompt
          )
          puts "===== Implementation plan:\n#{plan}"
          # TODO: Add interactive review step here
          run(
            developer_agent,
            <<~EO_Prompt
              Follow the implementation plan.

              #{plan}
            EO_Prompt
          )
          tests_cmd = 'bundle exec rspec --format documentation'
          loop do
            puts
            puts "===== Run tests..."
            test_result = XAeonAgentsSkills::Helpers.run_cmd(tests_cmd, expected_exit_status: nil)
            puts "Tests exit status: #{test_result[:exit_status]}"
            break if test_result[:exit_status] == 0
            run(
              tester_agent,
              <<~EO_Prompt
                # Original requirements

                #{requirements}

                # Implementation plan that may have incurred regressions

                #{plan}

                # List of files modifications that may be responsible for regressions

                ## git status

                ```
                #{`git status`}
                ```

                ## git diff

                ```
                #{`git diff`}
                ```

                # Test command

                ```bash
                #{tests_cmd}
                ```

                # Full result and errors of the test suite run

                ```
                #{test_result[:stdout]}
                ```
              EO_Prompt
            )
          end
          run(
            documenter_agent,
            <<~EO_Prompt
              # Original requirements

              #{requirements}

              # Implementation plan that introduced features and fixes to be documented

              #{plan}

              # List of corresponding modifications

              ## git status

              ```
              #{`git status`}
              ```

              ## git diff

              ```
              #{`git diff`}
              ```
            EO_Prompt
          )
        end
        puts
        puts 'Requirements implemented successfully'
      end

      private

      # Setup an agents runner.
      #
      # Parameters::
      # * Proc: Code called with the runner setup
      def with_runner
        @runner = ::Agents::Runner.new
        yield
      end

      # Run an agent with a prompt.
      #
      # Parameters::
      # * *agent* (::Agents::Agent): The agent to run
      # * *prompt* (String): Additional prompt [default = '']
      # Result::
      # * String: The result output
      def run(agent, prompt = '')
        puts
        puts "===== #{agent.name}..."
        result = @runner.run(agent, prompt)
        raise "Error: #{result.error}" unless result.error.nil?
        result.output
      end

      # Create a Cline agent
      #
      # Parameters::
      # * *name* (String): Agent name [default: 'Executor']
      # * *instructions* (String): Agent's system instructions [default: '']
      # * *model* (String): Model to be used [default: Agents.config[:default_cline_model]]
      # * *plan_mode* (Boolean): Are we executing in Plan mode? [default: false]
      # * *config* (Hash): Cline config to be used [default: Agents.config[:default_cline_config]]
      # * *cli_args* (String): Cline CLI additional arguments [default: Agents.config[:default_cline_cli_args]]
      # * *skills* (Array<String>): List of skills to be associated to this agent [default: Agents.config[:default_cline_skills]]
      def cline_agent(
        name: 'Executor',
        instructions: '',
        model: Agents.config[:default_cline_model],
        plan_mode: false,
        config: Agents.config[:default_cline_config],
        cli_args: Agents.config[:default_cline_cli_args],
        skills: Agents.config[:default_cline_skills]
      )
        ::Agents::Agent.new(
          model:,
          provider: 'clinecli',
          name:,
          params: {
            agent: {
              name:
            },
            cline: {
              plan_mode:,
              config:,
              cli_args:,
              skills:
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
