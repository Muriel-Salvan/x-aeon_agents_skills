require 'sqlite3'
require 'json'
require 'fileutils'
require 'tmpdir'

module XAeonAgentsSkillsTest

  module Helpers

    # Create a temporary workspace with skills.src directory
    # The skills are defined as a hash: skill_name => { file_path => content }
    # Example: my_skill: { 'SKILL.md' => 'content', 'scripts/test' => 'ls' }
    #
    # Parameters::
    # * *skills* (Hash): Hash of skill names to their file contents
    # * *&block* (Proc): Code block to execute with the workspace directory
    def with_skills_src(**skills)
      # Create a temporary workspace directory
      Dir.mktmpdir('test_skills_workspace') do |workspace_dir|
        @workspace_dir = workspace_dir
        skills_src_dir = File.join(@workspace_dir, 'skills.src')
        skills.each do |skill_name, files|
          skill_dir = File.join(skills_src_dir, skill_name.to_s)
          files.each do |file_path, content|
            full_file_path = File.join(skill_dir, file_path)
            FileUtils.mkdir_p(File.dirname(full_file_path))
            File.write(full_file_path, content)
          end
        end
        yield @workspace_dir
      end
    end

    # Run the generate_skills executable from the workspace directory
    # Assumes @workspace_dir is set by with_skills_src
    #
    # Returns::
    # * String: The output from the generate_skills command
    def run_generate_skills
      full_script_path = File.expand_path('./bin/generate_skills')
      output = nil
      Dir.chdir(@workspace_dir) do
        output = `ruby "#{full_script_path}" 2>&1`
        raise "Command failed: #{output}" unless $?.success?
      end
      output
    end

    # Helper method to temporarily set an environment variable
    # Uses begin...ensure to guarantee the original value is restored
    #
    # Parameters::
    # * *var_name* (String): Name of the environment variable
    # * *value* (String): Temporary value to set
    # * *&block* (Proc): Code block to execute with the temporary value
    def with_env_var(var_name, value)
      original_value = ENV[var_name]
      ENV[var_name] = value
      begin
        yield
      ensure
        ENV[var_name] = original_value
      end
    end

    # Helper method to setup a VSCode SQLite database with test data
    # Creates the database file, table structure, and inserts items
    #
    # Parameters::
    # * *vscode_portable_dir* (String): Base directory for the VSCode portable setup
    # * *items* (Array<Hash>): Array of items to insert into the ItemTable.
    #   Each item should be a hash with :key and :value keys.
    #   Can be empty to test "key not found" scenarios.
    # * *&block* (Proc): Code block to execute with the database setup
    def with_vscode_db(vscode_portable_dir, items)
      # Create the required directory structure
      db_dir = File.join(vscode_portable_dir, 'user-data', 'User', 'globalStorage')
      FileUtils.mkdir_p(db_dir)

      # Create the SQLite database
      db_path = File.join(db_dir, 'state.vscdb')
      db = SQLite3::Database.new(db_path)
      db.execute('CREATE TABLE ItemTable (key TEXT PRIMARY KEY, value TEXT)')

      # Insert items into the database
      items.each do |item|
        db.execute(
          'INSERT INTO ItemTable (key, value) VALUES (?, ?)',
          [item[:key], item[:value].to_json]
        )
      end

      db.close

      yield
    end

  end

end
