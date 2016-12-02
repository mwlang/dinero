module Dinero
  module Bank
    # San Diego County Credit Union
    class Sdccu < Base
      LOGIN_URL = "https://internetbranch.sdccu.com/SDCCU/Login.aspx"
      ACCOUNTS_SUMMARY_PATH = "/accounts"
      CONNECTION_TIMEOUT = 10

      def default_options
        { timeout: CONNECTION_TIMEOUT, login_url: LOGIN_URL }
      end

      def post_username!
        screenshot_on_error do
          wait.until { connection.find_element(id: "ctlSignon_txtUserID") }
          username_field = connection.find_element(id: "ctlSignon_txtUserID")
          username_field.send_keys username

          submit_button = connection.find_element(id: "ctlSignon_btnNext")
          submit_button.click
        end
      end

      def post_password!
        screenshot_on_error do
          wait.until { connection.find_element(id: "ctlSignon_txtPassword") }

          password_field = connection.find_element(id: "ctlSignon_txtPassword")
          password_field.send_keys password

          login_btn = connection.find_element(id: "ctlSignon_btnLogin")
          login_btn.click
        end
      end

      def find_answer question
        if q = security_questions.detect{ |qa| qa["question"] == question }
          return q["answer"]
        else
          raise "Unknown security question: #{question.inspect}"
        end
      end

      def post_security_answer!
        return if on_accounts_summary_page?
        screenshot_on_error do
          wait.until { connection.find_element(id: "lblChallengeQuestion") }
          question_text = connection.find_element(id: "lblChallengeQuestion").text
          answer = find_answer question_text

          answer_field = connection.find_element(id: "QuestionAnswer")
          answer_field.send_keys answer

          submit_button = logon_form.find_element(id:"btnSubmitAnswer")
          submit_button.click
        end
      end

      def post_credentials!
        post_username!
        post_password!
        post_security_answer!
      end

      def after_successful_login
        # the subdomain frequently changes, so capture the actual URL
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url
      end

      def on_accounts_summary_page?
        connection.page_source =~ /Account Balances/
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : login!
      end

      def account_tables
        accounts_summary_document.xpath("//div[@id='accountBalancesContainer_accountBalancesModule_accountList']//table")
      end

      def bank_accounts_table
        account_tables[0]
      end

      def loan_accounts_table
        account_tables[1]
      end

      def account_rows table, type
        rows = table.xpath(".//tr").map{|m| m.xpath(".//td").map{|m| m.text.strip}}
        rows.select{|s| s.size == 7}.map{|m| m.reject(&:empty?) << type}
      end

      def account_table_rows
        account_rows(bank_accounts_table, :bank) + account_rows(loan_accounts_table, :loan)
      end

      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts

        @accounts = account_table_rows.map do |row|
          acct_type = row.pop
          number = row.shift
          name = row.shift
          balance = row.shift.scan(NUMERIC_REGEXP).join
          available = acct_type == :loan ? "0.0" : balance
          Account.new(acct_type, name, number, balance, available)
        end
      end
    end
  end
end
