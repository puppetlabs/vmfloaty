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
end
