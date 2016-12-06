require 'spec_helper'

if bank_configured? :scottrade

  RSpec.describe Dinero::Bank::Scottrade do
    let(:bank_configuration) { bank_configurations[:scottrade] }
    let(:account_types) { bank_configuration[:account_types] }
    let(:accounts) { bank_configuration[:accounts] }
    let(:acct_name) { bank_configuration[:acct_name] }

    before(:all) do
      VCR.use_cassette("accounts_scottrade", record: :new_episodes) do
        @bank = Dinero::Bank::Scottrade.new(bank_configurations[:scottrade])
        @bank.accounts
      end
    end

    it "authenticates" do
      @bank.login!
      expect(@bank.authenticated?).to eq true
    end

    it "retrieves accounts_summary_document" do
      expect(@bank.accounts_summary_document).to be_kind_of Nokogiri::HTML::Document
    end

    it "has brokerage_table" do
      expect(@bank.brokerage_data.size).to eq 2
    end

    it "gets expected accounts" do
      expect(@bank.accounts.size).to eq accounts
    end

    it "extracts account names" do
      expect(@bank.accounts.map(&:name)).to_not be_empty
    end

    it "extracts account numbers" do
      expect(@bank.accounts.map(&:number).first).to start_with "513"
    end

    it "expects balances to be greater than zero" do
      expect(@bank.accounts.map(&:balance).any?(&:zero?)).to eq false
    end

    it "expects availables to be greater than zero for bank accts" do
      expect(@bank.accounts.map(&:available).any?(&:zero?)).to eq false
    end

    it "sets account types" do
      expect(@bank.accounts.map(&:account_type).uniq).to eq account_types
    end
  end

end
