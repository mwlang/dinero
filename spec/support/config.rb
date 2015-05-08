require 'yaml'

def bank_configurations
  config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'config'))
  @bank_configurations ||= YAML::load_file(File.join(config_path, 'banks.yml'))
end

def bank_configured? bank
  !!bank_configurations[bank.to_s]
end