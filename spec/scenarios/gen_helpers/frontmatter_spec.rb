RSpec.describe XAeonAgentsSkills::GenHelpers do

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

end
