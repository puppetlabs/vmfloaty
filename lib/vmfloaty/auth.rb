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
    if res_body['ok']
      return res_body['token']
    else
      raise TokenError, "HTTP #{resp.status}: There was a problem requesting a token:\n#{res_body}"
    end
  end

  def self.delete_token(verbose, url, user, password, token)
    if token.nil?
      raise TokenError, 'You did not provide a token'
    end

    conn = Http.get_conn_with_auth(verbose, url, user, password)

    response = conn.delete "token/#{token}"
    res_body = JSON.parse(response.body)
    if res_body['ok']
      return res_body
    else
      raise TokenError, "HTTP #{response.status}: There was a problem deleting a token:\n#{res_body}"
    end
  end

  def self.token_status(verbose, url, token)
    if token.nil?
      raise TokenError, 'You did not provide a token'
    end

    conn = Http.get_conn(verbose, url)

    response = conn.get "token/#{token}"
    res_body = JSON.parse(response.body)

    if res_body['ok']
      return res_body
    else
      raise TokenError, "HTTP #{response.status}: There was a problem getting the status of a token:\n#{res_body}"
    end
  end
end
