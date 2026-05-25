# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rake', require: false

group :test do
  # base64 is a bundled gem in Ruby >= 3.4, so it must be declared explicitly.
  gem 'base64'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-html', '~> 0.13.1'
  gem 'simplecov-lcov', '~> 0.9.0'
  gem 'pry'
  gem 'rb-readline'
  gem 'rspec', '~> 3.13.0'
  gem 'rubocop', '~> 1.66'
  gem 'webmock', '~> 3.23'
end
