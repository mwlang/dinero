module Dinero
  module Bank
    # San Diego County Credit Union
    class GeorgiasOwn < Base
      LOGIN_URL = "https://www.georgiasown.org/index"
      ACCOUNTS_SUMMARY_PATH = "https://online.georgiasown.org/DashboardV2"
      CONNECTION_TIMEOUT = 20

      def default_options
        { timeout: CONNECTION_TIMEOUT, login_url: LOGIN_URL }
      end

      def post_username!
        screenshot_on_error do
          wait.until { connection.find_element(id: "login") }
          login_area = connection.find_element(id: "login")

          username_field = login_area.find_element(name: "UserName")
          username_field.send_keys username

          submit_button = login_area.find_element(xpath: ".//input[@type='submit']")
          submit_button.click
        end
      end

      def post_password!
        screenshot_on_error do
          wait.until { connection.find_element(id: "content") }
          form = connection.find_element(id: "content")

          password_field = form.find_element(id: "Password")
          password_field.send_keys password

          login_btn = form.find_element(xpath: ".//input[@type='submit']")
          login_btn.click
        end
      end

      def post_security_answer!
        # return if on_accounts_summary_page?
        # screenshot_on_error do
        #   wait.until { connection.find_element(id: "lblChallengeQuestion") }
        #   question_text = connection.find_element(id: "lblChallengeQuestion").text
        #   answer = find_answer question_text
        #
        #   answer_field = connection.find_element(id: "QuestionAnswer")
        #   answer_field.send_keys answer
        #
        #   submit_button = logon_form.find_element(id:"btnSubmitAnswer")
        #   submit_button.click
        # end
      end

      def post_credentials!
        post_username!
        # post_security_answer!
        post_password!
        wait.until { connection.find_elements(xpath: "//div[@id='module_accounts']//ul/li").size > 0 }
      end

      def after_successful_login
        # the subdomain frequently changes, so capture the actual URL
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url
      end

      def on_accounts_summary_page?
        connection.page_source =~ /My Accounts/
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : login!
      end

      def account_table_rows
        items = accounts_summary_document.xpath("//div[@id='module_accounts']//ul/li")
        items.select{|s| s.attributes["data-is-external-account"]}
      end

      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts

        @accounts = account_table_rows.map do |row|
          acct_type = :bank
          name = row.xpath(".//h4").text
          number = row.xpath(".//span[@class='account-number truncate']").text.strip

          amount = row.xpath(".//span[@class='bal available']").text
          balance = amount.strip.scan(NUMERIC_REGEXP).join
          available = balance

          Account.new(acct_type, name, number, balance, available)
        end
      end
    end
  end
end
