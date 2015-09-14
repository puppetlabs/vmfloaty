require 'faraday'
require 'vmfloaty/http'
require 'json'

class Pooler
  def self.list(url, os_filter=nil)
    conn = Http.get_conn(url)

    response = conn.get '/vm'
    response_body = JSON.parse(response.body)

    if os_filter
      hosts = response_body.select { |i| i[/#{os_filter}/] }
    else
      hosts = response_body
    end

    puts hosts
  end

  def self.retrieve(os_type, token, url)
    os = os_type.split(',')
    conn = Http.get_conn(url)
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

    puts JSON.parse(response.body)
  end

  def self.modify(url, hostname, token, lifetime, tags)
    modify_body = {'lifetime'=>lifetime, 'tags'=>tags}
    conn = Http.get_conn(url)

    # need to use token
    response = conn.put "/#{hostname}"
    res_body = JSON.parse(response.body)

    puts res_body
  end

  def self.delete(url, hostname)
    hosts = hostnames.split(',')
    conn = Http.get_conn(url)

    hosts.each do |host|
      puts "Scheduling host #{host} for deletion"
      response = conn.delete "/#{host}"
      res_body = JSON.parse(response.body)
      puts res_body
    end
  end

  def self.status(url)
    conn = Http.get_conn(url)

    response = conn.get '/status'
    res_body = JSON.parse(response.body)
    puts res_body
  end

  def self.summary(url)
    conn = Http.get_conn(url)

    response = conn.get '/summary'
    res_body = JSON.parse(response.body)
    puts res_body
  end

  def self.query(url, hostname)
    conn = Http.get_conn(url)

    response = conn.get "/vm/#{hostname}"
    res_body = JSON.parse(response.body)

    puts res_body
  end

  def self.snapshot(url, hostname, token)
    conn = Http.get_conn(url)

    # need to use token
    response = conn.post "/#{hostname}/snapshot"
    res_body = JSON.parse(response.body)
    puts res_body
  end

  def self.revert(url, hostname, token, snapshot_sha)
    conn = Http.get_conn(url)

    # need to use token
    response = conn.post "/#{hostname}/snapshot/#{snapshot}"
    res_body = JSON.parse(response.body)
    puts res_body
  end
end
