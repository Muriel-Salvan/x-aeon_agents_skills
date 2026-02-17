require 'front_matter_parser'
require 'thor'
require 'x-aeon_agents_skills/installer'
require 'x-aeon_agents_skills/skills_dsl'

module XAeonAgentsSkills

  class SkillsCli < Thor

    desc 'install', 'Install skills as defined in the Skillfile file'
    def install
      skills_file = File.expand_path('./Skillfile')
      dsl = SkillsDsl.new
      dsl.instance_eval(File.read(skills_file), skills_file)
      dsl.skills.each do |skill|
        Installer.install_skill(skill)
      end
    end

  end

end
