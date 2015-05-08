require 'spec_helper'

if bank_configured? :capital_one_360

  RSpec.describe Dinero::Bank::CapitalOne360 do
    let(:bank_configuration) { bank_configurations["capital_one_360"] }
    let(:account_types) { bank_configuration["account_types"].sort }
    
    before(:all) do
      VCR.use_cassette("accounts_capital_one_360") do
        @bank = Dinero::Bank::CapitalOne360.new(bank_configurations["capital_one_360"])
        @bank.accounts
      end
    end
    
    it "has expected timeout" do
      expect(@bank.timeout).to eq Dinero::Bank::DEFAULT_TIMEOUT
    end

    it "retrieves accounts" do
      expect(@bank.accounts).to_not be_empty
    end
  
    it "extracts account names" do 
      expect(@bank.accounts.map(&:name)).to include /Checking|Savings/
    end
  
    it "extracts account numbers" do 
      expect(@bank.accounts.map(&:number).select{|s| s.to_s.scan /\A\d+\Z/}).to_not be_empty
    end
  
    it "sets account types" do 
      expect(@bank.accounts.map(&:account_type).uniq.sort).to eq account_types
    end
  end
  
end