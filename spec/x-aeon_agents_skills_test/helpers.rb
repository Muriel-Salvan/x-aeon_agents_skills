require 'sqlite3'
require 'json'
require 'fileutils'
require 'tmpdir'

module XAeonAgentsSkillsTest

  module Helpers

    # Create a temporary workspace directory
    # Sets @workspace_dir to the created directory path
    #
    # Parameters::
    # * *&block* (Proc): Code block to execute with the workspace directory
    def with_workspace
      Dir.mktmpdir('test_skills_workspace') do |workspace_dir|
        @workspace_dir = workspace_dir
        yield @workspace_dir
      end
    end

    # Create a temporary workspace with skills.src directory
    # The skills are defined as a hash: skill_name => { file_path => content }
    # Example: my_skill: { 'SKILL.md' => 'content', 'scripts/test' => 'ls' }
    #
    # Parameters::
    # * *skills* (Hash): Hash of skill names to their file contents
    # * *&block* (Proc): Code block to execute with the workspace directory
    def with_skills_src(**skills)
      with_workspace do |workspace_dir|
        skills_src_dir = File.join(workspace_dir, 'skills.src')
        skills.each do |skill_name, files|
          skill_dir = File.join(skills_src_dir, skill_name.to_s)
          files.each do |file_path, content|
            full_file_path = File.join(skill_dir, file_path)
            FileUtils.mkdir_p(File.dirname(full_file_path))
            File.write(full_file_path, content)
          end
        end
        yield workspace_dir
      end
    end

    # Create a temporary workspace with a Skillfile file
    # The Skillfile content is provided as a string
    #
    # Parameters::
    # * *skills_spec_content* (String): Content of the Skillfile file
    # * *&block* (Proc): Code block to execute with the workspace directory
    def with_skills_spec(skills_spec_content)
      with_workspace do |workspace_dir|
        skills_spec_path = File.join(workspace_dir, 'Skillfile')
        File.write(skills_spec_path, skills_spec_content)
        yield workspace_dir
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

    # Mock Kernel.system using RSpec mocks and execute a code block
    # Sets @load_calls with the system calls made during block execution
    #
    # Parameters::
    # * *skills* (Array<String or Hash>): List of skills that are available to openskills.
    #   Each element describes a skill as a Hash.
    #   A String can be used as a shortcut, representing the skill's ref.
    #   Here are all the properties the skill description can have:
    #   * *ref* (String): The skill's reference, as understood by OpenSkills. This is the default value when used as a String.
    #   * *name* (String): The skill's name [default: the last part of the ref]
    #   * *description* (String): The skill's description [default: 'Runs my test skill']
    #   * All other properties are given directly to the Skill's YAML frontmatter's metadata property.
    # * *&block* (Proc): Code block to execute with the mocking in place
    #
    # Sets::
    # * @load_calls (Array): Array of system calls that were made, for assertions
    def with_installable_skills(*skills)
      @installed_skills = []

      # Normalize skills to a hash: ref => skill_properties
      skills_hash = skills.to_h do |skill_desc|
        skill_desc = { ref: skill_desc } if skill_desc.is_a?(String)
        # Set default values
        skill_desc = {
          name: skill_desc[:ref].split('/').last,
          description: 'Runs my test skill'
        }.merge(skill_desc)
        ref = skill_desc.delete(:ref)
        [ref, skill_desc]
      end

      # Mock system calls from the Installer
      require 'x-aeon_agents_skills/installer'
      allow(XAeonAgentsSkills::Installer).to receive(:system).and_wrap_original do |original_method, *args, **kwargs|
        # Only mock the calls to OpenSkills
        if args.size == 1 && args.first =~ /^npx openskills install --yes (.+)$/
          skill_ref = Regexp.last_match[1]
          raise "Skill '#{skill_ref}' is not in the installable skills list. Available skills: #{skills_hash.keys.join(', ')}" unless skills_hash.key?(skill_ref)

          # Generate a SKILL.md file as if it was called for real
          skill_props = skills_hash[skill_ref]
          skill_name = skill_props.delete(:name)
          skill_description = skill_props.delete(:description)
          frontmatter = {
            'name' => skill_name,
            'description' => skill_description
          }
          frontmatter['metadata'] = skill_props unless skill_props.empty?
          skill_dir = File.join(@workspace_dir, '.claude', 'skills', skill_name)
          FileUtils.mkdir_p(skill_dir)
          File.write(File.join(skill_dir, 'SKILL.md'), "#{frontmatter.to_yaml}---\n\n# #{skill_name}\n\n#{skill_description}\n")
          @installed_skills << skill_ref
          true
        else
          # Call the original method
          original_method.call(*args, **kwargs)
        end
      end

      yield
    end

    # Run the skills install executable from the workspace directory
    # Assumes @workspace_dir is set by with_skills_spec
    #
    # Returns::
    # * String: The output from the skills install command
    # Sets::
    # * @load_calls (Array): Array of system calls that were made, for assertions
    def run_skills_install
      full_script_path = File.expand_path('./bin/skills')
      Dir.chdir(@workspace_dir) do
        original_argv = ARGV
        ARGV.replace ['install']
        begin
          load full_script_path
        ensure
          ARGV.replace original_argv
        end
      end
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
