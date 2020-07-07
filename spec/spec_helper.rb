# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start do
  add_filter %r{^/spec/}
end

require 'vmfloaty'
require 'webmock/rspec'

# Mock Commander Options object to allow pre-population with values
class MockOptions < Commander::Command::Options
  def initialize(values = {})
    @table = values
  end
end

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end
