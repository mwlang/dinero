require 'spec_helper'

if bank_configured? :sdccu

  RSpec.describe Dinero::Bank::Sdccu do
    let(:bank_configuration) { bank_configurations[:sdccu] }
    let(:account_types) { bank_configuration[:account_types].sort }
    let(:accounts) { bank_configuration[:accounts] }

    before(:all) do
      VCR.use_cassette("accounts_sdccu", record: :new_episodes) do
        @bank = Dinero::Bank::Sdccu.new(bank_configurations[:sdccu])
        @bank.accounts
      end
    end

    it "has security questions" do
      expect(@bank.security_questions.count).to eq 4
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

    it "retrieves accounts_summary_document" do
      expect(@bank.accounts_summary_document).to be_kind_of Nokogiri::HTML::Document
    end

    it "has account_tables" do
      expect(@bank.account_tables.size).to eq 2
    end

    it "has bank_accounts_table" do
      expect(@bank.bank_accounts_table).to be_a Nokogiri::XML::Element
    end

    it "has loan_accounts_table" do
      expect(@bank.loan_accounts_table).to be_a Nokogiri::XML::Element
    end

    it "has 2 bank accounts" do
      expect(@bank.account_rows(@bank.bank_accounts_table, :bank).size).to eq 2
    end

    it "has 1 loan account" do
      expect(@bank.account_rows(@bank.loan_accounts_table, :loan).size).to eq 1
    end

    it "gets expected accounts" do
      expect(@bank.accounts.size).to eq accounts
    end

    it "extracts account names" do
      expect(@bank.accounts.map(&:name).select{|s| s =~ /Primary/}).to_not be_empty
    end

    it "extracts account numbers" do
      expect(@bank.accounts.map(&:number).first).to eq  "1"
    end

    it "expects balances to be greater than zero" do
      expect(@bank.accounts.map(&:balance).any?(&:zero?)).to eq false
    end

    it "expects availables to be greater than zero for bank accts" do
      expect(@bank.accounts.select{|s| s.bank_account?}.map(&:available).any?(&:zero?)).to eq false
    end

    it "expects availables to be zero for loan accts" do
      expect(@bank.accounts.select{|s| s.loan_account?}.map(&:available).all?(&:zero?)).to eq true
    end

    it "sets account types" do
      expect(@bank.accounts.map(&:account_type).uniq).to eq account_types
    end
  end

end
