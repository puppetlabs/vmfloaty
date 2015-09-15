require 'faraday'

class Http
  def self.get_conn(verbose, url)
    conn = Faraday.new(:url => url) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end
end
