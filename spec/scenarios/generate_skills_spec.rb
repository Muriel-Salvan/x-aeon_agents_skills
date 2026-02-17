RSpec.describe 'generate_skills executable' do

  describe 'basic functionality' do

    context 'with empty skills.src directory' do
      it 'creates an empty skills directory' do
        with_skills_src do |workspace_dir|
          run_generate_skills
          expect(File.directory?("#{workspace_dir}/skills")).to be true
          expect(Dir.empty?("#{workspace_dir}/skills")).to be true
        end
      end
    end

    context 'with simple file copying' do
      it 'copies normal files as-is' do
        with_skills_src(my_skill: { 'SKILL.md' => '# My Skill', 'README.txt' => 'Readme content' }) do |workspace_dir|
          run_generate_skills
          expect(File.directory?("#{workspace_dir}/skills/my_skill")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/SKILL.md")).to eq('# My Skill')
          expect(File.read("#{workspace_dir}/skills/my_skill/README.txt")).to eq('Readme content')
        end
      end
    end

    context 'with ERB template processing' do
      it 'processes .erb files and removes the extension' do
        with_skills_src(my_skill: { 'SKILL.md.erb' => '<%= 1 + 1 %>' }) do |workspace_dir|
          run_generate_skills
          expect(File.exist?("#{workspace_dir}/skills/my_skill/SKILL.md")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/SKILL.md")).to eq('2')
        end
      end
    end

    context 'with recursive file copying' do
      it 'copies files in subdirectories preserving structure' do
        with_skills_src(my_skill: {
          'SKILL.md' => '# Skill',
          'scripts/script1.sh' => 'echo hello',
          'scripts/nested/script2.sh' => 'echo nested'
        }) do |workspace_dir|
          run_generate_skills
          expect(File.exist?("#{workspace_dir}/skills/my_skill/SKILL.md")).to be true
          expect(File.exist?("#{workspace_dir}/skills/my_skill/scripts/script1.sh")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/scripts/script1.sh")).to eq('echo hello')
          expect(File.exist?("#{workspace_dir}/skills/my_skill/scripts/nested/script2.sh")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/scripts/nested/script2.sh")).to eq('echo nested')
        end
      end
    end

    context 'with several skills' do
      it 'processes multiple skills with multiple files each' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One', 'README.txt' => 'Readme 1' },
          skill_two: { 'SKILL.md' => '# Skill Two', 'config.yml' => 'key: value' },
          skill_three: { 'SKILL.md' => '# Skill Three' }
        ) do |workspace_dir|
          run_generate_skills
          expect(File.exist?("#{workspace_dir}/skills/skill_one/SKILL.md")).to be true
          expect(File.exist?("#{workspace_dir}/skills/skill_one/README.txt")).to be true
          expect(File.exist?("#{workspace_dir}/skills/skill_two/SKILL.md")).to be true
          expect(File.exist?("#{workspace_dir}/skills/skill_two/config.yml")).to be true
          expect(File.exist?("#{workspace_dir}/skills/skill_three/SKILL.md")).to be true
        end
      end
    end

    context 'with error handling' do
      it 'handles invalid ERB syntax gracefully and continues processing other files' do
        with_skills_src(
          good_skill: { 'SKILL.md' => '# Good Skill', 'good.txt' => 'good content' },
          bad_skill: { 'error.erb' => '<%= undefined_method %>' }
        ) do |workspace_dir|
          output = run_generate_skills
          expect(File.exist?("#{workspace_dir}/skills/good_skill/SKILL.md")).to be true
          expect(File.exist?("#{workspace_dir}/skills/good_skill/good.txt")).to be true
          expect(File.read("#{workspace_dir}/skills/good_skill/good.txt")).to eq('good content')
          expect(File.exist?("#{workspace_dir}/skills/bad_skill/error")).to be false
          expect(output).to include('Error - undefined local variable or method \'undefined_method\'')
        end
      end
    end

    context 'with mixed ERB and non-ERB files' do
      it 'processes ERB files and copies non-ERB files correctly' do
        with_skills_src(my_skill: {
          'SKILL.md.erb' => '# Title: <%= "Test" %>',
          'config.yml' => 'setting: value',
          'script.rb.erb' => 'puts "<%= 1 + 2 %>"'
        }) do |workspace_dir|
          run_generate_skills
          expect(File.read("#{workspace_dir}/skills/my_skill/SKILL.md")).to eq('# Title: Test')
          expect(File.read("#{workspace_dir}/skills/my_skill/script.rb")).to eq('puts "3"')
          expect(File.read("#{workspace_dir}/skills/my_skill/config.yml")).to eq('setting: value')
        end
      end
    end

    context 'with empty files' do
      it 'creates empty output files' do
        with_skills_src(my_skill: { 'empty.txt' => '', 'also_empty.erb' => '' }) do |workspace_dir|
          run_generate_skills
          expect(File.exist?("#{workspace_dir}/skills/my_skill/empty.txt")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/empty.txt")).to eq('')
          expect(File.exist?("#{workspace_dir}/skills/my_skill/also_empty")).to be true
          expect(File.read("#{workspace_dir}/skills/my_skill/also_empty")).to eq('')
        end
      end
    end

  end

end
