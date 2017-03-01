require 'vmfloaty'
require 'webmock/rspec'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end
