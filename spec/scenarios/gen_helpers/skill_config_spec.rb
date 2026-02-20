require 'x-aeon_agents_skills/gen_helpers'

RSpec.describe XAeonAgentsSkills::GenHelpers do

  describe 'skill_config' do

    it 'returns an empty Hash when no config file exists for the skill' do
      with_skills_src(test_skill: { 'SKILL.md.erb' => '' }) do |workspace_dir|
        Dir.chdir(workspace_dir) do
          expect(XAeonAgentsSkills::GenHelpers.skill_config('test_skill')).to eq({})
        end
      end
    end

    it 'returns the parsed YAML Hash when a config file exists' do
      with_skills_src(test_skill: { '.skill_config.yml' => "---\nskip_quality_checks: 'Structure, Specificity'\n" }) do |workspace_dir|
        Dir.chdir(workspace_dir) do
          expect(XAeonAgentsSkills::GenHelpers.skill_config('test_skill')).to eq({ 'skip_quality_checks' => 'Structure, Specificity' })
        end
      end
    end

  end

end
