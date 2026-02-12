module XAeonAgentsSkills

  # Helper methods for generating skill content
  module GenHelpers

    # Return the execution checklist initialization section
    #
    # Result::
    # * String: The execution checklist section
    def self.init_skill_checklist
      <<~EO_Markdown
        ## Create Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist with ALL steps of this skill.
        - The checklist MUST include ALL numbered steps explicitly.
        - The checklist MUST be displayed to the USER at the beginning of the skill execution, and at the end of each step.
        - Mark each item as completed only after execution and successful completion of the item itself.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the Execution Checklist remains open.
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

        - Re-list all numbered steps from the Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EO_Markdown
    end

  end

end
