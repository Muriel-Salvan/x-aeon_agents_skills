RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'skill_goal_sentence' do

    it 'returns the skill goal with the first character lowercased' do
      expect(
        process_erb('<% skill_goal("Running the tests") %><%= skill_goal_sentence %>')
      ).to eq 'running the tests'
    end

  end

end
