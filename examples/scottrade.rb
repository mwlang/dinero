require_relative '../lib/dinero'
require 'pry-byebug'

@config = YAML.load_file('spec/config/banks.yml').fetch("scottrade2", {})

@username = @config["username"]
@password = @config["password"]

def camelize term
  string = term.to_s.sub(/^[a-z\d]*/) { $&.capitalize }
  string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
  string.gsub!(/\//, '::')
  string
end

def show_balances bank
  puts "Retrieving your bank account information..."
  bank.accounts

  puts "+" + "-" * 80 + "+"
  puts "| %35s | %12s | %11s | %11s |" % %w(name number balance available)
  puts "+" + "-" * 80 + "+"
  bank.accounts.each do |acct|
    puts "| %35s | %12s | $%10.2f | $%10.2f |" % [acct.name, acct.number, acct.balance, acct.available]
  end
  puts "+" + "-" * 80 + "+"
end

bank = Dinero::Bank::Scottrade.new(username: @username, password: @password)

bank.login!
show_balances bank
