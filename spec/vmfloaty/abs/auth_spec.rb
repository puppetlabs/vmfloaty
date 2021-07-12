# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/vmfloaty/auth'

user = 'first.last'
pass = 'password'

describe Pooler do

  before :each do
    @abs_url = 'https://abs.example.com/api/v2'
  end

  describe '#get_token' do
    before :each do
      @get_token_response = '{"ok": true,"token":"utpg2i2xswor6h8ttjhu3d47z53yy47y"}'
      @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
    end

    it 'returns a token from abs' do
      stub_request(:post, 'https://abs.example.com/api/v2/token')
        .with(headers: get_headers(username: user, password: pass, content_length: 0))
        .to_return(status: 200, body: @get_token_response, headers: {})

      token = Auth.get_token(false, @abs_url, user, pass)
      expect(token).to eq @token
    end

    it 'raises a token error if something goes wrong' do
      stub_request(:post, 'https://abs.example.com/api/v2/token')
        .with(headers: get_headers(username: user, password: pass, content_length: 0))
        .to_return(status: 500, body: '{"ok":false}', headers: {})

      expect { Auth.get_token(false, @abs_url, user, pass) }.to raise_error(TokenError)
    end
  end

  describe '#delete_token' do
    before :each do
      @delete_token_response = '{"ok":true}'
      @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
    end

    it 'deletes the specified token' do
      stub_request(:delete, 'https://abs.example.com/api/v2/token/utpg2i2xswor6h8ttjhu3d47z53yy47y')
        .with(headers: get_headers(username: user, password: pass))
        .to_return(status: 200, body: @delete_token_response, headers: {})

      expect(Auth.delete_token(false, @abs_url, user, pass,
                              @token)).to eq JSON.parse(@delete_token_response)
    end

    it 'raises a token error if something goes wrong' do
      stub_request(:delete, 'https://abs.example.com/api/v2/token/utpg2i2xswor6h8ttjhu3d47z53yy47y')
        .with(headers: get_headers(username: user, password: pass))
        .to_return(status: 500, body: '{"ok":false}', headers: {})

      expect { Auth.delete_token(false, @abs_url, user, pass, @token) }.to raise_error(TokenError)
    end

    it 'raises a token error if no token provided' do
      expect { Auth.delete_token(false, @abs_url, user, pass, nil) }.to raise_error(TokenError)
    end
  end

  describe '#token_status' do
    before :each do
      @token_status_response = '{"ok":true,"utpg2i2xswor6h8ttjhu3d47z53yy47y":{"created":"2015-04-28 19:17:47 -0700"}}'
      @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
    end

    it 'checks the status of a token' do
      stub_request(:get, "#{@abs_url}/token/utpg2i2xswor6h8ttjhu3d47z53yy47y")
        .with(headers: get_headers)
        .to_return(status: 200, body: @token_status_response, headers: {})

      expect(Auth.token_status(false, @abs_url, @token)).to eq JSON.parse(@token_status_response)
    end

    it 'raises a token error if something goes wrong' do
      stub_request(:get, "#{@abs_url}/token/utpg2i2xswor6h8ttjhu3d47z53yy47y")
        .with(headers: get_headers)
        .to_return(status: 500, body: '{"ok":false}', headers: {})

      expect { Auth.token_status(false, @abs_url, @token) }.to raise_error(TokenError)
    end

    it 'raises a token error if no token provided' do
      expect { Auth.token_status(false, @abs_url, nil) }.to raise_error(TokenError)
    end
  end
end
