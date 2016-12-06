module Dinero
  module Bank
    DEFAULT_TIMEOUT = 5

    class Base
      attr_reader :username, :password, :security_questions
      attr_reader :timeout, :login_url

      def initialize options
        opts = default_options.merge options

        @username = opts[:username]
        @password = opts[:password]
        @login_url = opts[:login_url]
        @security_questions = opts[:security_questions] || []
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

      def find_answer question
        if q = security_questions.detect{ |qa| qa["question"] == question }
          return q["answer"]
        else
          raise "Unknown security question: #{question.inspect}"
        end
      end

      def establish_connection
        capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs(
          'phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:50.0) Gecko/20100101 Firefox/50.0',
          'service_args' => ['--ignore-ssl-errors=true', '--ssl-protocol=any']
        )

        driver = Selenium::WebDriver.for :phantomjs, :desired_capabilities => capabilities
        driver.manage.window.size = Selenium::WebDriver::Dimension.new(1640, 768)
        driver
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

      def class_name
        self.class.to_s.downcase.gsub("dinero::bank::", '')
      end

      def snap filename
        filename = filename + '.png' unless filename =~ /\.png$/
        connection.save_screenshot "log/#{filename}"
      end

      def screenshot_on_error name = nil
        begin
          yield
        rescue
          unless name
            class_name, method_name = caller.first.match(/(\w+)\.rb\:\d+\:in\s\`([^\']+)/).captures
            name = "#{class_name}_#{method_name.gsub(/\W/, '')}"
          end
          snap "#{name}_error" unless @captured_error
          @captured_error = true
          raise
        end
      end

      def goto_login_page
        connection.navigate.to login_url
        snap "#{class_name}_login_page.png"
      end

      def login!
        return if authenticated?
        screenshot_on_error do
          goto_login_page
          post_credentials!
          wait.until { on_accounts_summary_page? }
          after_successful_login
          @authenticated = true
        end
      end

    end
  end
end
