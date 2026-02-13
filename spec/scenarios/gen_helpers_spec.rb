require 'spec_helper'
require 'x-aeon_agents_skills_test/helpers'

RSpec.describe 'GenHelpers in generate_skills executable' do

  include XAeonAgentsSkillsTest::Helpers

  # Helper method that creates a skill with ERB content, runs generate_skills,
  # and returns the generated SKILL.md output
  #
  # Parameters::
  # * *erb_content* (String): The ERB content for SKILL.md.erb
  # * *additional_files* (Hash): Optional additional files to include in the skill
  #
  # Returns::
  # * String: The content of the generated SKILL.md file
  def process_erb(erb_content, additional_files = {})
    files = { 'SKILL.md.erb' => erb_content }.merge(additional_files)
    with_skills_src(test_skill: files) do |workspace_dir|
      run_generate_skills
      File.read("#{workspace_dir}/skills/test_skill/SKILL.md")
    end
  end

  describe 'init_skill_checklist' do

    it 'generates the execution checklist initialization section' do
      expect(process_erb('<%= XAeonAgentsSkills::GenHelpers.init_skill_checklist %>')).to eq <<~EXPECTED
        ## Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with ALL steps of this skill.
        - The test_skill Execution Checklist MUST include ALL numbered steps explicitly.
        - The test_skill Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the test_skill Execution Checklist remains open.
      EXPECTED
    end

  end

  describe 'validate_skill_checklist' do

    it 'generates the final verification section' do
      expect(process_erb('<%= XAeonAgentsSkills::GenHelpers.validate_skill_checklist %>')).to eq <<~EXPECTED
        ## Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the test_skill Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EXPECTED
    end

  end

  describe 'define_ordered_todo_list' do

    it 'generates a full ordered list with checklist tracking instructions' do
      expect(
        process_erb(
          <<~EO_ERB
            <% XAeonAgentsSkills::GenHelpers.define_ordered_todo_list('Numbered Skill') do -%>
            ## First Action
            - Do the first action
            ## Second Action
            - Do the second action
            ## Third Action
            - Do the third action
            <% end -%>
          EO_ERB
        )
      ).to eq <<~EXPECTED
        # Numbered Skill

        When numbered Skill, follow those steps.

        ## Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with ALL steps of this skill.
        - The test_skill Execution Checklist MUST include ALL numbered steps explicitly.
        - The test_skill Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ## 1. Inform the USER

        - ALWAYS inform the user that you are running this skill, saying "SKILL: I am numbered Skill".

        ## 2. First Action
        - Do the first action

        ## 3. Second Action
        - Do the second action

        ## 4. Third Action
        - Do the third action

        ## Final Verification (MANDATORY)

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
            <% XAeonAgentsSkills::GenHelpers.define_ordered_todo_list('Empty Skill') do -%>
            <% end -%>
          EO_ERB
        )
      ).to eq <<~EXPECTED
        # Empty Skill

        When empty Skill, follow those steps.

        ## Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with ALL steps of this skill.
        - The test_skill Execution Checklist MUST include ALL numbered steps explicitly.
        - The test_skill Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ## 1. Inform the USER

        - ALWAYS inform the user that you are running this skill, saying "SKILL: I am empty Skill".



        ## Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the test_skill Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EXPECTED
    end

  end

end
