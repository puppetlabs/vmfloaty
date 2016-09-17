require 'faraday'
require 'vmfloaty/http'
require 'json'

class Pooler
  def self.list(verbose, url, os_filter=nil)
    conn = Http.get_conn(verbose, url)

    response = conn.get 'vm'
    response_body = JSON.parse(response.body)

    if os_filter
      hosts = response_body.select { |i| i[/#{os_filter}/] }
    else
      hosts = response_body
    end

    hosts
  end

  def self.retrieve(verbose, os_type, token, url)
    conn = Http.get_conn(verbose, url)
    if token
      conn.headers['X-AUTH-TOKEN'] = token
    end

    os_string = ""
    os_type.each do |os,num|
      num.times do |i|
        os_string << os+"+"
      end
    end

    os_string = os_string.chomp("+")

    if os_string.size == 0
      raise "No operating systems provided to obtain. See `floaty get --help` for more information on how to get VMs."
    end

    response = conn.post "vm/#{os_string}"

    res_body = JSON.parse(response.body)
    if res_body["ok"]
      res_body
    else
      raise "Failed to obtain VMs from the pooler at #{url}/vm/#{os_string}. #{res_body}"
    end
  end

  def self.modify(verbose, url, hostname, token, lifetime, tags)
    modify_body = {}
    if lifetime
      modify_body['lifetime'] = lifetime
    end
    if tags
      modify_body['tags'] = tags
    end

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.put do |req|
      req.url "vm/#{hostname}"
      req.body = modify_body.to_json
    end

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.disk(verbose, url, hostname, token, disk)
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.post "vm/#{hostname}/disk/#{disk}"

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.delete(verbose, url, hosts, token)
    conn = Http.get_conn(verbose, url)

    if token
      conn.headers['X-AUTH-TOKEN'] = token
    end

    response_body = {}

    hosts.each do |host|
      response = conn.delete "vm/#{host}"
      res_body = JSON.parse(response.body)
      response_body[host] = res_body
    end

    response_body
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

    response = conn.get "vm/#{hostname}"
    res_body = JSON.parse(response.body)

    res_body
  end

  def self.snapshot(verbose, url, hostname, token)
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.post "vm/#{hostname}/snapshot"
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.revert(verbose, url, hostname, token, snapshot_sha)
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    if snapshot_sha.nil?
      raise "Snapshot SHA provided was nil, could not revert #{hostname}"
    end

    response = conn.post "vm/#{hostname}/snapshot/#{snapshot_sha}"
    res_body = JSON.parse(response.body)
    res_body
  end
end
