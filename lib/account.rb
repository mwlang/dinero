module Dinero
  class Account
    attr_reader :account_type, :name, :name_other, :number, :balance, :available
    def initialize account_type, name, number, balance, available
      @account_type = account_type
      name_parts = name.split("\n")
      @name = name_parts.shift
      @name_other = name_parts.join("\n")
      @number = number
      @balance = balance.scan(/[\d|\-|\.]+/).join.to_f
      @available = available.scan(/[\d|\-|\.]+/).join.to_f
      @accounts = nil
    end
  end
end