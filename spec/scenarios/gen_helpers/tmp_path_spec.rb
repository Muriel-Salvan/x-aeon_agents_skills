describe XAeonAgentsSkills::GenHelpers do

  describe 'tmp_path' do

    it 'returns the default temporary folder path for agents' do
      expect(process_erb('<%= tmp_path %>')).to eq './.tmp_agents'
    end

  end

end
