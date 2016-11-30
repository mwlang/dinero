module Dinero
  module Bank
    class CapitalOne < Base
      LOGIN_URL = "https://verified.capitalone.com/sic-ui/#/esignin?Product=Card"
      ACCOUNTS_SUMMARY_PATH = "/accounts/"
      CONNECTION_TIMEOUT = 30

      def default_options
        { timeout: CONNECTION_TIMEOUT, login_url: LOGIN_URL }
      end

      def post_username!
        wait.until { connection.find_element(id: "id-signin-form") }
        @signin_form = connection.find_element(id: "id-signin-form")
        username_field = @signin_form.find_element(id: "username")
        username_field.send_keys username
      end

      def post_password!
        password_field = @signin_form.find_element(id: "password")
        password_field.send_keys password

        login_btn = @signin_form.find_element(id: "id-signin-submit")
        login_btn.click
      end

      def post_credentials!
        post_username!
        post_password!
      end

      def after_successful_login
        # the subdomain frequently changes, so capture the actual URL
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url
      end

      def on_accounts_summary_page?
        URI(connection.current_url).path == ACCOUNTS_SUMMARY_PATH
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : login!
        wait.until { connection.find_element(id: "main_content") }
      end

      def first_numeric value
        value.split("\n").reject{|r| r.empty?}.first
      end

      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts

        # find the bricklet articles, which contains the balance data
        articles = accounts_summary_document.xpath("//article").
          select{|a| a.attributes["class"].value == "bricklet"}

        @accounts = articles.map do |article|
          prefix = article.attributes["id"].value.gsub("_bricklet", '')
          name = article.xpath(".//a[@class='product_desc_link']").text
          number = article.xpath(".//span[@id='#{prefix}_number']").text
          balance = article.xpath(".//span[@id='#{prefix}_current_balance_amount']").text
          available = first_numeric(article.xpath(".//div[@id='#{prefix}_available_credit_amount']").text)
          Account.new(:credit_card, name, number, balance, available)
        end
      end
    end
  end
end
