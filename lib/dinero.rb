require 'selenium-webdriver'
require 'nokogiri'

require_relative 'dinero/version'

# Supported Banks
require_relative 'dinero/banks'
require_relative 'dinero/banks/capital_one'
require_relative 'dinero/banks/capital_one_360'
require_relative 'dinero/banks/south_state_bank'
require_relative 'dinero/banks/sdccu'
require_relative 'dinero/banks/georgias_own'

# Models
require_relative 'dinero/account'
