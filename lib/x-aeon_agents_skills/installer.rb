module XAeonAgentsSkills

  module Installer

    # Install a skill and its dependencies if they are not installed yet
    #
    # Parameters::
    # * *skill* (String): The skill reference to be installed
    def self.install_skill(skill)
      puts "Install skill #{skill}..."
      system "npx openskills install --yes #{skill}", exception: true
      # Look for its dependencies if any that are not yet installed
      skill_path, skill_name = skill.match(/^(.+)\/([^\/]+)$/)[1..2]
      deps = FrontMatterParser::Parser.parse_file(".claude/skills/#{skill_name}/SKILL.md").front_matter.dig('metadata', 'dependencies')
      unless deps.nil?
        deps.split(',').map(&:strip).each do |skill_dep|
          unless File.exist?(".claude/skills/#{skill_dep}/SKILL.md")
            skill_dep = "#{skill_path}/#{skill_dep}" unless skill_dep.include?('/')
            install_skill(skill_dep)
          end
        end
      end
    end

  end

end
