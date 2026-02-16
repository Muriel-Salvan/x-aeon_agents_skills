require_relative 'lib/x-aeon_agents_skills/version'

Gem::Specification.new do |spec|
  spec.name          = 'x-aeon_agents_skills'
  spec.version       = XAeonAgentsSkills::VERSION
  spec.summary       = 'AI agents skills to be used for X-Aeon projects'
  spec.homepage      = 'https://github.com/Muriel-Salvan/x-aeon_agents_skills'
  spec.license       = 'BSD-3-Clause'

  spec.author        = 'Muriel Salvan'
  spec.email         = 'muriel@x-aeon.com'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_path  = 'lib'

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'front_matter_parser', '~> 1.0'
  spec.add_dependency 'json', '~> 2.18'
  spec.add_dependency 'sqlite3', '~> 2.9'
  spec.add_dependency 'thor', '~> 1.5'
end
