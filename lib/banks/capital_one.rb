module Dinero
  module Bank
    class CapitalOne < Base
      LOGIN_URL = "https://servicing.capitalone.com/c1/Login.aspx"
      ACCOUNTS_SUMMARY_PATH = "/accounts"
      CONNECTION_TIMEOUT = 10

      def default_options
        { timeout: CONNECTION_TIMEOUT }
      end
      
      def signin!
        signin_form = connection.find_element(name: "login")
        username_field = signin_form.find_element(id: "uname")
        password_field = signin_form.find_element(id: "cofisso_ti_passw")
        login_btn = signin_form.find_element(id: "cofisso_btn_login")
    
        username_field.send_keys username
        password_field.send_keys password
        login_btn.click
        wait.until { on_accounts_summary_page? }
      end
      
      def authenticate!
        return if authenticated?
        
        connection.navigate.to LOGIN_URL    
        connection.switch_to.frame "loginframe"
      
        wait.until { connection.find_element(id: "uname") }
        signin!
        
        # the subdomain frequently changes, so capture the actual URL 
        # so we can return to the page if necessary.
        @accounts_summary_url = connection.current_url

        @authenticated = true
      end
  
      def on_accounts_summary_page?
        URI(connection.current_url).path == ACCOUNTS_SUMMARY_PATH
      end
      
      def goto_account_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(@accounts_summary_url) : authenticate!
      end
  
      def account_summary_document
        return @account_summary_document if @account_summary_document

        goto_account_summary_page
        @account_summary_document = Nokogiri::HTML connection.page_source
      end
      
      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts
    
        # find the bricklet articles, which contains the balance data
        articles = account_summary_document.xpath("//article").
          select{|a| a.attributes["class"].value == "bricklet"}

        @accounts = articles.map do |article|
          prefix = article.attributes["id"].value.gsub("_bricklet", '')
          name = article.xpath(".//a[@class='product_desc_link']").text
          number = article.xpath(".//span[@id='#{prefix}_number']").text
          balance = article.xpath(".//span[@id='#{prefix}_current_balance_amount']").text
          credit = article.xpath(".//div[@id='#{prefix}_available_credit_amount']").text.split("\n").first
          Account.new(:credit_card, name, number, balance, credit)
        end
      end
    end
  end
end