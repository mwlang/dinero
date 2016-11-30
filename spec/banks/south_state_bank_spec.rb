require 'spec_helper'

if bank_configured? :south_state_bank

  RSpec.describe Dinero::Bank::SouthStateBank do
    let(:bank_configuration) { bank_configurations[:south_state_bank] }
    let(:account_types) { bank_configuration[:account_types].sort }
    let(:accounts) { bank_configuration[:accounts] }

    before(:all) do
      VCR.use_cassette("accounts_south_state_bank", record: :new_episodes) do
        @bank = Dinero::Bank::SouthStateBank.new(bank_configurations[:south_state_bank])
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

    it "retrieves accounts_summary_document" do
      expect(@bank.accounts_summary_document).to be_kind_of Nokogiri::HTML::Document
    end

    it "has account line items" do
      expect(@bank.account_table_rows.size).to eq 3
    end

    it "gets expected accounts" do
      expect(@bank.accounts.size).to eq accounts
    end

    it "extracts account names" do
      expect(@bank.accounts.map(&:name)).to include "Joint Acct"
    end

    it "extracts account numbers" do
      expect(@bank.accounts.map(&:number).first).to start_with  "******"
    end

    it "expects balances to be greater than zero" do
      expect(@bank.accounts.map(&:balance).any?(&:zero?)).to eq false
    end

    it "expects availables to be greater than zero" do
      expect(@bank.accounts.map(&:available).any?(&:zero?)).to eq false
    end

    it "sets account types" do
      expect(@bank.accounts.map(&:account_type).uniq).to eq account_types
    end
  end

end
