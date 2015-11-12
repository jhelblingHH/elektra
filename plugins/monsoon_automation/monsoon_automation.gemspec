$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "monsoon_automation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "monsoon_automation"
  s.version     = MonsoonAutomation::VERSION
  s.authors     = ["Arturo Reuschenbach Puncernau"]
  s.email       = ["a.reuschenbach.puncernau@sap.com"]
  s.homepage    = "https://localhost/pages/monsoon/arc/"
  s.summary     = "Arc monsoon_automation service"
  s.description = "Arc monsoon_automation service"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  # s.add_dependency 'ruby-arc-client', '~> 0.1.1'

end
