Gem::Specification.new do |s|
  s.name        = "emery"
  s.summary     = "Type safety library"
  s.version     = ENV["VERSION"]
  s.files       = Dir.glob("{lib,test}/**/*")
  s.authors     = ["Vladimir Sapronov"]
  s.license     = "MIT"
  s.homepage    = "https://github.com/vsapronov/emery"
  s.authors     = ["Vladimir Sapronov"]
  s.add_runtime_dependency 'json'
end