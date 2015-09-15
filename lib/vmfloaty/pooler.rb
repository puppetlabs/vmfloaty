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
    os = os_type.split(',')
    conn = Http.get_conn(verbose, url)
    os_body = {}

    os.each do |os_type|
      unless os_body.has_key?(os_type)
        os_body[os_type] = 1
      else
        os_body[os_type] = os_body[os_type] + 1
      end
    end

    response = conn.post do |req|
        req.url '/vm'
        req.headers['Content-Type'] = 'application/json'
        req.body = os_body
      end

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.modify(verbose, url, hostname, token, lifetime, tags)
    modify_body = {'lifetime'=>lifetime, 'tags'=>tags}
    conn = Http.get_conn(verbose, url)

    # need to use token
    response = conn.put "/#{hostname}"
    res_body = JSON.parse(response.body)

    res_body
  end

  def self.delete(verbose, url, hostname)
    hosts = hostnames.split(',')
    conn = Http.get_conn(verbose, url)

    hosts.each do |host|
      puts "Scheduling host #{host} for deletion"
      response = conn.delete "/#{host}"
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
    conn = Http.get_conn(verbose, url)

    # need to use token
    response = conn.post "/#{hostname}/snapshot"
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.revert(verbose, url, hostname, token, snapshot_sha)
    conn = Http.get_conn(verbose, url)

    # need to use token
    response = conn.post "/#{hostname}/snapshot/#{snapshot}"
    res_body = JSON.parse(response.body)
    res_body
  end
end
