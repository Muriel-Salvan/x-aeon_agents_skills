require 'json'
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
        missing_input_artifacts = payload[:artifacts][:input].select { |name, _description| !payload[:artifacts][:store].key?(name) }
        raise "Missing #{missing_input_artifacts.size} artifacts from the payload:\n#{missing_input_artifacts.map { |name, description| "* #{name}: #{description}" }.join("\n")}" unless missing_input_artifacts.empty?

        @plan_mode = payload[:cline][:plan_mode]

        # Create a JSON prompt to keep the full structure
        prompt_json = {}
        prompt_json[:role] = payload[:agent][:role].strip unless payload[:agent][:role].strip.empty?
        prompt_json[:objective] = payload[:agent][:objective].strip unless payload[:agent][:objective].strip.empty?
        unless payload[:artifacts][:input].empty? && payload[:artifacts][:output].empty?
          prompt_json[:context] = <<~EO_Context.strip
            # Artifacts

            Artifacts are text documents that you can get as input.
            Each artifact is identified by a name.
            #{payload[:artifacts][:input].empty? ? '' : 'You must read all artifacts given in the `artifacts` JSON property: they are given to you by the user.'}
          EO_Context
        end
        unless payload[:artifacts][:input].empty?
          prompt_json[:artifacts] = payload[:artifacts][:input].to_h do |name, description|
            [
              "ARTIFACT_#{name.to_s.upcase}",
              {
                description:,
                content: payload[:artifacts][:store][name].strip
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
        log_debug { "Cline prompt:\n#{JSON.pretty_generate(prompt_json)}" }
        @cline.prompt(
          prompt_json.to_json,
          model: payload[:model],
          plan_mode: @plan_mode,
          config: payload[:cline][:config],
          skills: payload[:cline][:skills],
          skillkit_agents: true,
          cli_args: payload[:cline][:cli_args],
          on_message: proc do |message, last, _previous_version|
            log_debug { Cline.human_message(message, limit: 128) }
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
              when 'resume_task'
                # @cline.user_feedback('Resume task')
              when 'command_output'
                # @cline.user_feedback('Resume task')
              when 'followup'
                # Cline is asking for user feedback
                details = JSON.parse(message[:text], symbolize_names: true)
                puts
                puts details[:question]
                puts details[:options] unless details[:options].empty?
                puts '===== Please input your answer to Cline:'
                @cline.user_feedback($stdin.gets.strip)
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
          model: payload[:model]
        }
      end

      private

      # Handle the completion of a task.
      # This can trigger user feedback, for example to ask for an artifact
      #
      # Parameters::
      # * *response* (String): Last task's response
      def handle_completion(response)
        # If we were expecting an artifact, save it
        unless @expected_artifact.nil?
          log_debug "Received output artifact #{@expected_artifact}"
          @artifacts[@expected_artifact] = response
          @expected_artifact = nil
        end

        # Check for expected artifacts and eventually ask to continue if some are missing
        missing_artifacts = @output_artifacts.select { |name, _description| !@artifacts.key?(name) }
        if missing_artifacts.empty?
          @completion_result = response
          # In plan mode we force the exit, as CLI is waiting for user confirmation
          @cline.user_feedback(:exit) if @plan_mode
        else
          # Ask Cline to provide the first missing artifact
          @expected_artifact, description = missing_artifacts.first
          log_debug "Asking for the production of artifact #{@expected_artifact}"
          @cline.user_feedback(
            # "Return the implementation plan between `<artifact:#{name}>...</artifact:#{name}>` tags."
            <<~EO_Prompt
              What is #{description}?
            
              - You MUST return ONLY #{description} in your next response (MANDATORY)
              - Do NOT include any other information.
            EO_Prompt
          )
        end
      end

    end

  end

end
