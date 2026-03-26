require 'agents'
require 'commonmarker'
require 'front_matter_parser'
require 'git'
require 'json'
require 'octokit'
require 'ruby_llm/model/info'
require 'time'
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

      include Logger

      attr_reader :config

      # Configure agents
      #
      # Parameters::
      # * *cline_api_key* (String): Cline API key to be used [default: ENV['CLINE_API_KEY']]
      # * *default_cline_model* (String): Default Cline model [default: 'kwaipilot/kat-coder-pro']
      # * *default_cline_config* (Hash): Default Cline config [default: See signature]
      # * *default_cline_cli_args* (String): Default Cline CLI arguments [default: '--thinking 1024']
      # * *default_cline_skills* (Array<string>): Default Cline skills [default: []]
      # * *github_token* (String): GitHub token for Octokit authentication [default: ENV['GITHUB_TOKEN']]
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
        github_token: ENV['GITHUB_TOKEN'],
        debug: false
      )
        @config = {
          cline_api_key:,
          default_cline_model:,
          default_cline_config:,
          default_cline_cli_args:,
          default_cline_skills:,
          github_token:,
          debug:
        }

        # Register our providers
        RubyLLM::Provider.register(:clinecli, XAeonAgentsSkills::Providers::ClineCli)
        RubyLLM::Provider.register(:cline, XAeonAgentsSkills::Providers::Cline)

        # Register our models
        for_each_cline_model do |cline_model_name, cline_model|
          RubyLLM::Models.register!(
            id: cline_model_name,
            name: "Cline CLI - #{cline_model_name}",
            provider: 'cline',
            family: 'cline',
            created_at: '2026-01-01 00:00:00 UTC',
            context_window: cline_model[:contextWindow],
            max_output_tokens: cline_model[:maxTokens],
            knowledge_cutoff: '2026-01-01',
            modalities: {
              input: [
                'text'
              ] + (cline_model[:supportsImages] ? ['image'] : []),
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
                  input_per_million: cline_model[:inputPrice],
                  output_per_million: cline_model[:outputPrice]
                }.merge(cline_model.key?(:cacheReadsPrice) ? { cached_input_per_million: cline_model[:cacheReadsPrice] } : {})
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
                input: cline_model[:inputPrice],
                output: cline_model[:outputPrice]
              }.
                merge(cline_model.key?(:cacheReadsPrice) ? { cache_read: cline_model[:cacheReadsPrice] } : {}).
                merge(cline_model.key?(:cacheWritesPrice) ? { cache_write: cline_model[:cacheWritesPrice] } : {}),
              limit: {
                context: cline_model[:contextWindow],
                output: cline_model[:maxTokens]
              },
              knowledge: '2026-01-01'
            }
          )
        end

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

      # Interpret current code diffs
      #
      # Parameters::
      # * *base* (Object): Git base (sha, objectish...) with which we diff [default = 'HEAD']
      # Result::
      # * String: Code diffs interpretation
      def interpret_diffs(base = 'HEAD')
        with_runner do
          puts <<~EO_Diffs.strip
            
            ===== Code diffs interpretation:

            #{code_diffs(base).join("\n\n")}
          EO_Diffs
        end
      end

      # Implement a Github issue
      #
      # Parameters::
      # * *github_issue_number* (Integer): The Github issue number to implement
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def implement_github_issue(github_issue_number, run_id: nil)
        issue = github.issue(github_repo, github_issue_number)
        issue_comments = github.issue_comments(github_repo, github_issue_number)
        sections = [
          <<~EO_Section
            # #{issue.title}
            
            #{align_markdown_headers(issue.body, level: 2)}
          EO_Section
        ]
        sections << <<~EO_Section unless issue_comments.empty?
          # Comments
            
          This is the conversation log that happened in this issue.
          This is provided as a reference to better understand the requirements.

          #{format_comments_for_artifact(issue_comments)}
        EO_Section
        sections << <<~EO_Section
          # Associated Github issue
          
          - Number: #{issue.number}
          - Labels: #{issue.labels.map(&:name).join(', ')}
          - State: #{issue.state}
          - URL: #{issue.html_url}
        EO_Section
        implement_requirements(sections.map(&:strip).join("\n\n"), run_id:, commit: true, pull_request: true)
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
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      # * *commit* (Boolean): Do we commit changes? [default: false]
      # * *pull_request* (Boolean): Do we create a Pull Request (if not done already) for these requirements? [default: false]
      def implement_requirements(requirements, run_id: nil, commit: false, pull_request: false)
        with_runner(run_id) do

          # Initial artifacts
          step(:ir_a_setup_requirements) do
             @artifacts.merge!(
              requirements: requirements,
              base_sha: git.gcommit('HEAD').sha
             )
          end

          step(:ir_b_plan) do
            run(planner_agent)
            puts "===== Implementation plan:\n#{@artifacts[:plan]}"
          end

          # TODO: Add interactive review step here

          step(:ir_c_develop) do
            run(developer_agent)
            puts "===== Developer changes: #{git.status.changed.keys.join(", ")}"
          end

          step(:ir_d_commit) { git_commit(developer_agent) } if commit

          step(:ir_e_test) do
            tests_cmd = 'bundle exec rspec --format documentation'
            @artifacts[:tests_cmd] = tests_cmd
            idx_test = 0
            loop do
              puts
              puts "===== Run tests ##{idx_test}..."
              test_result = XAeonAgentsSkills::Helpers.run_cmd(tests_cmd, expected_exit_status: nil)
              puts "Tests ##{idx_test} exit status: #{test_result[:exit_status]}"
              @artifacts[:tests_output] = <<~EO_Artifact
                ```
                #{test_result[:stdout]}
                ```
              EO_Artifact
              break if test_result[:exit_status] == 0

              @artifacts[:files_diffs] = artifact_files_diffs(@artifacts[:base_sha])
              run(tester_agent)
              puts "===== Tester changes: #{git.status.changed.keys.join(", ")}"
              # Integrate potential implementation plan modifications
              unless @artifacts[:plan_modifications].strip.empty?
                plan_modifications = @artifacts.delete(:plan_modifications)
                @artifacts[:plan] << <<~EO_Artifact
                  # Revision ##{idx_test} to the implementation plan
                  
                  #{plan_modifications}

                EO_Artifact
              end
              git_commit(tester_agent) if commit
              idx_test += 1
            end
          end

          step(:ir_f_commit) { git_commit(tester_agent) } if commit

          step(:ir_g_document) do
            @artifacts[:files_diffs] = artifact_files_diffs(@artifacts[:base_sha])
            run(documenter_agent)
            puts "===== Documenter changes: #{git.status.changed.keys.join(", ")}"
          end

          step(:ir_h_commit) { git_commit(documenter_agent) } if commit

          step(:ir_i_pr) { create_pr } if pull_request
        end
        puts
        puts 'Requirements implemented successfully'
      end

      # Address Pull Request comments by finding open PRs, extracting agent-directed comments,
      # implementing requirements, and replying to comments.
      #
      # This method uses the "aprc" prefix in its step names, which stands for "Address Pull Request Comments".
      # The aprc prefix helps organize and identify the sequential steps involved in the PR comment addressing workflow:
      # - aprc_a_gather_comments: Gather and analyze PR comments directed at the agent
      # - aprc_b_extract_requirements: Extract actionable requirements from agent-directed comments
      # - aprc_c_reply_to_comment: Generate and post replies to each processed comment
      #
      # Parameters::
      # * *pull_request_number* (Integer): The Pull Request number to address comments for
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def address_pull_request_comments(pull_request_number, run_id: nil)
        with_runner(run_id) do
          step(:aprc_a_gather_comments) do
            owner, repo = github_repo.split('/')
            pr_json = github.post('/graphql',
              {
                query: File.read("#{__dir__}/gh_comments.gql"),
                variables: {
                  owner:,
                  repo:,
                  pr: pull_request_number
                }
              }.to_json
            )[:data][:repository][:pullRequest]
            # Select only conversations for which we need an AI Agent to contribute. That means:
            # * Not resolved.
            # * With at least 1 comment directed at the AI Agent (body starting with `/agent``) that does not have a reply (direct or indirect) from an AI Agent (body starting with `[X-Aeon Agent (.+)]``)).
            @artifacts[:pr_conversations] = pr_json[:reviewThreads][:edges].select do |review_thread|
              !review_thread[:node][:isResolved] &&
                !review_thread[:node][:comments][:nodes].select do |comment|
                  # Check if comment is directed at AI Agent and does not have an AI Agent reply (recursively)
                  # Mark it using an extra variable that we will use later to retrieve it
                  comment[:needAIReply] = comment[:body]&.start_with?('/agent') &&
                    !has_ai_reply_to_comment?(review_thread[:node][:comments][:nodes], comment[:databaseId])
                  comment[:needAIReply]
                end.empty?
            end.map do |review_thread|
              # Simplify the schema and only keep what is useful to us.
              # Sort it by creation date too.
              review_thread[:node][:comments][:nodes].sort_by { |comment| comment[:createdAt] }.map do |comment|
                {
                  comment_id: comment[:databaseId],
                  created_at: comment[:createdAt],
                  reply_to_comment_id: comment[:replyTo],
                  author: comment[:author][:login],
                  body: comment[:body],
                  subject_type: comment[:subjectType],
                  path: comment[:path],
                  commit: {
                    sha: comment[:commit][:oid],
                    message: comment[:commit][:message]
                  },
                  line: comment[:line],
                  start_line: comment[:startLine],
                  original_commit: {
                    sha: comment[:originalCommit][:oid],
                    message: comment[:originalCommit][:message]
                  },
                  original_line: comment[:originalLine],
                  original_start_line: comment[:originalStartLine],
                  diff_hunk: comment[:diffHunk],
                  need_ai_reply: comment[:needAIReply]
                }
              end
            end.to_json
          end

          pr_conversations = JSON.parse(@artifacts[:pr_conversations], symbolize_names: true)
          if pr_conversations.empty?
            log_debug "No PR reviews conversations found that need X-Aeon Agents input for PR ##{pull_request_number}"
          else
            log_debug "Found #{pr_conversations.size} PR reviews conversations that need X-Aeon Agents input for PR ##{pull_request_number}"
            open_comments_to_agents = pr_conversations.map do |conversation|
              conversation.select { |comment| comment[:need_ai_reply] }
            end.flatten(1)

          step(:aprc_b_extract_requirements) do
            pr = github.pull_request(github_repo, pull_request_number)
            @artifacts[:pr_description] = <<~EO_Description.strip
              # #{pr.title}

              #{align_markdown_headers(pr.body, level: 2)}
            EO_Description
            @artifacts[:pr_files_diffs] = git.diff("#{pr.base.sha}...#{pr.head.sha}")
            @artifacts[:conversations] = JSON.pretty_generate(pr_conversations)
            @artifacts[:open_comments_to_agents] = JSON.pretty_generate(open_comments_to_agents)
              run(pr_requirements_extractor_agent)
              @artifacts[:requirements] = 'No requirements' if @artifacts[:requirements].strip.downcase == 'no requirements'
            end

            if @artifacts[:requirements] == 'No requirements'
              log_debug 'No requirements to implement'
              @artifacts[:plan] = 'No implementation plan'
              @artifacts[:files_diffs] = 'No changes'
            else
              log_debug 'Requirements found, implementing...'
              implement_requirements(@artifacts[:requirements], commit: true, pull_request: true)
            end
            
            # Reply to each agent-directed comment
            open_comments_to_agents.each.with_index do |comment, comment_idx|
              step("aprc_c#{comment_idx}_reply_to_comment".to_sym) do
                @artifacts[:open_comment_for_reply] = JSON.pretty_generate(comment)
                run(review_responder_agent)
                reply = github.create_pull_request_comment_reply(github_repo, pull_request_number, "[X-Aeon Agent (#{review_responder_agent.model})] - #{@artifacts[:reply]}", comment[:comment_id])
                log_debug "Successfully replied to comment ##{comment[:comment_id]}: #{reply[:html_url]}"
              end
            end
          end
        end
        puts
        puts 'Pull Request comments addressed successfully'
      end

      private

      # Format comments for use in artifacts
      #
      # Parameters::
      # * *comments* (Array<Octokit::IssueComment>): Comments to format
      # Result::
      # * String: Formatted comments as markdown
      def format_comments_for_artifact(comments)
        return "No comments" if comments.empty?
        
        comments.sort_by(&:created_at).map do |comment|
          <<~EO_Comment
            ## #{comment.user.login} at #{comment.created_at.utc.strftime('%F %T UTC')}
            
            #{align_markdown_headers(comment.body, level: 3)}
          EO_Comment
        end.join("\n")
      end

      private

      # Loop over all Cline models
      #
      # Parameters::
      # * Proc: Code called for each Cline model
      #   * Parameters::
      #     * *cline_model_name* (String): The Cline mode name
      #     * *cline_model* (Hash): The Cline model definition
      def for_each_cline_model
        JSON.parse(File.read("#{ENV['VSCODE_PORTABLE'] ? "#{ENV['VSCODE_PORTABLE']}/user-data" : "#{ENV['APPDATA']}/Code"}/User/globalStorage/saoudrizwan.claude-dev/cache/cline_models.json"), symbolize_names: true).each do |name, info|
          yield name.to_s, info
        end
      end

      # Get a Git instance on the current directory.
      # Keep a cache of it.
      #
      # Result::
      # * Git::Base: The git instance
      def git
        @git_pwd ||= Git.open(Dir.pwd)
      end

      # Get a Github Octokit API instance.
      # Keep a cache of it.
      #
      # Result::
      # * Octokit::Client: The Octokit client
      def github
        @github_octokit ||= Octokit::Client.new(access_token: config[:github_token])
      end

      # Get the Github remote from the Git remotes.
      # Keep a cache of it.
      #
      # Result::
      # * Git::Remote: The Github remote instance
      def github_remote
        @github_remote ||= begin
          remote = git.remotes.find { |remote| remote.url.match(%r{github\.com[:/].+\.git}) }
          raise 'Can\'t find a Github remote in this repository' if remote.nil?
          remote
        end
      end

      # Get the current repository name from the Git remote URL.
      # Keep a cache of it.
      #
      # Result::
      # * String: The repository name in the format "owner/repo"
      def github_repo
        @github_repo ||= github_remote.url.match(%r{github\.com[:/](.+)\.git})[1]
      end

      # Get the read-only configuration used by agents that are planning and analyzing code
      #
      # Result::
      # * Hash: The read-only configuration
      def read_only_config
        @read_only_config ||= Helpers.deep_merge(
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
        )
      end

      # Create the Manager agent
      #
      # Result::
      # * ::Agents::Agent: The Manager agent
      def manager_agent
        @manager_agent ||= cline_agent(
          name: 'Manager',
          objective: 'Coordinate the work of other agents to fully implement a Github issue'
        )
      end

      # Create the Planner agent
      #
      # Result::
      # * ::Agents::Agent: The Planner agent
      def planner_agent
        @planner_agent ||= cline_agent(
          name: 'Planner',
          objective: 'Produce a full and detailed implementation plan that can be used to implement some requirements.',
          input_artifacts: [
            { name: :requirements, description: 'Initial requirements for which you need to devise an implementation plan' }
          ],
          output_artifacts: [
            {
              name: :plan,
              description: 'the full and detailed implementation plan that should implement the requirements given by the `ARTIFACT_REQUIREMENTS` artifact',
              to_be_reviewed: true
            }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            enforcing-project-rules
          ],
          plan_mode: true,
          config: read_only_config,
          instructions: {
            ordered_list: [
              'Read the initial requirements from the `ARTIFACT_REQUIREMENTS` artifact',
              'Analyze the project files',
              'Devise a **step-by-step implementation plan**',
            ]
          },
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You may only analyze and propose plans.
            - Do NOT execute the plan yourself.
          EO_Constraints
        )
      end

      # Create the Diff interpreter agent
      #
      # Result::
      # * ::Agents::Agent: The Diff interpreter agent
      def diff_interpreter_agent
        @diff_interpreter_agent ||= cline_agent(
          name: 'Diff interpreter',
          objective: <<~EO_Objective,
            Interpret files modifications and explain the changes properly with its meaning and intent.

            The goals are:
            - Get a general explanation of those changes.
            - Identify the kind of changes involved (new features, feature change, bug fix, documentation...).
            - Identify the components that are impacted by those changes (a specific plugin, CLI, UI...).
          EO_Objective
          input_artifacts: [
            { name: :files_diffs, description: 'Full list of files changes and differences that have been done' }
          ],
          output_artifacts: [
            { name: :change_intent, description: 'the full explanation of the changes, as in a git commit description' }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            enforcing-project-rules
          ],
          plan_mode: false,
          config: read_only_config.merge(
            doubleCheckCompletionEnabled: false
          ),
          instructions: <<~EO_Instructions,
            ## 1. Read and analyze ALL file changes from the `ARTIFACT_FILES_DIFFS` artifact
            
            - Those changes are the ones you must explain.
            
            ## 2. Analyze the project files
            
            - Those files give you context to understand the changes.
            - Changes made on those files should NOT be explained unless they are part of the `ARTIFACT_FILES_DIFFS` artifact.
            
            ## 3. Explain properly the changes reported by the `ARTIFACT_FILES_DIFFS` artifact

            - You MUST produce an output that includes:
            1. A general explanation of the changes, their meaning and intent in the context of this project.
            2. The types of changes (feature, bug fix, documentation, etc.).
            3. The impacted architectural components (backend, login screen, CLI, etc.).
            - Describe those changes as in a git commit or pull request description.
            - ONLY cover changes from the `ARTIFACT_FILES_DIFFS` artifact.
            - Do NOT explain changes for other files.
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You must ONLY explain the changes of the `ARTIFACT_FILES_DIFFS` artifact content, NOT other changes.
            - You already have ALL the information required.
            - The user's intent is fully specified.
            - The conversation log is provided for context only. You MUST NOT ask follow-up questions.
          EO_Constraints
        )
      end

      # Create the 1-line code diff summarizer agent
      #
      # Result::
      # * ::Agents::Agent: The 1-line code diff summarizer agent
      def one_line_code_diff_summarizer
        @one_line_code_diff_summarizer ||= cline_agent(
          name: '1-line code diff summarizer',
          objective: 'Produce a 1-line summary of a code change intent report.',
          input_artifacts: [
            { name: :change_intent, description: 'The full description of the code changes, their meaning and intent' }
          ],
          output_artifacts: [
            { name: :one_line_summary, description: 'the 1-line summary of the code change intent' }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            enforcing-project-rules
          ],
          plan_mode: false,
          config: read_only_config.merge(
            doubleCheckCompletionEnabled: false
          ),
          instructions: <<~EO_Instructions,
            ## Provide a 1-line summary of the code change intent described in the `ARTIFACT_CHANGE_INTENT` artifact
            
            - Follow standard git commit title conventions using `feat`, `fix`, etc... with impacted component names.
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You already have ALL the information required.
            - The user's intent is fully specified.
            - You MUST NOT ask follow-up questions.
          EO_Constraints
        )
      end

      # Create the Developer agent
      #
      # Result::
      # * ::Agents::Agent: The Developer agent
      def developer_agent
        @developer_agent ||= cline_agent(
          name: 'Developer',
          objective: 'Implement a task',
          input_artifacts: [
            { name: :plan, description: 'Implementation plan that you must follow' }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: <<~EO_Instructions
            Follow all the steps of the implementation plan described in the `ARTIFACT_PLAN` artifact.
          EO_Instructions
        )
      end

      # Create the Tester agent
      #
      # Result::
      # * ::Agents::Agent: The Tester agent
      def tester_agent
        @tester_agent ||= cline_agent(
          name: 'Tester',
          objective: <<~EO_Objective,
            Fix any regression that has been induced by new features or fixes, while keeping the initial requirements and implementation plan in mind.
            If the decisions taken in the implementation plan prevent you from fixing regressions, modify the implementation plan and report those modifications to the user.
          EO_Objective
          input_artifacts: [
            { name: :requirements, description: 'Initial requirements' },
            { name: :plan, description: 'Implementation plan devised from the requirements' },
            { name: :files_diffs, description: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan' },
            { name: :tests_output, description: 'Output of running the whole tests suite' },
            { name: :tests_cmd, description: 'Command line to be used to run the whole tests suite' }
          ],
          output_artifacts: [
            { name: :plan_modifications, description: 'the modification or divergence you considered from the implementation plan' }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
          ],
          instructions: {
            ordered_list: [
              <<~EO_Step,
                Understand the initial requirements from the `ARTIFACT_REQUIREMENTS` artifact
                
                - Understand those requirements.
              EO_Step
              <<~EO_Step,
                Understand the implementation plan from the `ARTIFACT_PLAN` artifact
                
                - Understand all the steps of the implementation plan.
              EO_Step
              <<~EO_Step,
                Understand the concrete changes from the `ARTIFACT_FILES_DIFFS` artifact

                - Understand what was the intent of the developer implementing those requirements.
              EO_Step
              <<~EO_Step,
                Analyze the full output of unit tests run from the `ARTIFACT_TESTS_OUTPUT` artifact
                
                - Check every error reported in the output.
              EO_Step
              'Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements',
              'Remember any inconsistency and modification you need to make to the implementation plan so that your fixes are in-line with a better implementation plan',
              <<~EO_Step
                Make sure all tests are running without issue after your fixes
                
                - You can run tests again using the provided tests command from the `ARTIFACT_TESTS_CMD` artifact to test your own fixes.
              EO_Step
            ]
          }
        )
      end

      # Create the Documenter agent
      #
      # Result::
      # * ::Agents::Agent: The Documenter agent
      def documenter_agent
        @documenter_agent ||= cline_agent(
          name: 'Documenter',
          objective: 'Update relevant documentation when a task is being implemented.',
          input_artifacts: [
            { name: :requirements, description: 'Initial requirements' },
            { name: :plan, description: 'Implementation plan that introduced features and fixes to be documented' },
            { name: :files_diffs, description: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan' }
          ],
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            editing-files
            enforcing-project-rules
            updating-doc
          ],
          instructions: <<~EO_Instructions,
            ## 1. Analyze the initial requirements from the `ARTIFACT_REQUIREMENTS` artifact
            
            - Those give you information about the requirements you should be documenting.
                
            ## 2. Analyze all the steps of the implementation plan from the `ARTIFACT_PLAN` artifact

            - Those give you every step that should have been followed for this new development.
                
            ## 3. Analyze the concrete changes from the `ARTIFACT_FILES_DIFFS` artifact

            - Understand what was the intent of the developer implementing those requirements.

            ## 4. Explore the filesystem to locate documentation files

            Guidelines:
            - Start with README.md and docs/**/*.md if they exist.
            - Look for files mentioning related features or APIs.
            - Find documentation files that are referenced recursively from other documentation files.
            - Understand the documentation structure and content.
            - If no relevant documentation is found, proceed by assuming documentation needs to be created or extended.
            - If you are unsure which documentation file to update: default to updating README.md.

            This step is best-effort and should not block progress.

            ## 5. Update the relevant documentation files

            - Use artifacts as the source of truth for understanding the changes to be documented.
            - Use the filesystem to locate where documentation should be updated.
            - After exploring the filesystem, if relevant documentation files are found: update them.
                          
            When updating documentation:
            - Modify existing sections if they already describe related functionality.
            - Add new sections if the feature is not documented.
            - Keep consistency with existing documentation style.
            - Prefer minimal, precise updates over large rewrites.
          EO_Instructions
          constraints: <<~EO_Constraints
            - Only update documentation files.
            - Do NOT change any code or test.
          EO_Constraints
        )
      end

      # Create the Releaser agent
      #
      # Result::
      # * ::Agents::Agent: The Releaser agent
      def releaser_agent
        @releaser_agent ||= cline_agent(
          name: 'Releaser',
          objective: 'Release a new feature or bugfix to its branch on Github, with a Pull Request'
        )
      end

      # Create the PRRequirementsExtractor agent
      #
      # Result::
      # * ::Agents::Agent: The PRRequirementsExtractor agent
      def pr_requirements_extractor_agent
        @pr_requirements_extractor_agent ||= cline_agent(
          name: 'PRRequirementsExtractor',
          objective: 'Extract requirements from PR comments directed at X-Aeon Agents',
          input_artifacts: [
            { name: :pr_description, description: 'Pull Request description (context)' },
            { name: :pr_files_diffs, description: 'Files modifications that were done in this Pull Request (context)' },
            { name: :conversations, description: 'All Pull Request conversations and comments to be considered (context)' },
            { name: :open_comments_to_agents, description: 'Exact list of agent-directed comments that need to be addressed' }
          ],
          output_artifacts: [
            { name: :requirements, description: 'the requirements that will implement what is needed by the agent-directed comments (reply "No requirements" if there is no implementation needed)' }
          ],
          config: read_only_config,
          instructions: <<~EO_Instructions,
            ## 1. Read the `ARTIFACT_PR_DESCRIPTION` artifact to understand the purpose of this Pull Request
            
            - This gives you context on what is the purpose of this Pull Request.

            ## 2. Read the `ARTIFACT_PR_FILES_DIFFS` artifact to understand all changes made by this Pull Request
            
            - This gives you context on how has this Pull Request been implemented.

            ## 3. Read the `ARTIFACT_CONVERSATIONS` artifact to understand the full context of the PR conversations
            
            - This gives you context on the discussions around this Pull Request.

            ## 4. Read the `ARTIFACT_OPEN_COMMENTS_TO_AGENTS` artifact to focus on agent-directed comments
            
            - You must devise requirements that will address those exact comments.

            ## 5. Analyze agent-directed comments to identify specific requirements or tasks that need implementation
            
            ## 6. Extract clear, actionable requirements from the comments
            
            - If no implementation is required (e.g., comments are just questions), output "No requirements"
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - Focus only on agent-directed comments (/agent) for requirement extraction.
            - Output clear, actionable requirements or "No requirements" if none exist.
          EO_Constraints
        )
      end

      # Create the ReviewResponder agent
      #
      # Result::
      # * ::Agents::Agent: The ReviewResponder agent
      def review_responder_agent
        @review_responder_agent ||= cline_agent(
          name: 'ReviewResponder',
          objective: 'Generate a reply to a review comment',
          input_artifacts: [
            { name: :conversations, description: 'All PR conversations and comments to be considered (context)' },
            { name: :open_comment_for_reply, description: 'Exact comment to be replied to' },
            { name: :requirements, description: 'Requirements implemented (or "No requirements")' },
            { name: :plan, description: 'Implementation plan from implement_requirements workflow (or "No implementation plan")' },
            { name: :files_diffs, description: 'Code changes from implement_requirements workflow (or "No changes")' }
          ],
          output_artifacts: [
            { name: :reply, description: 'the exact reply text to post' }
          ],
          plan_mode: false,
          config: read_only_config.merge(
            doubleCheckCompletionEnabled: false
          ),
          instructions: <<~EO_Instructions,
            ## 1. Read the `ARTIFACT_CONVERSATIONS` artifact to understand the full context of the PR conversations
            
            - This gives you context on the discussions around this Pull Request.
            
            ## 2. Read the `ARTIFACT_REQUIREMENTS` artifact to understand what was implemented
            
            - This gives you context on what has been implemented by other agents.
            
            ## 3. Read the `ARTIFACT_PLAN` artifact to understand the implementation approach
            
            - This gives you context on how other agents implemented the requirements.

            ## 4. Read the `ARTIFACT_FILES_DIFFS` artifact to understand the specific code changes made

            - This gives you context on what files have been modified.

            ## 5. Read the `ARTIFACT_OPEN_COMMENT_FOR_REPLY` artifact to understand the specific comment to respond to
            
            - This is the EXACT comment that you should reply to.

            ## 6. Generate a professional, helpful reply that addresses the comment appropriately
            
            - If requirements were implemented, explain what was done and how it addresses the comment.
            - If no requirements existed, provide a helpful response explaining the situation.
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - The implementation work is already complete (captured in the artifacts).
            - Generate a professional, helpful response to the review comment.
            - ONLY focus on addressing the specific comment of the `ARTIFACT_OPEN_COMMENT_FOR_REPLY` artifact appropriately.
            - Do NOT answer or reply to any other comment.
            - You already have ALL the information required.
            - You MUST NOT ask follow-up questions.
            - You MUST NOT ask for user confirmation.
          EO_Constraints
        )
      end

      # Get current code diffs interpretation
      #
      # Parameters::
      # * *base* (Object): Git base (sha, objectish...) with which we diff [default = 'HEAD']
      # Result::
      # * String: The current code diffs summarized as 1 line
      # * String: The current code diffs with details
      def code_diffs(base = 'HEAD')
        @artifacts[:files_diffs] = artifact_files_diffs(base)
        run(diff_interpreter_agent)
        run(one_line_code_diff_summarizer)
        [
          @artifacts[:one_line_summary].each_line.first.strip,
          @artifacts[:change_intent].strip
        ]
      end

      # Create a Pull Request if it does not exist already for the current branch against main
      def create_pr
        repo_name = github_repo
        head_branch = git.current_branch

        # Push the branch on the git_remote using --force-with-lease as it may have been rebased
        # TODO: Use force_with_lease when it will be supported by ruby-git
        git.push(github_remote, head_branch, force: true)
       
        # Check if PR already exists for the current branch
        existing_pr = github.pull_requests(repo_name, state: 'open').find { |pull_request| pull_request.head.ref == head_branch }
        if existing_pr.nil?
          # Create new PR
          title, description = code_diffs(@artifacts[:base_sha])
          sections = [description]
          sections << <<~EO_Section if @artifacts[:requirements]
              # Initial requirements given
              
              #{align_markdown_headers(@artifacts[:requirements], level: 2)}
          EO_Section
          sections << <<~EO_Section unless @artifacts[:user_feedbacks].nil?
              # User guidance and feedback to agents
              
              #{align_markdown_headers(@artifacts[:user_feedbacks], level: 2)}
          EO_Section
          sections << <<~EO_Section unless @artifacts[:agents_run].nil?
            # Co-authored by X-Aeon AI Agents
            
            #{@artifacts[:agents_run].each_line.uniq.join}
          EO_Section
          new_pr = github.create_pull_request(
            repo_name,
            'main',
            head_branch,
            title,
            sections.map { |section| section.strip }.join("\n\n")
          )
          log_debug "Created new Pull Request for branch #{head_branch}: #{new_pr.html_url}"
        else
          log_debug "A Pull Request for branch #{head_branch} already exists: #{existing_pr.html_url}"
        end
      end
      
      # Git commit and author properly what the agent modified
      #
      # Parameters::
      # * *author_agent* (::Agents::Agent): The agent authoring the changes
      def git_commit(author_agent)
        git_status = git.status
        if git_status.changed.empty? && git_status.added.empty? && git_status.deleted.empty? && git_status.untracked.empty?
          log_debug 'Nothing to commit'
        else
          git.add(all: true)
          git.commit <<~EO_Commit.strip
            #{code_diffs.join("\n\n")}
            
            Co-authored by: X-Aeon Agent #{author_agent.name} (#{author_agent.model})
          EO_Commit
        end
      end

      # Get a current files diffs
      #
      # Parameters::
      # * *base* (Object): Git base (sha, objectish...) with which we diff [default = 'HEAD']
      def artifact_files_diffs(base = 'HEAD')
        <<~EO_Artifact
          ### New untracked files

          #{git.status.untracked.keys.map do |file|
            <<~EO_Untracked_File
              #### #{file}
              ```
              #{File.read(file)}
              ```
            EO_Untracked_File
          end.join("\n")}

          ### git diff

          ```
          #{git.diff(base)}
          ```
        EO_Artifact
      end

      # Define a step that can be serialized and resumed.
      # This will store the state of this step in the file system.
      # If this step was already executed, skip it and update its artifacts from the file system store.
      #
      # Parameters::
      # * *name* (Symbol): Step name
      # * Proc: The code called for this step
      def step(name)
        if @run_id.nil?
          yield
        else
          step_dir = ".x-aeon_agents/runs/#{@run_id}/#{name}"
          step_file = "#{step_dir}/step.json"
          if File.exist?(step_file) && JSON.parse(File.read(step_file), symbolize_names: true)[:executed]
            # This step was already executed
            # Read all the artifacts
            @artifacts.replace(Dir.glob("#{step_dir}/*.md").to_h { |file| [File.basename(file, '.md').to_sym, File.read(file)] })
            log_debug "[Step #{name}] - Executed - #{@artifacts.size} artifacts read from persistence: #{@artifacts.keys.join(', ')}"
          else
            yield
            FileUtils.mkdir_p(step_dir)
            # Serialize all the artifacts
            @artifacts.each do |artifact_name, artifact_content|
              File.write("#{step_dir}/#{artifact_name}.md", artifact_content)
            end
            # Mark the step as executed
            File.write("#{step_dir}/step.json", { executed: true }.to_json)
            log_debug "[Step #{name}] - Executed - Stored #{@artifacts.size} artifacts in persistence: #{@artifacts.keys.join(', ')}"
          end
        end
      end

      # Setup an agents runner.
      # This method is re-entrant, meaning it can be called multiple times within the same execution context.
      # If a runner is already initialized, it will reuse the existing runner and artifacts.
      #
      # Parameters::
      # * *run_id* (String or nil): The run ID, or nil if persistence is not needed [default = nil]
      # * Proc: Code called with the runner setup
      def with_runner(run_id = nil)
        # If runner is already initialized, reuse existing runner and artifacts
        unless @runner
          # Initialize new runner and artifacts
          @run_id = run_id
          @runner = ::Agents::Runner.new
          @artifacts = {}
        end
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
        # Keep user's feedback in an artifact
        unless agent.params[:agent][:asks].empty?
          @artifacts[:user_feedbacks] = <<~EO_Artifact if @artifacts[:user_feedbacks].nil?
            The following is a conversation log.
            Each section is independent and labeled by speaker.
            Do not merge messages across roles.

          EO_Artifact
          @artifacts[:user_feedbacks] << <<~EO_Artifact
            ## Conversation between Agent: #{agent.name} and User
            
            #{
              agent.params[:agent][:asks].map do |ask|
                <<~EO_Ask
                  ### Agent: #{agent.name}
                  
                  ```
                  #{ask[:question]}
                  ```
                  
                  ### User
                  
                  ```
                  #{ask[:feedback]}
                  ```

                EO_Ask
              end.join
            }

          EO_Artifact
        end
        # Keep the log of the agent's run in an artifact
        @artifacts[:agents_run] = '' if @artifacts[:agents_run].nil?
        @artifacts[:agents_run] << "* #{agent.name}: #{agent.model}\n"
        result.output
      end

      # Create a Cline agent.
      # Artifacts are defined with these properties:
      # * *name* (Symbol): Artifact's name
      # * *description* (String): Artifact's description
      # * *to_be_reviewed* (Boolean): Does this artifact need user review during output? [default: false]
      #
      # Parameters::
      # * *name* (String): Agent name [default: 'Executor']
      # * *role* (String): Agent's role [default: "You are a #{name} agent"]
      # * *objective* (String): Agent's objective [default: '']
      # * *instructions* (String): Agent's system instructions [default: '']
      # * *constraints* (String): Constraints to be respected [default: '']
      # * *input_artifacts* (Array<Hash>): Set of artifacts this agent expects as input [default: []]
      # * *output_artifacts* (Array<Hash>): Set of artifacts this agent is expected to output [default: []]
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
        input_artifacts: [],
        output_artifacts: [],
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
              constraints:,
              asks: []
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
          instructions: system_instructions(name:, instructions:)
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
      # Result::
      # * String: The resulting instructions as a string
      def system_instructions(name:, instructions:)
        # Normalize instructions
        instructions = (instructions.is_a?(Array) ? instructions : [instructions]).
          map { |instruction_desc| instruction_desc.is_a?(Hash) ? instruction_desc : { text: instruction_desc } }

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

      # Check if there's an AI Agent reply to a specific comment, recursively checking all reply levels
      #
      # Parameters::
      # * *comments* (Array<Hash>): All comments in the thread
      # * *comment_id* (Integer): The databaseId of the comment to check for replies
      # Result::
      # * Boolean: true if there's an AI Agent reply to the comment, false otherwise
      def has_ai_reply_to_comment?(comments, comment_id)
        comments.any? do |reply|
          reply[:replyTo]&.fetch(:databaseId, nil) == comment_id && (
            reply[:body].match(/^\[X-Aeon Agent \([^)]+\)\]/) ||
              has_ai_reply_to_comment?(comments, reply[:databaseId])
          )
        end
      end

      # Align markdown headers in a String to a given level.
      # This method parses the String as a markdown document, sees the minimum current header level,
      # and changes it while preserving the structure and hierarchy so that this min level is equal to `level`.
      #
      # Parameters::
      # * *markdown* (String): The markdown content to align
      # * *level* (Integer): The target level for the minimum header [default: 2]
      # Result::
      # * String: The aligned markdown content
      def align_markdown_headers(markdown, level: 2)
        doc = Commonmarker.parse(markdown)
        min_level = find_minimum_header_level(doc)
        return markdown if min_level.nil? || min_level == level
        
        adjust_header_levels(doc, level - min_level)
        doc.to_commonmark
      end

      # Find the minimum header level in a CommonMarker document
      #
      # Parameters::
      # * *doc* (CommonMarker::Document): The parsed CommonMarker document
      # Result::
      # * Integer or nil: The minimum header level found, or nil if no headers exist
      def find_minimum_header_level(doc)
        min_level = nil
        doc.walk do |node|
          if node.type == :heading
            current_level = node.header_level
            min_level = current_level if min_level.nil? || current_level < min_level
          end
        end
        min_level
      end

      # Adjust header levels in a CommonMarker document by a given difference
      #
      # Parameters::
      # * *doc* (CommonMarker::Document): The parsed CommonMarker document
      # * *level_diff* (Integer): The difference to add to each header level
      def adjust_header_levels(doc, level_diff)
        doc.walk do |node|
          node.header_level = node.header_level + level_diff if node.type == :heading
        end
      end

    end

  end

end
