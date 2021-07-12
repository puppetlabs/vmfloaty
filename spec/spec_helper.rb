# frozen_string_literal: true

require 'simplecov'
require 'coveralls'
require 'base64'

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

def get_headers(username: nil, password: nil, token: nil, content_type: nil, content_length: nil)
  headers = {
    'Accept'          => '*/*',
    'Accept-Encoding' => /gzip/,
    'User-Agent'      => /Faraday/,
  }
  if username && password
    auth = Base64.encode64("#{username}:#{password}").chomp
    headers['Authorization'] = "Basic #{auth}"
  end
  headers['X-Auth-Token'] = token if token
  headers['Content-Type'] = content_type if content_type
  headers['Content-Length'] = content_length.to_s if content_length
  headers
end