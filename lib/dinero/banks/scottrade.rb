module Dinero
  module Bank
    # San Diego County Credit Union
    class Scottrade < Base
      LOGIN_URL = "https://trading.scottrade.com/default.aspx"
      CONNECTION_TIMEOUT = 20

      def default_options
        { timeout: CONNECTION_TIMEOUT, login_url: LOGIN_URL }
      end

      def post_username!
        screenshot_on_error do
          wait.until { connection.find_element(id: "ctl00_body_txtAccountNumber") }
          username_field = connection.find_element(id: "ctl00_body_txtAccountNumber")
          username_field.send_keys username
        end
      end

      def post_password!
        screenshot_on_error do
          password_field = connection.find_element(id: "ctl00_body_txtPassword")
          password_field.send_keys password

          login_btn = connection.find_element(id: "ctl00_body_btnLogin")
          login_btn.click
        end
      end

      def skip_confirmations_page
        if connection.page_source =~ /has trade confirmations/
          button = connection.find_element(id: "ctl00_body_btnViewLater")
          button.click
        end
      end

      # <button type="button" class="ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" role="button" aria-disabled="false"><span class="ui-button-text">Close</span></button>
      def skip_monthly_statements_modal
        if connection.page_source =~ /ui\-dialog\-title\-monthlyStatementsDiv/
          button = connection.find_element(xpath: "button[@class='ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only']")
          button.click
        end
      end

      def post_credentials!
        post_username!
        post_password!
        skip_confirmations_page
        skip_monthly_statements_modal
        expand_bank_table
      end

      def after_successful_login
        # the subdomain frequently changes, so capture the actual URL
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url
      end

      def on_accounts_summary_page?
        connection.page_source =~ /Brokerage Balances/
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : login!
      end

      def expand_bank_table
        return unless connection.page_source =~ /ctl00_PageContent_ctl02_w1_widgetContent1_lblDisplayBankBalanceLink/
        expand_link = connection.find_element(id: "ctl00_PageContent_ctl02_w1_widgetContent1_lblDisplayBankBalanceLink")
        expand_link.click
        wait.until { connection.find_element(id: "bankBalance66") }
      end

      def brokerage_table
        accounts_summary_document.css("#ctl00_PageContent_ctl02_w1_widgetContent1_tblBalanceElements66").first
      end

      def bank_table
        table = accounts_summary_document.css("#bankBalance66")
      end

      def brokerage_data
        rows = brokerage_table.xpath("tbody/tr").map{|tr| tr.xpath("td").map(&:text)}
        available = rows.shift.last
        rows.shift
        rows.shift
        balance = rows.shift.last
        return { available: available, balance: balance }
      end

      def brokerage_account
        data = brokerage_data
        Account.new :brokerage, username, username, data[:balance], data[:available]
      end

      def bank_data
        rows = bank_table.xpath("tbody/tr").map{|tr| tr.xpath("td").map(&:text)}
        available = rows.shift.last
        balance = rows.shift.last
        return { available: available, balance: balance }
      rescue
        return nil
      end

      def bank_account
        if data = bank_data
          Account.new :bank, "Bank", "", data[:balance], data[:available]
        end
      end

      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts
        @accounts = [ brokerage_account, bank_account ].compact
      end
    end
  end
end
