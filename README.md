# Dinero
Dinero makes logging into all your online banking websites trivial for retrieving accounts, balances, and transactions.

Banks are rightly concerned about security, anti-phishing, and general brute force attacks on their sites, so they have developed a number of creative ways of protecting access to their sites.  Some techniques include:

* Asking for only username on first page, then password on the next page.
* Multiple redirects.
* Asking security questions when browser cookies aren't set.
* loading login forms with JavaScript or requiring JS is enabled.
* loading login forms inside of IFRAME
* Randomizing code behind the PIN pad that you must click.

So much trickery requires something more than just Mechanize or RestClient.  Dinero uses Selenium and PhantomJS to drive the data collection.  So, you'll need to install Selenium before you can begin using Dinero.  If you're on a mac:

    brew install selenium-server-standalone
    
And then: 

    gem install dinero
    
## The Vision

Much like ActiveRecord sought to standardize the API for accessing and modeling domain data in the DBMS without having to drop down to raw SQL and as ActiveMerchant seeks to standardize payment processing to a common set of API's, Dinero aims to standardize access to bank accounts.  To that end, I have started implementing all the banks I have accounts with.

## Project Status

The following banks are implemented:

* Capital One - https://capitalone.com (only U.S. credit card logins -- there's also banking, loans, investing, business, and Canada/UK credit cards)
* Capital One 360 - https://capitalone360.com (formerly Ing Direct).  

Currently, only Accounts balances are essentially implemented.  The following properties are available on each Account:

  * account_type -- one of :bank, :brokerage, :credit_card
  * name -- the name of the account (e.g. "Checking 360 - primary", "Worldview MasterCard")
  * number -- the account number in-as-much as it's displayed
  * balance -- the balance on the account.  For :credit_card, this is outstanding balance
  * available -- the amount available to you.  For :credit_card, difference between your credit limit and balance

## How to Use

You'll find at least one example in the examples folder called 'get_balances.'  This example can take a bank_name, username, and password and print out balances to the console something like this:

~~~ bash
>> bundle exec ruby examples/get_balances.rb --bank capital_one_360 --user scrooge
enter password:
Retrieving your bank account information...
+--------------------------------------------------------------------------------+
|                                name |       number |     balance |   available |
+--------------------------------------------------------------------------------+
|              360 Checking - primary |    735546410 | $ 111543.07 | $ 111210.61 |
|                  MONEY - SK's Money |    112335590 | $    302.39 | $    302.39 |
|        360 Savings - Rainy Day Fund |     12341232 | $  12144.45 | $  12144.45 |
|                       SB Individual |   0903959692 | $  10191.23 | $  10191.23 |
|                       Visa Platinum |     ....1165 | $     87.10 | $  19912.90 |
|                    World MasterCard |     ....2978 | $    192.66 | $  19807.34 |
+--------------------------------------------------------------------------------+
~~~

Don't worry, all those numbers are made up.  ;-)

So, yeah, with more banks, we can collect more info.  The above shows banking accounts, brokerage account, and credit card accounts.

To use the gem inside your app:

~~~
require 'dinero'

bank_info = CapitalOne360.new(username: @username, password: @password))
bank_info.accounts.each do |acct|
puts [acct.name, acct.number, acct.account_type, acct.balance, acct.available].join("\t")
~~~

If you have a really slow Bank site or Internet connection, try passing ```timeout: 15``` when initializing a Bank class.

## Contribute!

I'm planning to continue implementing more banks, but I can use your help since I don't have access to all the world's banks.

I plan to implement the following banks:

  * Wells Fargo (Loans)
  * Scottrade (brokerage, IRA, and Bank Account)
  * San Diego County Credit Union
  * Georgia's Own Credit Union
  * South State Bank

I know I'll need to do those fun security questions for unregistered browsers on some of these.  I haven't quite decided on how to structure this, but at least the Bank class has an open-ended options hash parameter to accommodate additional fields being passed in.
  
If you want to add a new bank, here's how:

  # Pick one of the existing banks that most closely follows the login pattern of your chosen bank and model your effort after it.
  # Set up a new class in the lib/banks folder.
  # Set up rspec specs in the spec/banks folder.
  # Set up a spec/config/banks.yml file with your credentials (don't commit to the repo! -- it's .gitignore'd)

Here's an example banks.yml file:

~~~ yaml
capital_one_360:
  username: mickeymouse
  password: moosamoosamickeymouse
  account_types: 
    - :bank
    - :brokerage
    - :credit_card
  accounts: 3
  
capital_one:
  username: mickeymouse
  password: moosamoosamickeymouse
  account_types: 
    - :credit_card
  accounts: 2
~~~

The bank rspecs are wrapped with ```if bank_configured? :capital_one_360``` if block that allows the spec to run or not, so if the first thing you did was 'rspec' and saw 0 examples, that means you don't have a banks.yml file, yet -- or it's incorrectly configured.

Once you have the basic structure in place, then implement the following methods for your Bank class:

### Inherit from the Base class

Be sure your Bank class is inherited from the Bank::Base class.

### #login!

The #login! method expects to navigate to the login URL and then key in account credentials and finish with the user fully authenticated on the site.  I found it best to browse the website in Firefox and Inspect the elements I wanted to key data into (user and password fields).  You may have to switch to a frame if the login form is inside an IFRAME.  You may have to wait until the login form is presented if it's delay-loaded via JavaScript.  These are the two principal challenges I encountered.  Some banks split user account and password credentials into two screens.  Use a Private/Incognito Window as the Selenium environment will be without cookies so your browser experience should be, too.

### #post_username!
The #login! calls post_username! after navigating to the login URL.  If your bank only prompts for User account here, key it and post the form.  If password and username are entered on this screen, just key the username and then implement the form submit in the #post_password! method.  It should look something like this:

~~~ ruby
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
~~~

### #post_password! 
Here, key the password and submit the form.  You may have to get the handle on the button and call the button.click method instead of simply calling form.submit as some banks put JavaScript here to make sure the button's being clicked rather than automated submittals via scripts.  The implementation should look something like this:

~~~ ruby
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
~~~

## Tips to getting logged in successfully.

```binding.pry``` is your friend.  Set up the very basic rspec spec to trigger the login process and stick binding.pry at the point where you're having trouble.  Then use connection.page_source and connection.find_element, etc. to work your way through successfully grabbing controls, keying data, and posting the form.  Compare what connection.page_source prints out to what you get when viewing source in your browser.  Take screenshots with connection.save_screenshot('somefilename') to get a visual cue on what's really going on.

### #accounts_summary_document

Once you're successfully logging in, the expectation is that we'll get the list of accounts from the page along with name, number, and balances.  Almost all banks drop you in at an accounts summary page with enough information to gather the basic data we're interested in.  So, the next task after logging in is to implement accounts_summary_document so that you parse this page's contents into a Nokogiri document.  Once you can successfully construct the Nokogiri document, you can capture the above login chain of events through #accounts_summary_document via the VCR gem and you can rapidly evolve the #accounts solution through TDD.  All the fun Bank tricks will be neatly captured for near instant playback, which is a boon since these banking sites can take upwards of 45 seconds to go from Login page to Accounts Summary page.  Be aware that if you have to touch the connection object again after getting your accounts_summary_document, you'll see spurious errors from VCR, so it's best to be self-reliant on the Nokogiri document once you can retrieve the accounts summaries.

### #accounts

This method returns an Array of Account objects.  How you get from HTML page to an Array of Accounts is largely dependent on what the website is feeding you and some of these pages can be quite *ugly*, but fortunately, go years without any significant changes.  A typical extraction from HTML to Accounts might look like this:

~~~ ruby
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
    credit = article.xpath(".//div[@id='#{prefix}_available_credit_amount']").text.split("\n").first
    Account.new(:credit_card, name, number, balance, credit)
  end
end
~~~

Try to structure your specs so that likely scenarios of others who have accounts will also pass.  In other words, if there's something you really want to test, like number of accounts retrieved, or types of accounts retrieved, place those as new options in the banks.yml file.  Reference those in the let(:option { ... } blocks at the top of the specs.  See capital_one_spec and capital_one_360_spec for examples.

Once you've implemented and tested, send me your PR.  Don't check in your banks.yml nor your vcr_cassettes classes.  Others who need to fix will just have to get their own credentials working -- at least for now.  At some point, it would be nice to figure out how to version the cassettes without risking accidental inclusion of sensitive credentials.  I'm thinking a before commit hook on git that checks the banks.yml file against the cassettes before making a commit or something along those lines.

Happy Banking!
