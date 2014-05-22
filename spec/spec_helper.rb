# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
begin
  require File.expand_path("../../testbed/config/environment", __FILE__)
rescue LoadError => e
  fail "Could not load the testbed app. Have you generated it?\n#{e.class}: #{e}"
end

require 'rspec/autorun'
require 'database_cleaner'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  ## Database Cleaner

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, :clean_with_truncation) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, :clean_with_truncation) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

