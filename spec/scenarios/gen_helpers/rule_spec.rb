RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'rule' do

    it 'generates a rule with just a title' do
      expect(
        process_erb('<%= rule("Use descriptive variable names") %>')
      ).to eq '### Rule: Use descriptive variable names'
    end

    it 'generates a rule with a description' do
      expect(
        process_erb('<%= rule("Use descriptive variable names", description: "Variables should clearly indicate their purpose") %>')
      ).to eq <<~EXPECTED.chomp
        ### Rule: Use descriptive variable names

        Variables should clearly indicate their purpose
      EXPECTED
    end

    it 'generates a rule with bad and good examples' do
      expect(
        process_erb(
          <<~EO_ERB
            <%= rule("Use descriptive variable names",
              bad: "x = 5",
              good: "item_count = 5") %>
          EO_ERB
        ).chomp
      ).to eq <<~EXPECTED.chomp
        ### Rule: Use descriptive variable names

        #### Example: Incorrect

        ```ruby
        x = 5
        ```

        #### Example: Correct

        ```ruby
        item_count = 5
        ```
      EXPECTED
    end

    it 'generates a rule with rationale' do
      expect(
        process_erb(
          <<~EO_ERB
            <%= rule("Use descriptive variable names",
              rationale: "Clear variable names make code easier to understand and maintain.") %>
          EO_ERB
        ).chomp
      ).to eq <<~EXPECTED.chomp
        ### Rule: Use descriptive variable names

        #### Rationale

        Clear variable names make code easier to understand and maintain.
      EXPECTED
    end

    it 'generates a complete rule with all options' do
      expect(
        process_erb(
          <<~EO_ERB
            <%= rule("Use descriptive variable names",
              description: "Variables should clearly indicate their purpose",
              type: :ruby,
              bad: "x = 5",
              good: "item_count = 5",
              rationale: "Clear variable names make code easier to understand and maintain.") %>
          EO_ERB
        ).chomp
      ).to eq <<~EXPECTED.chomp
        ### Rule: Use descriptive variable names

        Variables should clearly indicate their purpose

        #### Example: Incorrect

        ```ruby
        x = 5
        ```

        #### Example: Correct

        ```ruby
        item_count = 5
        ```

        #### Rationale

        Clear variable names make code easier to understand and maintain.
      EXPECTED
    end

    it 'generates a rule with a different code type' do
      expect(
        process_erb(
          <<~EO_ERB
            <%= rule("Use set -e in bash scripts",
              type: :bash,
              bad: "#!/bin/bash\nrm file",
              good: "#!/bin/bash\nset -e\nrm file") %>
          EO_ERB
        ).chomp
      ).to eq <<~EXPECTED.chomp
        ### Rule: Use set -e in bash scripts

        #### Example: Incorrect

        ```bash
        #!/bin/bash
        rm file
        ```

        #### Example: Correct

        ```bash
        #!/bin/bash
        set -e
        rm file
        ```
      EXPECTED
    end

  end

end
