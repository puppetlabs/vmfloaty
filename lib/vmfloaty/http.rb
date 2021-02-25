# frozen_string_literal: true

require 'faraday'
require 'uri'

class Http
  def self.url?(url)
    # This method exists because it seems like Farady
    # has no handling around if a user gives us a URI
    # with no protocol on the beginning of the URL

    uri = URI.parse(url)

    return true if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    false
  end

  def self.get_conn(verbose, url)
    raise 'Did not provide a url to connect to' if url.nil?

    url = "https://#{url}" unless url?(url)

    Faraday.new(url: url, ssl: { verify: false }) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.get_conn_with_auth(verbose, url, user, password)
    raise 'Did not provide a url to connect to' if url.nil?

    raise 'You did not provide a user to authenticate with' if user.nil?

    url = "https://#{url}" unless url?(url)

    Faraday.new(url: url, ssl: { verify: false }) do |faraday|
      faraday.request :url_encoded
      faraday.request :basic_auth, user, password
      faraday.response :logger if verbose
      faraday.adapter Faraday.default_adapter
    end
  end
end
