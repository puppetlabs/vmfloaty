require 'faraday'
require 'json'
require 'vmfloaty/http'

class Auth
  def self.get_token(verbose, url, user, password)
    conn = Http.get_conn(verbose, url, user, password)

    resp = conn.post do |req|
            req.url '/token'
            req.headers['Content-Type'] = 'application/json'
          end

    resp_body = JSON.parse(resp.body)
    resp_body
  end

  def self.delete_token(verbose, url, user, password, token)
    if token.nil?
      puts 'You did not provide a token'
      return
    end

    conn = Http.get_conn(verbose, url, user, password)

    response = conn.delete "/token/#{token}"
    res_body = JSON.parse(response)
    puts res_body
  end

  def self.token_status(verbose, url, user, password, token)
    if token.nil?
      puts 'You did not provide a token'
      return
    end

    conn = Http.get_conn(verbose, url, user, password)

    response = conn.get "/token/#{token}"
    res_body = JSON.parse(response.body)
    puts res_body
  end
end
