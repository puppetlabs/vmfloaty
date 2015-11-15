require 'faraday'

class Http
  def self.get_conn(verbose, url)
    if url.nil?
      raise "Did not provide a url to connect to"
    end

    conn = Faraday.new(:url => url, :ssl => {:verify => false}) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end

  def self.get_conn_with_auth(verbose, url, user, password)
    if url.nil?
      raise "Did not provide a url to connect to"
    end

    if user.nil?
      raise "You did not provide a user to authenticate with"
    end

    conn = Faraday.new(:url => url, :ssl => {:verify => false}) do |faraday|
      faraday.request :url_encoded
      faraday.request :basic_auth, user, password
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end

end
