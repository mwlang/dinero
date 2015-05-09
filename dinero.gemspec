# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dinero/version'

Gem::Specification.new do |spec|
  spec.name          = "dinero"
  spec.version       = Dinero::VERSION
  spec.authors       = ["Michael Lang"]
  spec.email         = ["mwlang@cybrains.net"]
  spec.homepage      = "https://github.com/mwlang/dinero"
  spec.summary       = "Dinero automates the process of logging into banking and financial websites to collect account balances."
  spec.description   = "Dinero automates the process of logging into banking and financial websites to collect account balances.  For now, only account balances are collected.  Planned to download transactions and download eStatements in the future"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "rspec-its", "~> 1.2.0"
  spec.add_development_dependency "vcr", "~> 2.9.3"
  spec.add_development_dependency "webmock", "~> 1.21.0"
  spec.add_development_dependency "simplecov", "~> 0.10.0"
  spec.add_development_dependency "pry-byebug", "~> 3.1.0"

  spec.add_dependency 'selenium-webdriver', "~> 2.45.0"
  spec.add_dependency "nokogiri", "~> 1.6.6"
end
