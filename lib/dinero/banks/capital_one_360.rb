module Dinero
  module Bank
    class CapitalOne360 < Base
      LOGIN_URL = "https://secure.capitalone360.com/myaccount/banking/login.vm"
      ACCOUNTS_SUMMARY_URL = "https://secure.capitalone360.com/myaccount/banking/account_summary.vm"
  
      def default_options
        { login_url: LOGIN_URL }
      end

      def post_username!
        begin
          wait.until { connection.find_element(id: "Signin").displayed? }
        rescue
          connection.save_screenshot('log/capital_one_360_signin_failed.png')
          raise
        end

        signin_form = connection.find_element(id: "Signin")
        username_field = connection.find_element(id: "ACNID")
        raise "Sign in Form not reached!" unless username_field && signin_form
    
        username_field.send_keys username
        signin_form.submit
      end
  
      def post_password!
        begin
          wait.until { connection.find_element(id: "PasswordForm").displayed? }
        rescue
          connection.save_screenshot('log/capital_one_360_password_failed.png')
          raise
        end

        password_form = connection.find_element(id: "PasswordForm")
        password_field = connection.find_element(id: "currentPassword_TLNPI")
        submit_button = connection.find_element :css, ".bluebutton > a:nth-child(1)"
        raise "Password Form not reached!" unless password_field && password_form

        password_field.send_keys password
        submit_button.click
      end
  
      def accounts_summary_page_fully_loaded?
        tables = connection.find_elements css: 'table'
        !(tables.empty? or tables.detect{|t| t.text =~ /\sLoading/})
      end
      
      def on_accounts_summary_page?
        connection.current_url == ACCOUNTS_SUMMARY_URL
      end

      def goto_accounts_summary_page
        return if authenticated? && on_accounts_summary_page?
        authenticated? ? connection.navigate.to(ACCOUNTS_SUMMARY_URL) : login!
        wait.until { accounts_summary_page_fully_loaded? }
      end
  
      def accounts_summary_document
        return @accounts_summary_document if @accounts_summary_document

        goto_accounts_summary_page
        @accounts_summary_document = Nokogiri::HTML connection.page_source
      end
      
      def balance_row? row
        row[1] =~ /Total/
      end
  
      def promo_table? table
        table.empty? or table[0].empty? or table[0][0].empty?
      end

      def decipher_account_type title
        return :credit_card if title =~ /Credit Cards/
        return :brokerage if title =~ /ShareBuilder/
        return :bank if title =~ /Checking/
        return :unknown
      end

      def sanitize value
        return unless value
        value.split("\u00A0").first.strip
      end
      
      # extract account data from the account summary page
      def accounts
        return @accounts if @accounts
        @accounts = []
    
        # lots of spaces, tabs and the #00A0 characters, so extract
        # text with this extraneous junk suppressed.
        tables = accounts_summary_document.xpath("//table")
        account_tables = tables.map do |table| 
          rows = table.xpath(".//tr").map{|row| row.xpath(".//td|.//th").
            map{|cell| cell.text.strip.gsub(/\s+|\t/, " ")}}
        end.reject{|table| promo_table? table }

        # Turn tablular data into Account classes
        account_tables.map do |table|

          # the header row tells us what kind of account we're looking at
          header = table.shift
          account_type = decipher_account_type header[0]
          has_account_number = header[1] =~ /Account/
      
          # ignore balance rows at bottom of tables
          rows = table.reject{|row| balance_row? row }

          # turn those rows into accounts
          rows.each do |row|
            name = sanitize(row.shift)
            number = (has_account_number ? sanitize(row.shift) : nil)
            if number.nil? || name =~ /(\.{4})(\d+)\Z/
              number = name.match(/(\.{4})(\d+)\Z/).captures.join
              name = name.gsub(number,'')
            end
            balance = row.shift
            available = row.shift || balance
            @accounts << Account.new(account_type, name, number, balance, available)
          end
        end
        return @accounts
      end
    end
  end
end