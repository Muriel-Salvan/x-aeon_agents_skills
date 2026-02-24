RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'name' do

    it 'returns the skill name being generated from the ERB file path' do
      expect(process_erb('<%= name %>')).to eq 'test_skill'
    end

  end

end
