require 'faraday'
require 'vmfloaty/http'
require 'json'

class Pooler
  def self.list(verbose, url, os_filter=nil)
    conn = Http.get_conn(verbose, url)

    response = conn.get '/vm'
    response_body = JSON.parse(response.body)

    if os_filter
      hosts = response_body.select { |i| i[/#{os_filter}/] }
    else
      hosts = response_body
    end

    hosts
  end

  def self.retrieve(verbose, os_type, token, url)
    os = os_type.gsub(',','+')
    if token.nil?
      conn = Http.get_conn(verbose, url)
    else
      conn = Http.get_conn_with_token(verbose, url, token)
      conn.headers['X-AUTH-TOKEN']
    end

    response = conn.post "/vm/#{os}"

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.modify(verbose, url, hostname, token, lifetime, tags)
    modify_body = {}
    if lifetime
      modify_body['lifetime'] = lifetime
    end
    if tags
      modify_body['tags'] = tags
    end

    puts modify_body
    conn = Http.get_conn_with_token(verbose, url, token)
    conn.headers['X-AUTH-TOKEN']

    response = conn.put "/vm/#{hostname}"
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.delete(verbose, url, hostnames)
    if hostnames.nil?
      STDERR.puts "You did not provide any hosts to delete"
      exit 1
    end

    hosts = hostnames.split(',')
    conn = Http.get_conn(verbose, url)

    hosts.each do |host|
      puts "Scheduling host #{host} for deletion"
      response = conn.delete "/vm/#{host}"
      res_body = JSON.parse(response.body)
      puts res_body
    end
  end

  def self.status(verbose, url)
    conn = Http.get_conn(verbose, url)

    response = conn.get '/status'
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.summary(verbose, url)
    conn = Http.get_conn(verbose, url)

    response = conn.get '/summary'
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.query(verbose, url, hostname)
    conn = Http.get_conn(verbose, url)

    response = conn.get "/vm/#{hostname}"
    res_body = JSON.parse(response.body)

    res_body
  end

  def self.snapshot(verbose, url, hostname, token)
    conn = Http.get_conn_with_token(verbose, url, token)
    conn.headers['X-AUTH-TOKEN']

    response = conn.post "/vm/#{hostname}/snapshot"
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.revert(verbose, url, hostname, token, snapshot_sha)
    conn = Http.get_conn_with_token(verbose, url, token)
    conn.headers['X-AUTH-TOKEN']

    response = conn.post "/vm/#{hostname}/snapshot/#{snapshot}"
    res_body = JSON.parse(response.body)
    res_body
  end
end
