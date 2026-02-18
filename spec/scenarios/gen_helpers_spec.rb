require 'x-aeon_agents_skills/gen_helpers'

RSpec.describe 'GenHelpers in generate_skills executable' do

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

  describe 'define_ordered_todo_list' do

    it 'generates a full ordered list with checklist tracking instructions' do
      expect(
        process_erb(
          <<~EO_ERB
            <% skill_goal('Numbered Skill') -%>
            <% define_ordered_todo_list do -%>
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

        - Before executing anything, create a checklist named test_skill Execution Checklist with ALL steps of this skill.
        - The test_skill Execution Checklist MUST include ALL numbered steps explicitly.
        - The test_skill Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ### 1. Inform the USER

        - ALWAYS tell the USER "SKILL: I am numbered Skill" to inform the USER that you are running this skill.

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
            <% skill_goal('Empty Skill') -%>
            <% define_ordered_todo_list do -%>
            <% end -%>
          EO_ERB
        )
      ).to eq <<~EXPECTED
        ## Sequential steps to be followed when using this skill

        When empty Skill, follow those steps.

        ### Create the test_skill Execution Checklist (MANDATORY)

        - Before executing anything, create a checklist named test_skill Execution Checklist with ALL steps of this skill.
        - The test_skill Execution Checklist MUST include ALL numbered steps explicitly.
        - The test_skill Execution Checklist MUST be displayed to the USER.
        - After completing each step of this skill, mark the item in the test_skill Execution Checklist as completed, and display again the test_skill Execution Checklist to the USER.
        - Do NOT skip any item.
        - If an item cannot be executed, explicitly explain why.
        - NEVER mark the skill as completed while any item from the test_skill Execution Checklist remains open.

        ### 1. Inform the USER

        - ALWAYS tell the USER "SKILL: I am empty Skill" to inform the USER that you are running this skill.



        ### Final Verification (MANDATORY)

        Before declaring the task complete:

        - Re-list all numbered steps from the test_skill Execution Checklist.
        - Confirm each one was executed.
        - If any step was not executed, execute it now.
      EXPECTED
    end

  end

  describe 'skill_name' do

    it 'returns the skill name being generated from the ERB file path' do
      expect(process_erb('<%= skill_name %>')).to eq 'test_skill'
    end

  end

  describe 'tmp_path' do

    it 'returns the default temporary folder path for agents' do
      expect(process_erb('<%= tmp_path %>')).to eq './.tmp_agents'
    end

  end

  describe 'frontmatter' do

    it 'generates YAML frontmatter without metadata' do
      expect(
        process_erb('<%= frontmatter(description: "A test skill") %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill
        ---
      EXPECTED
    end

    it 'generates YAML frontmatter with metadata' do
      expect(
        process_erb('<%= frontmatter(description: "A test skill", metadata: { tool: "rspec", version: "3" }) %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill
        metadata:
          tool: rspec
          version: '3'
        ---
      EXPECTED
    end

  end

  describe 'skill_goal' do

    it 'sets and returns the goal when a goal_desc argument is given' do
      expect(
        process_erb('<%= skill_goal("Implementing a feature") %>')
      ).to eq 'Implementing a feature'
    end

    it 'retrieves the previously set goal when called without argument' do
      expect(
        process_erb('<% skill_goal("Fixing a bug") %><%= skill_goal %>')
      ).to eq 'Fixing a bug'
    end

  end

  describe 'skill_goal_sentence' do

    it 'returns the skill goal with the first character lowercased' do
      expect(
        process_erb('<% skill_goal("Running the tests") %><%= skill_goal_sentence %>')
      ).to eq 'running the tests'
    end

  end

  describe 'announce_skill' do

    it 'returns the announcement instruction with the skill description' do
      expect(process_erb('<% skill_goal("Committing changes") %><%= announce_skill %>')).to eq 'ALWAYS tell the USER "SKILL: I am committing changes" to inform the USER that you are running this skill.'
    end

  end

  describe 'skill_config' do

    it 'returns an empty Hash when no config file exists for the skill' do
      with_skills_src(test_skill: { 'SKILL.md.erb' => '' }) do |workspace_dir|
        Dir.chdir(workspace_dir) do
          expect(XAeonAgentsSkills::GenHelpers.skill_config('test_skill')).to eq({})
        end
      end
    end

    it 'returns the parsed YAML Hash when a config file exists' do
      with_skills_src(test_skill: { '.skill_config.yml' => "---\nskip_quality_checks: 'Structure, Specificity'\n" }) do |workspace_dir|
        Dir.chdir(workspace_dir) do
          expect(XAeonAgentsSkills::GenHelpers.skill_config('test_skill')).to eq({ 'skip_quality_checks' => 'Structure, Specificity' })
        end
      end
    end

  end

end
