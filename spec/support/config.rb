require 'yaml'

def symbolized_keys hash
  hash.keys.each do |key|
    hash[(key.to_sym rescue key) || key] = hash.delete(key)
  end
  hash.each_pair{|k,v| hash[k] = symbolized_keys(v) if v.is_a?(Hash)}
  return hash
end

def bank_configurations
  config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'config'))
  @bank_configurations ||= symbolized_keys YAML::load_file(File.join(config_path, 'banks.yml'))
end

def bank_configured? bank
  !!bank_configurations[bank.to_sym]
end