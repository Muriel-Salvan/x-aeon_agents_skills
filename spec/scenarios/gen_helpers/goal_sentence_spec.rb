RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'goal_sentence' do

    it 'returns the skill goal with the first character lowercased' do
      expect(
        process_erb('<% goal("Running the tests") %><%= goal_sentence %>')
      ).to eq 'running the tests'
    end

  end

end
