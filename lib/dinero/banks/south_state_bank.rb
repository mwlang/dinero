module Dinero
  module Bank
    class SouthStateBank < Base
      LOGIN_URL = "https://www.southstatebank.com/"
      ACCOUNTS_SUMMARY_PATH = "/accounts"
      CONNECTION_TIMEOUT = 10

      def default_options
        { timeout: CONNECTION_TIMEOUT, login_url: LOGIN_URL }
      end

      def post_username!
        screenshot_on_error do
          wait.until { connection.find_element(id: "desktop-splash-login") }
          login_form = connection.find_element(id: "desktop_hero_form_online_banking")
          username_field = login_form.find_element(id: "desktop_hero_input_online_banking")
          username_field.send_keys username

          submit_button = login_form.find_element(xpath: ".//input[@type='submit']")
          submit_button.click
        end
      end

      def post_security_answer!
        screenshot_on_error do
          wait.until { connection.find_element(id: "nav2t") }
          logon_form = connection.find_element(id: "Logon")
          question_text = logon_form.find_element(xpath: ".//table/tbody/tr/td").text
          answer = find_answer question_text

          answer_field = logon_form.find_element(id: "QuestionAnswer")
          answer_field.send_keys answer

          submit_button = logon_form.find_element(id:"Submit")
          submit_button.click
        end
      end

      def post_password!
        wait.until { connection.find_element(id: "DisplayPassword") }

        password_field = connection.find_element(id: "DisplayPassword")
        password_field.send_keys password

        login_btn = connection.find_element(id: "Submit")
        login_btn.click
      end

      def post_credentials!
        post_username!
        post_security_answer!
        post_password!
      end

      def after_successful_login
        # the subdomain frequently changes, so capture the actual URL
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url
      end

      def on_accounts_summary_page?
        connection.page_source =~ /List of Accounts/
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : login!
      end

      def account_table_rows
        accounts_summary_document.xpath("//ul[@class='AccountList-Accounts']/li/table/tbody/tr")
      end

      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts

        # find the bricklet articles, which contains the balance data
        @accounts = account_table_rows.map do |row|
          data = row.xpath(".//td").map(&:text)
          number = data.shift
          name = data.shift
          balance = data.pop.scan(NUMERIC_REGEXP).join
          available = data.pop.scan(NUMERIC_REGEXP).join
          available = balance if available.empty?
          Account.new(:bank, name, number, balance, available)
        end
      end
    end
  end
end
