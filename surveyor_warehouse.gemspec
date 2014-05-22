Gem::Specification.new do |s|
  s.name        = 'surveyor_warehouse'
  s.version     = '0.1.0'
  s.summary     = "Transform surveyor responses into an alternate structure"
  s.description = "Transform surveyor responses into an alternate structure"
  s.authors     = ["John Dzak"]
  s.email       = 'j-dzak@northwestern.edu'
  s.files       = Dir.glob("{README.md,{assets,lib,spec}/**/*}")
  s.homepage    = 'http://rubygems.org/gems/surveyor_warehouse'
  s.license     = 'MIT'

  s.add_runtime_dependency 'surveyor'
  s.add_runtime_dependency 'haml'
  s.add_runtime_dependency 'rails'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'actionpack'
  s.add_runtime_dependency 'activerecord'

  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'pg'
end