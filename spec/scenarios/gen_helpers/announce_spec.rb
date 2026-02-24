describe XAeonAgentsSkills::GenHelpers do

  describe 'announce' do

    it 'returns the announcement instruction with the skill description' do
      expect(process_erb('<% goal("Committing changes") %><%= announce %>')).to eq 'Always tell the user "SKILL: I am committing changes" to inform the user that you are running this skill.'
    end

  end

end
