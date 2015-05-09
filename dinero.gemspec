# $:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
# require "dinero/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dinero"
  s.version     = "0.0.1"
  s.authors     = ["Michael Lang"]
  s.email       = ["mwlang@cybrains.net"]
  s.homepage    = "https://github.com/mwlang/dinero"
  s.summary     = "Dinero automates the process of logging into banking and financial websites to collect account balances."
  s.description = "Dinero automates the process of logging into banking and financial websites to collect account balances.  For now, only account balances are collected.  Planned to download transactions and download eStatements in the future"
  s.license     = "MIT"

  s.files = Dir["{examples,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.require_paths = ["lib"]
  s.test_files = Dir["spec/**/*"]

  s.add_development_dependency "rspec", "~> 3.2.0"
  s.add_development_dependency "rspec-its", "~> 1.2.0"
  s.add_development_dependency "vcr", "~> 2.9.3"
  s.add_development_dependency "webmock", "~> 1.21.0"
  s.add_development_dependency "simplecov", "~> 0.10.0"
  s.add_development_dependency "pry-byebug", "~> 3.1.0"

  s.add_dependency 'selenium-webdriver', "~> 2.45.0"
  s.add_dependency "rails", "~> 4"
  s.add_dependency "nokogiri", "~> 1.6.6"
end
