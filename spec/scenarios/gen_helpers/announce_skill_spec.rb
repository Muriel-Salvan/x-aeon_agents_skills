RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'announce_skill' do

    it 'returns the announcement instruction with the skill description' do
      expect(process_erb('<% skill_goal("Committing changes") %><%= announce_skill %>')).to eq 'Always tell the user "SKILL: I am committing changes" to inform the user that you are running this skill.'
    end

  end

end
