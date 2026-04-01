require 'json'
require 'launchy'
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
        # First check that needed artifacts are present
        missing_input_artifacts = payload[:artifacts][:input].select { |artifact| !payload[:artifacts][:store].key?(artifact[:name]) }
        raise "Missing #{missing_input_artifacts.size} artifacts from the payload:\n#{missing_input_artifacts.map { |artifact| "* #{artifact[:name]}: #{artifact[:description]}" }.join("\n")}" unless missing_input_artifacts.empty?

        @plan_mode = payload[:cline][:plan_mode]

        # Create a JSON prompt to keep the full structure
        prompt_json = {}
        prompt_json[:role] = payload[:agent][:role].strip unless payload[:agent][:role].strip.empty?
        prompt_json[:objective] = payload[:agent][:objective].strip unless payload[:agent][:objective].strip.empty?
        contexts = []
        unless payload[:artifacts][:input].empty?
          contexts << <<~EO_Context.strip
            # Artifacts

            - Artifacts are text documents that you can get as input.
            - Each artifact is identified by a name, like `ARTIFACT_PLAN`.
            #{payload[:artifacts][:input].empty? ? '' : '- You must read all artifacts given in the `artifacts` JSON property: they are given to you by the user.'}
            #{payload[:artifacts][:input].map { |artifact| "- The `ARTIFACT_#{artifact[:name].to_s.upcase}` artifact content is embedded directly in this message. It is NOT a file. Do NOT try to open it." }.join("\n")}
          EO_Context
        end
        contexts << <<~EO_Context.strip unless payload[:artifacts][:store][:user_feedbacks].nil?
          # User guidance and feedback
          
          #{payload[:artifacts][:store][:user_feedbacks]}
        EO_Context
        prompt_json[:context] = contexts.join("\n\n") unless contexts.empty?
        unless payload[:artifacts][:input].empty?
          prompt_json[:artifacts] = payload[:artifacts][:input].to_h do |artifact|
            [
              "ARTIFACT_#{artifact[:name].to_s.upcase}",
              {
                description: artifact[:description],
                content: payload[:artifacts][:store][artifact[:name]].strip
              }
            ]
          end
        end
        prompt_json[:instructions] = payload[:messages].map(&:content).select { |content| !content.strip.empty? }.join("\n\n").strip
        constraints = <<~EO_Constraints
          - Do NOT ask for user confirmation. 
        EO_Constraints
        unless @plan_mode
          constraints << <<~EO_Constraints
            - Do NOT call the tool `plan_mode_respond`.
          EO_Constraints
        end
        constraints << payload[:agent][:constraints] unless payload[:agent][:constraints].empty?
        prompt_json[:constraints] = constraints.strip

        @completion_result = nil
        @artifacts = {}
        @output_artifacts = payload[:artifacts][:output]
        @expected_artifact = nil
        @asks = payload[:agent][:asks]
        @usage = nil
        log_debug { "Cline prompt:\n#{JSON.pretty_generate(prompt_json)}" }
        @cline.prompt(
          prompt_json.to_json,
          model: payload[:model],
          plan_mode: @plan_mode,
          config: payload[:cline][:config],
          skills: payload[:cline][:skills],
          skillkit_agents: true,
          cli_args: payload[:cline][:cli_args],
          on_message: proc do |message, last, _previous_version, usage|
            @usage = usage
            if message[:type] == 'ask' && last
              case message[:ask]
              when 'tool'
                # Do nothing: the CLI agent will automatically pick this up
              when 'plan_mode_respond'
                # Cline just got a plan done.
                if @plan_mode
                  handle_completion(JSON.parse(message[:text], symbolize_names: true)[:response])
                else
                  @cline.user_feedback('You are not in Plan mode, so resume this task.')
                end
              when 'resume_task', 'command_output'
                # Nopthing to do, a new message should be coming in
              when 'followup'
                # Cline is asking for user feedback
                details = JSON.parse(message[:text], symbolize_names: true)
                puts
                puts details[:question]
                puts details[:options] unless details[:options].empty?
                puts '===== Please input your answer to Cline:'
                feedback = $stdin.gets.strip
                @cline.user_feedback(feedback)
                log_ask(details[:question], feedback)
              when 'new_task'
                @cline.user_feedback('Resume task')
              when 'mistake_limit_reached'
                raise "Cline failed to process prompt: #{message}"
              else
                raise "Unknown ask from Cline: #{message}"
              end
            elsif message[:type] == 'say'
              case message[:say]
              when 'completion_result'
                handle_completion(message[:text])
              end
            end
          end,
          ignore_partials: true
        )
        log_debug "#{@artifacts.size} artifacts returned: #{@artifacts.keys.join(', ')}"
        payload[:artifacts][:store].merge!(@artifacts)
        {
          body: @completion_result,
          model: payload[:model],
          usage: @usage
        }
      end

      private

      # Log a question and feedback to the asks array
      #
      # Parameters::
      # * *question* (String): The question asked
      # * *feedback* (String): The user's feedback
      def log_ask(question, feedback)
        @asks << { question: question, feedback: feedback }
      end

      # Handle the completion of a task.
      # This can trigger user feedback, for example to ask for an artifact
      #
      # Parameters::
      # * *response* (String): Last task's response
      def handle_completion(response)
        feedback_given = false
        # If we were expecting an artifact, save it
        unless @expected_artifact.nil?
          if @expected_artifact[:to_be_reviewed]
            log_debug "Asking user to review the `#{@expected_artifact[:name]}` artifact..."
            # Ask for user review of the artifact.
            # If user is not happy with the artifact, give extra feedback for the agent to improve it.
            
            Helpers.with_temp_dir(sub_dir: 'tmp/reviews', suffix: "-#{@expected_artifact[:name]}") do |temp_dir|
              # Generate the markdown file with the artifact content
              artifact_file = File.join(temp_dir, "#{@expected_artifact[:name]}.md")
              File.write(artifact_file, response)
              Launchy.open(artifact_file)
              
              # Ask the user for feedback on the file
              puts
              puts "Please review the `#{@expected_artifact[:name]}` artifact (#{artifact_file}) that has been opened in your default viewer."
              puts 'If you are satisfied with the artifact, respond with \'ok\' or press Enter without typing anything.'
              puts 'Otherwise, please provide your feedback:'
              puts '===== Please input your feedback:'
              feedback = $stdin.gets.strip
              
              # If the user has responded something else than ok or an empty string, 
              # then call @cline.user_feedback and log_ask, and set feedback_given to true
              if feedback.downcase != 'ok' && !feedback.empty?
                @cline.user_feedback(feedback)
                log_ask("Review of #{@expected_artifact[:name]}", feedback)
                feedback_given = true
              end
            end
          end
          unless feedback_given
            log_debug "Received output artifact #{@expected_artifact[:name]}"
            @artifacts[@expected_artifact[:name]] = response
          end
          @expected_artifact = nil
        end

        unless feedback_given
          # Check for expected artifacts and eventually ask to continue if some are missing
          missing_artifacts = @output_artifacts.select { |artifact| !@artifacts.key?(artifact[:name]) }
          if missing_artifacts.empty?
            @completion_result = response
            # In plan mode we force the exit, as CLI is waiting for user confirmation
            @cline.user_feedback(:exit) if @plan_mode
          else
            # Ask Cline to provide the first missing artifact
            @expected_artifact = missing_artifacts.first
            log_debug "Asking for the production of artifact #{@expected_artifact[:name]}"
            @cline.user_feedback(
              <<~EO_Prompt
                What is #{@expected_artifact[:description]}?
              
                - You MUST return ONLY #{@expected_artifact[:description]} in your next response (MANDATORY)
                - Do NOT include any other information.
              EO_Prompt
            )
          end
        end
      end

    end

  end

end
