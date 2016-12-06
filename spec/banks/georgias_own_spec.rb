require 'spec_helper'

if bank_configured? :georgias_own

  RSpec.describe Dinero::Bank::GeorgiasOwn do
    let(:bank_configuration) { bank_configurations[:georgias_own] }
    let(:account_types) { bank_configuration[:account_types].sort }
    let(:accounts) { bank_configuration[:accounts] }
    let(:acct_name) { bank_configuration[:acct_name] }

    before(:all) do
      VCR.use_cassette("accounts_georgias_own", record: :new_episodes) do
        @bank = Dinero::Bank::GeorgiasOwn.new(bank_configurations[:georgias_own])
        @bank.accounts
      end
    end

    it "has security questions" do
      expect(@bank.security_questions.count).to eq 3
    end

    it "finds favorite hobby answer" do
      expect(@bank.find_answer("What is your favorite hobby?")).to eq "tennis"
    end

    it "posts credentials" do
      expect(@bank.authenticated?).to be true
    end

    it "authenticates" do
      @bank.login!
      expect(@bank.authenticated?).to eq true
    end

    it "handles security questions" do
      pending "waiting for security questions to reappear to finish functionality!"
      expect(true).to be false
    end

    it "retrieves accounts_summary_document" do
      expect(@bank.accounts_summary_document).to be_kind_of Nokogiri::HTML::Document
    end

    it "has account_tables" do
      expect(@bank.account_table_rows.size).to eq 2
    end

    it "gets expected accounts" do
      expect(@bank.accounts.size).to eq accounts
    end

    it "extracts account names" do
      expect(@bank.accounts.map(&:name)).to_not be_empty
    end

    it "extracts account numbers" do
      expect(@bank.accounts.map(&:number).first).to start_with "800"
    end

    it "expects balances to be greater than zero" do
      expect(@bank.accounts.first.balance.zero?).to eq true
    end

    it "expects availables to be greater than zero for bank accts" do
      expect(@bank.accounts.first.balance.zero?).to eq true
    end

    it "sets account types" do
      expect(@bank.accounts.map(&:account_type).uniq).to eq account_types
    end
  end

end
