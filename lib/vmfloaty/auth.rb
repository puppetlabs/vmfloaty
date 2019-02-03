# frozen_string_literal: true

require 'faraday'
require 'json'
require 'vmfloaty/http'
require 'vmfloaty/errors'

class Auth
  def self.get_token(verbose, url, user, password)
    conn = Http.get_conn_with_auth(verbose, url, user, password)

    resp = conn.post 'token'

    res_body = JSON.parse(resp.body)
    return res_body['token'] if res_body['ok']

    raise TokenError, "HTTP #{resp.status}: There was a problem requesting a token:\n#{res_body}"
  end

  def self.delete_token(verbose, url, user, password, token)
    raise TokenError, 'You did not provide a token' if token.nil?

    conn = Http.get_conn_with_auth(verbose, url, user, password)

    response = conn.delete "token/#{token}"
    res_body = JSON.parse(response.body)
    return res_body if res_body['ok']

    raise TokenError, "HTTP #{response.status}: There was a problem deleting a token:\n#{res_body}"
  end

  def self.token_status(verbose, url, token)
    raise TokenError, 'You did not provide a token' if token.nil?

    conn = Http.get_conn(verbose, url)

    response = conn.get "token/#{token}"
    res_body = JSON.parse(response.body)

    return res_body if res_body['ok']

    raise TokenError, "HTTP #{response.status}: There was a problem getting the status of a token:\n#{res_body}"
  end
end
