require 'faraday'
require 'uri'

class Http
  def self.is_url(url)
    # This method exists because it seems like Farady
    # has no handling around if a user gives us a URI
    # with no protocol on the beginning of the URL

    uri = URI.parse(url)

    if uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
      return true
    end

    return false
  end

  def self.get_conn(verbose, url)
    if url.nil?
      raise "Did not provide a url to connect to"
    end

    unless is_url(url)
      url = "https://#{url}"
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

    unless is_url(url)
      url = "https://#{url}"
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
