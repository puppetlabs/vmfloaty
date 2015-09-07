require 'faraday'
require 'json'
require 'vmfloaty/http'

class Auth
  def self.get_token(url, user, password)
    conn = Http.get_conn(url)

    resp = conn.post do |req|
            req.url '/v1/token'
            req.headers['Content-Type'] = 'application/json'
          end

    resp_body = JSON.parse(resp.body)
    resp_body
  end

  def self.delete_token(url, user, pass, token)
    if token.nil?
      puts 'You did not provide a token'
      return
    end

    conn = Http.get_conn(url)

    response = conn.delete "/v1/token/#{token}"
    res_body = JSON.parse(response)
    puts res_body
  end

  def self.token_status(url, user, pass, token)
    if token.nil?
      puts 'You did not provide a token'
      return
    end

    conn = Http.get_conn(url)

    response = conn.get "/v1/token/#{token}"
    res_body = JSON.parse(response.body)
    puts res_body
  end
end
