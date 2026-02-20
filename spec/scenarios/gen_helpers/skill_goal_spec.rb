RSpec.describe XAeonAgentsSkills::GenHelpers do

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

end
