module XAeonAgentsSkills

  # Helper methods for generating skill content
  module GenHelpers

    # Return the execution checklist initialization section
    #
    # Result::
    # * String: The execution checklist section
    def self.init_skill_checklist
      <<~EO_Markdown
        ## Create the #{generating_skill} Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named #{generating_skill} Execution Checklist with ALL steps of this skill.
        - The #{generating_skill} Execution Checklist MUST include ALL numbered steps explicitly.
        - The #{generating_skill} Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the #{generating_skill} Execution Checklist as completed, and display again the #{generating_skill} Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the #{generating_skill} Execution Checklist remains open.
      EO_Markdown
    end

    # Return the final verification section
    #
    # Result::
    # * String: The final verification section
    def self.validate_skill_checklist
      <<~EO_Markdown
        ## Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the #{generating_skill} Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EO_Markdown
    end

    # Define an ordered todo list for a skill.
    # Captures the ERB block content, parses its ## sections, numbers them starting at 2
    # (section 1 "Inform the USER" is auto-generated), and wraps everything with the
    # standard skill header, checklist initialization, and final verification sections.
    #
    # Parameters::
    # * *skill_human_name* (String): Human-readable name of the skill (e.g. 'Committing changes')
    # * *block* (Proc): ERB block containing the markdown sections
    def self.define_ordered_todo_list(skill_human_name, &block)
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
      content = lines.map { |l| l.strip.empty? ? "\n" : l[min_indent..] }.join.strip

      # Split into sections by ## headings
      sections = content.split(/^(?=## )/).reject { |s| s.strip.empty? }

      # Number sections starting from 2 and strip trailing whitespace
      step_number = 2
      numbered_sections = sections.map do |section|
        numbered = section.sub(/^## /, "## #{step_number}. ").rstrip
        step_number += 1
        numbered
      end

      # Build the intro name (lowercase first character)
      intro_name = skill_human_name[0].downcase + skill_human_name[1..]

      # Compose the full output and append directly to ERB buffer
      # (we use <% %> not <%= %> since standard ERB doesn't support <%= method do %>)
      erb_buffer << <<~EO_Markdown
        # #{skill_human_name}

        When #{intro_name}, follow those steps.

        #{init_skill_checklist.rstrip}

        ## 1. Inform the USER

        - ALWAYS inform the user that you are running this skill, saying "SKILL: I am #{intro_name}".

        #{numbered_sections.join("\n\n")}

        #{validate_skill_checklist.rstrip}
      EO_Markdown
    end

    # Return the skill being generated
    #
    # Result::
    # * String: Skill name being generated
    def self.generating_skill
      current_erb_file.match(/\/skills\.src\/([^\/]+)\//)[1]
    end

    private

    # Return the ERB file being generated
    #
    # Result::
    # * String: ERB file being generated
    def self.current_erb_file
      file_found = caller.find { |stack_trace| stack_trace =~ /(\/skills\.src\/.+\.erb)/ }
      raise "Unable to find ERB file among stack:\n#{caller.join("\n")}" if file_found.nil?
      Regexp.last_match[1]
    end

  end

end
