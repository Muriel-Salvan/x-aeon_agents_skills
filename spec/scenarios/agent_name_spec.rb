require 'tmpdir'

describe XAeonAgentsSkills do

  describe '.agent_name' do

    it 'returns the agent name from the VSCode globalStorage database' do
      # Create a temporary directory for the test database
      Dir.mktmpdir do |temp_dir|
        # Set up the expected model ID
        model_id = 'test-provider/test-model'

        # Use helper to setup the database and execute the test
        with_vscode_db(
          temp_dir,
          [{ key: 'saoudrizwan.claude-dev', value: { 'actModeOpenRouterModelId' => model_id } }]
        ) do
          with_env_var('VSCODE_PORTABLE', temp_dir) do
            expect(described_class.agent_name).to eq("Cline (#{model_id})")
          end
        end
      end
    end

    it 'raises an error when the database file does not exist' do
      Dir.mktmpdir do |temp_dir|
        # Do not create the database file
        with_env_var('VSCODE_PORTABLE', temp_dir) do
          expect { described_class.agent_name }.to raise_error(/Cannot find/)
        end
      end
    end

    it 'raises an error when the key is not found in the database' do
      Dir.mktmpdir do |temp_dir|
        # Use helper with empty items array to create database without the required key
        with_vscode_db(temp_dir, []) do
          with_env_var('VSCODE_PORTABLE', temp_dir) do
            expect { described_class.agent_name }.to raise_error(/Key 'saoudrizwan.claude-dev' not found/)
          end
        end
      end
    end

  end

end
