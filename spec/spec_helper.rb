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
