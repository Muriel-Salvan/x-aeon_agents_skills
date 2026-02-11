# frozen_string_literal: true

require 'sqlite3'
require 'json'
require 'fileutils'

module XAeonAgentsSkillsTest

  module Helpers

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
