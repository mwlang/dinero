module Dinero
  module Bank
    DEFAULT_TIMEOUT = 5

    class Base
      attr_reader :username, :password
      attr_reader :timeout
    
      def initialize options
        opts = default_options.merge options
      
        @username = opts[:username]
        @password = opts[:password]
        @timeout = opts[:timeout]
        @authenticated = false
      end

      def default_options
        {timeout: DEFAULT_TIMEOUT}
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
    end
  end
end