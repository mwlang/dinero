require_relative '../lib/dinero'

args = ARGV.dup
while !args.empty? do
  option = args.shift
  if option =~ /\A\-\-/
    value = args.shift
  end
  case option
  when "--bank" then @bank = value
  when "--user" then @username = value
  when "--password" then @password = value
  end
end

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

if @bank && @username
  (print "enter password: "; @password = STDIN.noecho(&:gets).chomp; puts) unless @password
  bank_class = eval("Dinero::Bank::#{camelize(@bank)}")
  show_balances(bank_class.new(username: @username, password: @password))
else
  puts <<-USAGE
  usage: bundle exec ruby examples/get_balances.rb --bank <bank_name> --user <login_account_name> [--password <login_password>]

  * bank_name needs to match one of the class_names supported in the lib/banks folder.
  * if password omitted, you'll be prompted to supply one.

  USAGE
end
