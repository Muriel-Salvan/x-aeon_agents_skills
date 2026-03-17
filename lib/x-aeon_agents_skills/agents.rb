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
          input_artifacts: {
            requirements: 'Initial requirements for which you need to devise an implementation plan.'
          },
          output_artifacts: {
            plan: 'The full implementation plan that you must devise.'
          },
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
            [ ] 1. Read the initial requirements from the artifact named `requirements`.
            [ ] 2. Analyze the project files.
            [ ] 3. Devise a **step-by-step implementation plan**.
            [ ] 4. Output **only the implementation plan** as an artifact named `plan`.
            [ ] 5. Do NOT execute the plan yourself.

            # Constraints
            
            * You are in read-only mode.
            * Do NOT modify or write any file.
            * You may only analyze and propose plans.
          EO_Instructions
        )
        developer_agent = cline_agent(
          name: 'Developer',
          input_artifacts: {
            plan: 'Implementation plan you must follow.'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Implement a task by following all the steps of the implementation plan described in the artifact named `plan`.
          EO_Instructions
        )
        tester_agent = cline_agent(
          name: 'Tester',
          input_artifacts: {
            requirements: 'Initial requirements.',
            plan: 'Implementation plan devised from the requirements.',
            files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan.',
            tests_output: 'Output of running the whole tests suite.',
            tests_cmd: 'Command line to be used to run the whole tests suite.'
          },
          output_artifacts: {
            plan_modifications: 'Any modification or divergence you considered from the implementation plan. Keep empty if you didn\'t change the implementation plan.'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Fix any regression that has been induced by new features or fixes, while keeping the initial requirements and implementation plan in mind.
            If the decisions taken in the implementation plan prevent you from fixing regressions, modify the implementation plan and report those modifications to the user between `<plan-modifications>...</plan-modifications>` tags.

            [ ] 1. Read the initial requirements from the artifact named `requirements`.
            [ ] 2. Read the implementation plan that was decided from the artifact named `plan`.
            [ ] 3. Read all files modifications from the artifact named `files_diffs`, and understand what was the intent of the developer implementing those requirements.
            [ ] 4. Analyze the full output of unit tests run from the artifact named `tests_output`, and check every error reported in it.
            [ ] 5. Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements.
            [ ] 6. Remember any inconsistency and modification you need to make to the implementation plan so that your fixes are in-line with a better implementation plan.
            [ ] 7. Make sure all tests are running without issue after your fixes. You can run tests again using the provided tests command from the artifact named `tests_cmd` to test your own fixes.
            [ ] 8. Report to the user any implementation plan modification or divergence you considered in the artifact named `plan_modifications`.
          EO_Instructions
        )
        documenter_agent = cline_agent(
          name: 'Documenter',
          input_artifacts: {
            requirements: 'Initial requirements.',
            plan: 'Implementation plan that introduced features and fixes to be documented.',
            files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan.'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
            updating-doc
          ],
          instructions: <<~EO_Instructions
            Update relevant documentation when a task is being implemented.

            [ ] 1. Read the initial requirements from the artifact named `requirements`.
            [ ] 2. Read the implementation plan that was decided from the artifact named `plan`.
            [ ] 3. Read all files modifications from the artifact named `files_diffs`, and understand what was the intent of the developer implementing those requirements.
            [ ] 4. Find all documentation files and all the files referenced by the documentation files. You can start with `README.md` and any `docs/*.md` file.
            [ ] 5. Read all the documentation files that you found to understand the documentation structure and content.
            [ ] 6. Update the documentation files according to the new requirements that were implemented following the plan and corresponding files diffs.

            # Constraints

            * Only update documentation files.
            * Do NOT change any code or test.
          EO_Instructions
        )
        releaser_agent = cline_agent(
          name: 'Releaser',
          instructions: <<~EO_Instructions
            Release a new feature or bugfix to its branch on Github, with a Pull Request
          EO_Instructions
        )

        with_runner do
          # Initial artifacts
          @artifacts[:requirements] = requirements

          run(planner_agent)
          puts "===== Implementation plan:\n#{@artifacts[:plan]}"

          # TODO: Add interactive review step here

          run(developer_agent)
          puts "===== Developer changes:\n#{`git status`}"

          tests_cmd = 'bundle exec rspec --format documentation'
          @artifacts[:tests_cmd] = tests_cmd
          idx_test = 0
          loop do
            puts
            puts "===== Run tests ##{idx_test}..."
            test_result = XAeonAgentsSkills::Helpers.run_cmd(tests_cmd, expected_exit_status: nil)
            puts "Tests ##{idx_test} exit status: #{test_result[:exit_status]}"
            @artifacts.merge!(
              files_diffs: <<~EO_Artifact,
                ### git status

                ```
                #{`git status`}
                ```

                ### git diff

                ```
                #{`git diff`}
                ```
              EO_Artifact
              tests_output: <<~EO_Artifact,
                ```
                #{test_result[:stdout]}
                ```
              EO_Artifact
            )
            break if test_result[:exit_status] == 0

            run(tester_agent)
            puts "===== Tester changes:\n#{`git status`}"
            # Integrate potential implementation plan modifications
            unless @artifacts[:plan_modifications].strip.empty?
              plan_modifications = @artifacts.delete(:plan_modifications)
              @artifacts[:plan] << <<~EO_Artifact
                # Revision ##{idx_test} to the implementation plan
                
                #{plan_modifications}

              EO_Artifact
            end
            idx_test += 1
          end

          run(documenter_agent)
          puts "===== Documenter changes:\n#{`git status`}"
        end
        puts
        puts 'Requirements implemented successfully'
      end

      # Get the instructions artifacts header, applicable to all agents dealing with artifacts
      #
      # Result::
      # String: The corresponding instructions
      def instructions_artifacts_header
        <<~EO_Instructions
          Artifacts are text documents that you can get as input and produce as output.
          Each artifact is identified by a name.
          You can produce an artifact by including its content between `<artifact:name>...</artifact:name>` tags in any of your response. For example the artifact named `plan` should be returned to the user between `<artifact:plan>...</artifact:plan>` tags.
          The user is communicating artifacts with you using the same tags syntax: `<artifact:name>...</artifact:name>`.
        EO_Instructions
      end

      private

      # Setup an agents runner.
      #
      # Parameters::
      # * Proc: Code called with the runner setup
      def with_runner
        @runner = ::Agents::Runner.new
        @artifacts = {}
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
        agent.params[:artifacts][:store] = @artifacts
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
      # * *input_artifacts* (Hash<Symbol,String>): Set of artifacts (name: description) this agent expects as input [default: {}]
      # * *output_artifacts* (Hash<Symbol,String>): Set of artifacts (name: description) this agent is expected to output [default: {}]
      # * *model* (String): Model to be used [default: Agents.config[:default_cline_model]]
      # * *plan_mode* (Boolean): Are we executing in Plan mode? [default: false]
      # * *config* (Hash): Cline config to be used [default: Agents.config[:default_cline_config]]
      # * *cli_args* (String): Cline CLI additional arguments [default: Agents.config[:default_cline_cli_args]]
      # * *skills* (Array<String>): List of skills to be associated to this agent [default: Agents.config[:default_cline_skills]]
      def cline_agent(
        name: 'Executor',
        instructions: '',
        input_artifacts: {},
        output_artifacts: {},
        model: Agents.config[:default_cline_model],
        plan_mode: false,
        config: Agents.config[:default_cline_config],
        cli_args: Agents.config[:default_cline_cli_args],
        skills: Agents.config[:default_cline_skills]
      )
        full_instructions = instructions_header(name)
        unless instructions.empty?
          full_instructions << <<~EO_Instructions
            # Your task
            
            #{instructions}

          EO_Instructions
        end
        unless input_artifacts.empty? && output_artifacts.empty?
          full_instructions << <<~EO_Instructions
            # Artifacts
            
            #{instructions_artifacts_header}

          EO_Instructions
          unless input_artifacts.empty?
            full_instructions << <<~EO_Instructions
              ## Input artifacts
            
              You are expecting the following artifacts as input from the `Artifacts` section.

              #{input_artifacts.map { |name, description| "* `#{name}`: #{description}" }.join("\n")}
              
            EO_Instructions
          end
          unless output_artifacts.empty?
            full_instructions << <<~EO_Instructions
              ## Output artifacts
            
              You must produce the following artifacts as output when completing your task.

              #{output_artifacts.map { |name, description| "* `#{name}`: #{description}" }.join("\n")}
              
            EO_Instructions
          end
        end
        ::Agents::Agent.new(
          model:,
          provider: 'clinecli',
          name:,
          params: {
            agent: {
              name:
            },
            artifacts: {
              input: input_artifacts,
              output: output_artifacts
            },
            cline: {
              plan_mode:,
              config:,
              cli_args:,
              skills:
            }
          },
          instructions: full_instructions
        )
      end

      # Get the instructions header, applicable to all agents
      #
      # Parameters::
      # * *name* (String): Agent's name
      # Result::
      # String: The corresponding instructions' header
      def instructions_header(name)
        <<~EO_Instructions
          You are a #{name} agent.

          You are working in a headless environment.
          Do NOT ask for user confirmation. 
          Do NOT call the tool `plan_mode_respond`.

        EO_Instructions
      end

    end

  end

end
