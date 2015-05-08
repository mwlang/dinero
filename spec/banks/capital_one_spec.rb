require 'spec_helper'

if bank_configured? :capital_one 

  RSpec.describe Dinero::Bank::CapitalOne do
    let(:bank_configuration) { bank_configurations["capital_one"] }
    let(:account_types) { bank_configuration["account_types"].sort }
    let(:accounts) { bank_configuration["accounts"] }
    
    before(:all) do
      VCR.use_cassette("accounts_capital_one") do
        @bank = Dinero::Bank::CapitalOne.new(bank_configurations["capital_one"])
        @bank.account_summary_document
      end
    end

    it "has expected timeout" do
      expect(@bank.timeout).to eq Dinero::Bank::CapitalOne::CONNECTION_TIMEOUT
    end
  
    it "authenticates" do 
      @bank.authenticate!
      expect(@bank.authenticated?).to eq true
    end
  
    it "retrieves account_summary_document" do
      expect(@bank.account_summary_document).to be_kind_of Nokogiri::HTML::Document
    end
  
    it "has article sections" do
      expect(@bank.account_summary_document.xpath("//article").size).to eq accounts + 1
    end

    it "gets expected accounts" do
      expect(@bank.accounts.size).to eq accounts
    end
  
    it "extracts account names" do 
      expect(@bank.accounts.map(&:name)).to include /MasterCard|Visa/
    end
  
    it "extracts account numbers" do 
      expect(@bank.accounts.map(&:number).select{|s| s.to_s.scan /\A[\.|\d]+\Z/}).to_not be_empty
    end
  
    it "sets account types" do 
      expect(@bank.accounts.map(&:account_type).uniq).to eq account_types
    end
  end
  
end