Gem::Specification.new do |s|
  s.name        = "emery"
  s.summary     = "Type safety library"
  s.version     = "0.0.1"
  s.files       = Dir.glob("{lib,test}/**/*")
  s.authors     = ["Vladimir Sapronov"]
  s.license     = "MIT"
  s.homepage    = "https://github.com/vsapronov/emery"
  s.add_runtime_dependency 'json'
end