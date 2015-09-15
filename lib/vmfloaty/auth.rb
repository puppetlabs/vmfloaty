require 'faraday'
require 'json'
require 'vmfloaty/http'

class Auth
  def self.get_token(verbose, url, user, password)
    conn = Http.get_conn_with_auth(verbose, url, user, password)

    resp = conn.post "/token"

    res_body = JSON.parse(resp.body)
    if res_body["ok"]
      return res_body["token"]
    else
      STDERR.puts "There was a problem with your request:"
      puts res_body
      exit 1
    end
  end

  def self.delete_token(verbose, url, user, password, token)
    if token.nil?
      STDERR.puts 'You did not provide a token'
      exit 1
    end

    conn = Http.get_conn_with_auth(verbose, url, user, password)

    response = conn.delete "/token/#{token}"
    res_body = JSON.parse(response.body)
    if res_body["ok"]
      puts res_body
    else
      STDERR.puts "There was a problem with your request:"
      puts res_body
      exit 1
    end
  end

  def self.token_status(verbose, url, user, password, token)
    if token.nil?
      STDERR.puts 'You did not provide a token'
      exit 1
    end

    conn = Http.get_conn_with_auth(verbose, url, user, password)

    response = conn.get "/token/#{token}"
    res_body = JSON.parse(response.body)

    if res_body["ok"]
      puts res_body
    else
      STDERR.puts "There was a problem with your request:"
      puts res_body
      exit 1
    end
  end
end
