require 'yaml'

module XAeonAgentsSkills

  # Helper methods for generating skill content
  module GenHelpers

    # Define a skill metadata.
    # This should always be the first call in a skill ERB file.
    # It also returns the corresponding YAML frontmatter.
    # The name is automatically derived from skill_name.
    #
    # Parameters::
    # * *description* (String): Description of the skill
    # * *dependencies* (Array<String>): List of skills dependencies [default: []]
    # * *plan* (Boolean): Is this skill applicable to plan mode? [default: false]
    # * *metadata* (Hash): Optional metadata key-value pairs [default: {}]
    #
    # Result::
    # * String: The complete YAML frontmatter block (including --- delimiters)
    def skill(description:, dependencies: [], plan: false, metadata: {})
      frontmatter = {
        'name' => skill_name,
        'description' => "#{description}#{plan ? ' Use this skill also in Plan mode.' : ''}"
      }
      metadata['agent'] = 'Plan' if plan
      metadata['dependencies'] = dependencies unless dependencies.empty?
      frontmatter['metadata'] = metadata.transform_keys(&:to_s) unless metadata.empty?
      YAML.dump(frontmatter, line_width: -1).chomp + "\n---"
    end

    # Define or get the skill goal to be used in ERB templates
    #
    # Parameters::
    # * *goal_desc* (String or nil): The skill goal, or nil to retrieve the previously set skill goal [default = nil]
    # Result::
    # * String: The skill goal
    def skill_goal(goal_desc = nil)
      @skill_goal = goal_desc unless goal_desc.nil?
      @skill_goal
    end

    # Get the skill goal as a sentence
    # Prerequisite: skill_goal should be set before.
    #
    # Result::
    # * String: The skill goal as useable inside a sentence
    def skill_goal_sentence
      "#{@skill_goal[0].downcase}#{@skill_goal[1..]}"
    end

    # Return the prompt to announce that the agent is working on a skill.
    # Prerequisite: skill_goal should be set before.
    def announce_skill
      "Always tell the user \"SKILL: I am #{skill_goal_sentence}\" to inform the user that you are running this skill."
    end

    # Return a default temporary folder that agents can use in a project.
    # It's better to force it to the agents, as some models will try weird CLI commands to create temporary files otherwise.
    #
    # Result::
    # * String: Temporary folder path
    def tmp_path
      './.tmp_agents'
    end

    # Generate a rule documentation block with examples and rationale.
    #
    # Parameters::
    # * *title* (String): The rule title
    # * *description* (String or nil): The additional description [default: nil]
    # * *type* (Symbol): The code block language type (e.g., :bash, :ruby) [default: :ruby]
    # * *bad* (String or nil): The incorrect example [default: nil]
    # * *good* (String or nil): The correct example [default: nil]
    # * *rationale* (String or nil): The explanation for why this rule exists [default: nil]
    #
    # Result::
    # * String: The formatted markdown documentation for the rule
    def rule(title, description: nil, type: :ruby, bad: nil, good: nil, rationale: nil)
      markdown_sections = [
        <<~EO_Markdown
          ### Rule: #{title}#{description.nil? ? '' : "\n\n#{description.strip}"}
        EO_Markdown
      ]
      unless bad.nil?
        markdown_sections << <<~EO_Markdown
          #### Example: Incorrect

          ```#{type}
          #{bad.strip}
          ```
        EO_Markdown
      end
      unless good.nil?
        markdown_sections << <<~EO_Markdown
          #### Example: Correct

          ```#{type}
          #{good.strip}
          ```
        EO_Markdown
      end
      unless rationale.nil?
        markdown_sections << <<~EO_Markdown
          #### Rationale

          #{rationale}
        EO_Markdown
      end
      markdown_sections.join("\n").strip
    end

    # Define an ordered todo list for a skill.
    # Captures the ERB block content, parses its ## sections, numbers them starting at 2
    # (section 1 "Inform the USER" is auto-generated), and wraps everything with the
    # standard skill header, checklist initialization, and final verification sections.
    #
    # Parameters::
    # * *block* (Proc): ERB block containing the markdown sections
    def define_ordered_todo_list(&block)
      # Capture the ERB block content using buffer manipulation
      erb_buffer = eval('_erbout', block.binding)
      saved_content = erb_buffer.dup
      erb_buffer.clear
      yield
      captured = erb_buffer.dup
      erb_buffer.replace(saved_content)

      # Dedent the captured content: remove common leading whitespace
      lines = captured.lines
      min_indent = lines.reject { |l| l.strip.empty? }.map { |l| l.match(/^(\s*)/)[1].length }.min || 0
      # Split into sections by ## headings
      # Number sections starting from 2 and strip trailing whitespace
      step_number = 2
      numbered_sections = lines.
        map { |l| l.strip.empty? ? "\n" : l[min_indent..] }.
        join.
        strip.
        split(/^(?=### )/).
        reject { |s| s.strip.empty? }.
        map do |section|
          numbered = section.sub(/^### /, "### #{step_number}. ").rstrip
          step_number += 1
          numbered
        end

      # Compose the full output and append directly to ERB buffer
      # (we use <% %> not <%= %> since standard ERB doesn't support <%= method do %>)
      erb_buffer << <<~EO_Markdown
        ## Sequential steps to be followed when using this skill

        When #{skill_goal_sentence}, follow those steps.

        #{init_skill_checklist.rstrip}

        ### 1. Inform the user

        - #{announce_skill}

        #{numbered_sections.join("\n\n")}

        #{validate_skill_checklist.rstrip}
      EO_Markdown
    end

    # Return the skill config hash from its .skill_config.yml file, if it exists.
    #
    # Parameters::
    # * *skill_name* (String): The skill name (matching a directory under skills.src/)
    #
    # Result::
    # * Hash: The YAML config hash, or an empty Hash if no config file exists
    def self.skill_config(skill_name)
      skill_config_file = "skills.src/#{skill_name}/.skill_config.yml"
      File.exist?(skill_config_file) ? YAML.load_file(skill_config_file) : {}
    end

    # Return the skill being generated
    #
    # Result::
    # * String: Skill name being generated
    def skill_name
      current_erb_file.match(/\/skills\.src\/([^\/]+)\//)[1]
    end

    # Small class that can serve as a container for ERB evaluation with our DSL
    class ErbEvaluator

      include XAeonAgentsSkills::GenHelpers

      # Constructor
      #
      # Parameters::
      # * *erb_file* (String): File containing the ERB template
      def initialize(erb_file)
        @erb = ERB.new(File.read(erb_file), trim_mode: '-')
        # Use filename for better error reporting
        @erb.filename = erb_file
      end

      # Evaluate the ERB template
      #
      # Result::
      # * String: The evaluated ERB result
      def result
        @erb.result(binding)
      end

    end

    private

    # Return the ERB file being generated
    #
    # Result::
    # * String: ERB file being generated
    def current_erb_file
      file_found = caller.find { |stack_trace| stack_trace =~ /(\/skills\.src\/.+\.erb)/ }
      raise "Unable to find ERB file among stack:\n#{caller.join("\n")}" if file_found.nil?
      Regexp.last_match[1]
    end

    # Return the execution checklist initialization section
    #
    # Result::
    # * String: The execution checklist section
    def init_skill_checklist
      <<~EO_Markdown
        ### Create the #{skill_name} Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named #{skill_name} Execution Checklist with all steps of this skill.
        - The #{skill_name} Execution Checklist must include all numbered steps explicitly.
        - The #{skill_name} Execution Checklist must be displayed to the user.
        - After completing each step of this skill, mark the item in the #{skill_name} Execution Checklist as completed, and display again the #{skill_name} Execution Checklist to the user.
        - Do not skip any item.
        - If an item cannot be executed, explicitly explain why.
        - Never mark the skill as completed while any item from the #{skill_name} Execution Checklist remains open.
      EO_Markdown
    end

    # Return the final verification section
    #
    # Result::
    # * String: The final verification section
    def validate_skill_checklist
      <<~EO_Markdown
        ### Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the #{skill_name} Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EO_Markdown
    end

  end

end
