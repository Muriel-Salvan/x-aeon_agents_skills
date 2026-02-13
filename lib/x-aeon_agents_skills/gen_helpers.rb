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

    # Return the skill being generated
    #
    # Result::
    # * String: Skill name being generated
    def self.generating_skill
      skill_found = caller.find { |stack_trace| stack_trace =~ /\/skills\.src\/([^\/]+)\/.+\.erb/ }
      raise "Unable to find generated skill among stack:\n#{caller.join("\n")}" if skill_found.nil?
      Regexp.last_match[1]
    end

  end

end
