describe XAeonAgentsSkills::GenHelpers do

  describe 'ordered_todo_list' do

    it 'generates a full ordered list with checklist tracking instructions' do
      expect(
        process_erb(
          <<~EO_ERB
            <% goal('Numbered Skill') -%>
            <% ordered_todo_list do -%>
              ### First Action
              - Do the first action
              ### Second Action
              - Do the second action
              ### Third Action
              - Do the third action
            <% end -%>
          EO_ERB
        )
      ).to eq <<~EXPECTED
        ## Sequential steps to be followed when using this skill

        When numbered Skill, follow those steps.

        ### Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with all steps of this skill.
        - The test_skill Execution Checklist must include all numbered steps explicitly.
        - The test_skill Execution Checklist must be displayed to the user.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the user.
        - Do not skip any item.
        - If an item cannot be executed, explicitly explain why.
        - Never mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ### 1. Inform the user

        - Always tell the user "SKILL: I am numbered Skill" to inform the user that you are running this skill.

        ### 2. First Action
        - Do the first action

        ### 3. Second Action
        - Do the second action

        ### 4. Third Action
        - Do the third action

        ### Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the test_skill Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EXPECTED
    end

    it 'handles an empty todo list' do
      expect(
        process_erb(
          <<~EO_ERB
            <% goal('Empty Skill') -%>
            <% ordered_todo_list do -%>
            <% end -%>
          EO_ERB
        )
      ).to eq <<~EXPECTED
        ## Sequential steps to be followed when using this skill

        When empty Skill, follow those steps.

        ### Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with all steps of this skill.
        - The test_skill Execution Checklist must include all numbered steps explicitly.
        - The test_skill Execution Checklist must be displayed to the user.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the user.
        - Do not skip any item.
        - If an item cannot be executed, explicitly explain why.
        - Never mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ### 1. Inform the user

        - Always tell the user "SKILL: I am empty Skill" to inform the user that you are running this skill.



        ### Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the test_skill Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EXPECTED
    end

  end

end
