RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'skill_name' do

    it 'returns the skill name being generated from the ERB file path' do
      expect(process_erb('<%= skill_name %>')).to eq 'test_skill'
    end

  end

end
