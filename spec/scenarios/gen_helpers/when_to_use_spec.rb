describe XAeonAgentsSkills::GenHelpers do

  describe '#when_to_use' do

    context 'when plan mode is enabled' do
      it 'includes plan mode instruction and custom content' do
        expect(
          process_erb(
            <<~EO_ERB
              <% skill(description: 'Test Skill', plan: true) -%>
              <% when_to_use do -%>
                - Custom usage instruction for plan mode.
              <% end -%>
            EO_ERB
          )
        ).to eq <<~EXPECTED
          ## When to use it

          - This skill can be used when in Plan mode.
          - Always use it every time another skill specifically mentions `skill: test_skill`.
          - Custom usage instruction for plan mode.
        EXPECTED
      end
    end

    context 'when plan mode is disabled' do
      it 'includes only non-plan mode instructions and custom content' do
        expect(
          process_erb(
            <<~EO_ERB
              <% skill(description: 'Test Skill', plan: false) -%>
              <% when_to_use do -%>
                - Custom usage instruction for non-plan mode.
              <% end -%>
            EO_ERB
          )
        ).to eq <<~EXPECTED
          ## When to use it

          - Always use it every time another skill specifically mentions `skill: test_skill`.
          - Custom usage instruction for non-plan mode.
        EXPECTED
      end
    end

    context 'when no custom content is provided' do
      it 'includes only default instructions' do
        expect(
          process_erb(
            <<~EO_ERB
              <% skill(description: 'Test Skill', plan: false) -%>
              <% when_to_use do -%>
              <% end -%>
            EO_ERB
          )
        ).to eq <<~EXPECTED
          ## When to use it

          - Always use it every time another skill specifically mentions `skill: test_skill`.
        EXPECTED
      end
    end

    context 'when plan mode is enabled and no custom content is provided' do
      it 'includes plan mode instruction and default instructions' do
        expect(
          process_erb(
            <<~EO_ERB
              <% skill(description: 'Test Skill', plan: true) -%>
              <% when_to_use do -%>
              <% end -%>
            EO_ERB
          )
        ).to eq <<~EXPECTED
          ## When to use it

          - This skill can be used when in Plan mode.
          - Always use it every time another skill specifically mentions `skill: test_skill`.
        EXPECTED
      end
    end
  end
end
