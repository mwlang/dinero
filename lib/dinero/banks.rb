module Dinero
  module Bank
    DEFAULT_TIMEOUT = 5

    class Base
      attr_reader :username, :password
      attr_reader :timeout, :login_url
    
      def initialize options
        opts = default_options.merge options
      
        @username = opts[:username]
        @password = opts[:password]
        @login_url = opts[:login_url]
        @timeout = opts[:timeout] || DEFAULT_TIMEOUT
        @authenticated = false
        validate!
      end

      def validate!
        raise "Must supply :username" if @username.to_s.empty?
        raise "Must supply :password" if @password.to_s.empty?
        raise "Must have a :login_url" if @login_url.to_s.empty?
      end
      
      def default_options
        {}
      end
    
      def establish_connection
        Selenium::WebDriver.for :phantomjs
      end

      def connection
        @connection ||= establish_connection
      end

      def authenticated?
        !!@authenticated
      end

      def wait
        @wait ||= Selenium::WebDriver::Wait.new(:timeout => timeout)
      end
      
      def accounts_summary_document
        return @accounts_summary_document if @accounts_summary_document

        goto_accounts_summary_page
        @accounts_summary_document = Nokogiri::HTML connection.page_source
      end

      def after_successful_login
        # NOP 
      end

      def login!
        return if authenticated?
        begin
          connection.navigate.to login_url
          post_username!
          post_password!
          wait.until { on_accounts_summary_page? }
          after_successful_login
          @authenticated = true
        rescue
          connection.save_screenshot('log/#{self.to_s.downcase}_login_failure.png')
          raise
        end
      end

    end
  end
end