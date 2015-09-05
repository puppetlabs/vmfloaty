require 'faraday'

class Http
  def self.get_conn(url)
    conn = Faraday.new(:url => url) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    return conn
  end
end
