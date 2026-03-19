require 'agents'
require 'front_matter_parser'
require 'ruby_llm/model/info'
require 'x-aeon_agents_skills/gen_helpers'
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
          objective: 'Coordinate the work of other agents to fully implement a Github issue'
        )
        planner_agent = cline_agent(
          name: 'Planner',
          objective: 'Create a `plan` artifact containing a complete and detailed implementation plan that can be used to implement some requirements.',
          input_artifacts: {
            requirements: 'Initial requirements for which you need to devise an implementation plan'
          },
          output_artifacts: {
            plan: 'The full implementation plan that should implement the requirements given by the `requirements` artifact'
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
          instructions: {
            ordered_list: [
              'Read the initial requirements from the `requirements` artifact',
              'Analyze the project files',
              'Devise a **step-by-step implementation plan**',
              'Return to ther user the `plan` artifact containing the full and detailed implementation plan between `<artifact:plan>` and `</artifact:plan>` tags',
              'Do NOT execute the plan yourself'
            ]
          },
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You may only analyze and propose plans.
          EO_Constraints
        )
        developer_agent = cline_agent(
          name: 'Developer',
          objective: 'Implement a task',
          input_artifacts: {
            plan: 'Implementation plan that you must follow'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Follow all the steps of the implementation plan described in the `plan` artifact.
          EO_Instructions
        )
        tester_agent = cline_agent(
          name: 'Tester',
          objective: <<~EO_Objective,
            Fix any regression that has been induced by new features or fixes, while keeping the initial requirements and implementation plan in mind.
            If the decisions taken in the implementation plan prevent you from fixing regressions, modify the implementation plan and report those modifications to the user.
          EO_Objective
          input_artifacts: {
            requirements: 'Initial requirements',
            plan: 'Implementation plan devised from the requirements',
            files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan',
            tests_output: 'Output of running the whole tests suite',
            tests_cmd: 'Command line to be used to run the whole tests suite'
          },
          output_artifacts: {
            plan_modifications: 'Any modification or divergence you considered from the implementation plan'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: {
            ordered_list: [
              'Read the initial requirements from the `requirements` artifact',
              'Read the implementation plan that was decided from the `plan` artifact',
              'Read all files modifications from the `files_diffs` artifact, and understand what was the intent of the developer implementing those requirements',
              'Analyze the full output of unit tests run from the `tests_output` artifact, and check every error reported in it',
              'Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements',
              'Remember any inconsistency and modification you need to make to the implementation plan so that your fixes are in-line with a better implementation plan',
              <<~EO_Step,
                Make sure all tests are running without issue after your fixes
                
                - You can run tests again using the provided tests command from the `tests_cmd` artifact to test your own fixes.
              EO_Step
              'Report to the user any implementation plan modification or divergence you considered in the `plan_modifications` artifact'
            ]
          }
        )
        documenter_agent = cline_agent(
          name: 'Documenter',
          objective: 'Update relevant documentation when a task is being implemented.',
          input_artifacts: {
            requirements: 'Initial requirements',
            plan: 'Implementation plan that introduced features and fixes to be documented',
            files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan'
          },
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
            updating-doc
          ],
          instructions: {
            ordered_list: [
              'Read the initial requirements from the `requirements` artifact',
              'Read the implementation plan that was decided from the `plan` artifact',
              'Read all files modifications from the `files_diffs` artifact, and understand what was the intent of the developer implementing those requirements',
              <<~EO_Step,
                Find all documentation files and all the files referenced by the documentation files
                
                - Start with `README.md` and any `docs/*.md` files.
              EO_Step
              'Read all the documentation files that you found to understand the documentation structure and content',
              'Update the documentation files according to the new requirements that were implemented, keeping in mind the implementation plan that was used and the corresponding files diffs'
            ]
          },
          constraints: <<~EO_Constraints
            - Only update documentation files.
            - Do NOT change any code or test.
          EO_Constraints
        )
        releaser_agent = cline_agent(
          name: 'Releaser',
          objective: 'Release a new feature or bugfix to its branch on Github, with a Pull Request'
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

      # Return a clear instruction for the LLM to generate an artifact
      #
      # Parameters::
      # * *name* (Symbol): Artifact's name
      # * *description* (String): Artifact's description
      # Result::
      # * String: The prompt instruction to generate this artifact
      def artifact_prompt(name, description)
        # "Return the implementation plan between `<artifact:#{name}>...</artifact:#{name}>` tags."
        "Return the `#{name}` artifact (#{description}) between `<artifact:#{name}>` and `</artifact:#{name}>` tags"
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
      # * *role* (String): Agent's role [default: "You are a #{name} agent"]
      # * *objective* (String): Agent's objective [default: '']
      # * *instructions* (String): Agent's system instructions [default: '']
      # * *constraints* (String): Constraints to be respected [default: '']
      # * *input_artifacts* (Hash<Symbol,String>): Set of artifacts (name: description) this agent expects as input [default: {}]
      # * *output_artifacts* (Hash<Symbol,String>): Set of artifacts (name: description) this agent is expected to output [default: {}]
      # * *model* (String): Model to be used [default: Agents.config[:default_cline_model]]
      # * *plan_mode* (Boolean): Are we executing in Plan mode? [default: false]
      # * *config* (Hash): Cline config to be used [default: Agents.config[:default_cline_config]]
      # * *cli_args* (String): Cline CLI additional arguments [default: Agents.config[:default_cline_cli_args]]
      # * *skills* (Array<String>): List of skills to be associated to this agent [default: Agents.config[:default_cline_skills]]
      def cline_agent(
        name: 'Executor',
        role: "You are a #{name} agent",
        objective: '',
        instructions: '',
        constraints: '',
        input_artifacts: {},
        output_artifacts: {},
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
              name:,
              role:,
              objective:,
              constraints:
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
          instructions: system_instructions(name:, instructions:, output_artifacts:)
        )
      end

      # Compute the system instructions as a String from the original instructions and other agent variables that may affect it
      #
      # Parameters::
      # * *name* (String): Agent name
      # * *instructions* (Object): Original instructions given to the agent
      #   Here are the possible kinds of instructions:
      #   * Array<Object>: List of instruction descriptions that should be appended
      #   * Object: Individual instruction description.
      #   An individual instruction can be one of the following:
      #     * Hash<Symbol,Object>: A structure describing the instructions
      #     * String: Direct instructions to be used (equivalent to { text: instructions })
      #     Here is the list of keys that can define different instructions:
      #       * *text* (String): The instructions are given as text directly.
      #       * *ordered_list* (Array<String>): The instructions are a precise list of steps to perform.
      #       Several keys can be used in the same Hash, and they will be treated in the order in the Hash.
      # * *output_artifacts* (Hash<Symbol,String>): Set of expected output artifacts
      # Result::
      # * String: The resulting instructions as a string
      def system_instructions(name:, instructions:, output_artifacts:)
        # Normalize instructions
        instructions = (instructions.is_a?(Array) ? instructions : [instructions]).
          map { |instruction_desc| instruction_desc.is_a?(Hash) ? instruction_desc : { text: instruction_desc } }

        # Enrich instructions with output artifacts
        unless output_artifacts.empty?
          # We add the output artifacts at the end of an ordered list (we add one if current instructions don't end with such a list)
          instructions << { ordered_list: [] } unless instructions.last.key?(:ordered_list)
          instructions.last[:ordered_list].concat(output_artifacts.map { |name, description| artifact_prompt(name, description) })
        end

        # Convert the list of instructions into a nice string
        idx_checklist = 0
        instructions.map do |instruction_desc|
          instruction_desc.map do |instruction_kind, instruction|
            case instruction_kind
            when :text
              instruction
            when :ordered_list
              checklist_name = "#{name}-#{idx_checklist}"
              idx_checklist += 1
              <<~EO_Instructions
                ## Sequential steps to follow

                #{GenHelpers.init_skill_checklist(checklist_name)}

                #{
                  # Consider each element of the list as a potential markdown section, with the first line being the title.
                  instruction.map.with_index do |markdown_section, step_number|
                    lines = markdown_section.each_line.to_a
                    "### #{step_number + 1}. #{lines.first}#{lines[1..-1].join}"
                  end.join("\n\n")
                }

                #{GenHelpers.validate_skill_checklist(checklist_name)}
              EO_Instructions
            else
              raise "Unknown instruction kind: #{instruction_kind}"
            end
          end
        end.flatten(1).join("\n\n")
      end

    end

  end

end
