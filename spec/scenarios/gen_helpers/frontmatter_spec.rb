describe XAeonAgentsSkills::GenHelpers do

  describe 'skill' do

    it 'generates YAML skill without metadata' do
      expect(
        process_erb('<%= skill(description: "A test skill") %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill
        ---
      EXPECTED
    end

    it 'generates YAML skill with metadata' do
      expect(
        process_erb('<%= skill(description: "A test skill", metadata: { tool: "rspec", version: "3" }) %>')
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

    it 'generates YAML skill with dependencies as array' do
      expect(
        process_erb('<%= skill(description: "A test skill", metadata: { dependencies: %w[dep1 dep2 dep3] }) %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill
        metadata:
          dependencies:
          - dep1
          - dep2
          - dep3
        ---
      EXPECTED
    end

    it 'generates YAML skill with plan argument set to true' do
      expect(
        process_erb('<%= skill(description: "A test skill.", plan: true) %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill. Use this skill also in Plan mode.
        metadata:
          agent: Plan
        ---
      EXPECTED
    end

    it 'generates YAML skill with dependencies not empty' do
      expect(
        process_erb('<%= skill(description: "A test skill", dependencies: %w[dep1 dep2]) %>')
      ).to eq <<~EXPECTED.chomp
        ---
        name: test_skill
        description: A test skill
        metadata:
          dependencies:
          - dep1
          - dep2
        ---
      EXPECTED
    end

  end

end
