require 'faraday'

class Http
  def self.get_conn(verbose, url)
    if url.nil?
      STDERR.puts "The url you provided was empty"
      exit 1
    end

    conn = Faraday.new(:url => url) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end

  def self.get_conn(verbose, url, user, password)
    if url.nil?
      STDERR.puts "The url you provided was empty"
      exit 1
    end

    if user.nil?
      STDERR.puts "You did not provide a user to authenticate with"
      exit 1
    end

    conn = Faraday.new(:url => url) do |faraday|
      faraday.request :url_encoded
      faraday.request :basic_auth, user, password
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end
end
