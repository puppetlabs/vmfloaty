# frozen_string_literal: true

require 'faraday'
require 'vmfloaty/http'
require 'json'
require 'vmfloaty/errors'

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

  def self.list_active(verbose, url, token)
    status = Auth.token_status(verbose, url, token)
    vms = []
    if status[token] && status[token]['vms']
      vms = status[token]['vms']['running']
    end
    vms
  end

  def self.retrieve(verbose, os_type, token, url)
    # NOTE:
    #   Developers can use `Utils.generate_os_hash` to
    #   generate the os_type param.
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    os_string = os_type.map { |os, num| Array(os) * num }.flatten.join('+')
    if os_string.empty?
      raise MissingParamError, 'No operating systems provided to obtain.'
    end

    response = conn.post "vm/#{os_string}"

    res_body = JSON.parse(response.body)

    if res_body['ok']
      res_body
    elsif response.status == 401
      raise AuthError, "HTTP #{response.status}: The token provided could not authenticate to the pooler.\n#{res_body}"
    else
      raise "HTTP #{response.status}: Failed to obtain VMs from the pooler at #{url}/vm/#{os_string}. #{res_body}"
    end
  end

  def self.modify(verbose, url, hostname, token, modify_hash)
    if token.nil?
      raise TokenError, 'Token provided was nil. Request cannot be made to modify vm'
    end

    modify_hash.keys.each do |key|
      unless [:tags, :lifetime, :disk].include? key
        raise ModifyError, "Configured service type does not support modification of #{key}."
      end
    end

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    if modify_hash['disk']
      disk(verbose, url, hostname, token, modify_hash['disk'])
      modify_hash.delete 'disk'
    end

    response = conn.put do |req|
      req.url "vm/#{hostname}"
      req.body = modify_hash.to_json
    end

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.disk(verbose, url, hostname, token, disk)
    if token.nil?
      raise TokenError, 'Token provided was nil. Request cannot be made to modify vm'
    end

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.post "vm/#{hostname}/disk/#{disk}"

    res_body = JSON.parse(response.body)
    res_body
  end

  def self.delete(verbose, url, hosts, token)
    if token.nil?
      raise TokenError, 'Token provided was nil. Request cannot be made to delete vm'
    end

    conn = Http.get_conn(verbose, url)

    conn.headers['X-AUTH-TOKEN'] = token if token

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
    if token.nil?
      raise TokenError, 'Token provided was nil. Request cannot be made to snapshot vm'
    end

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.post "vm/#{hostname}/snapshot"
    res_body = JSON.parse(response.body)
    res_body
  end

  def self.revert(verbose, url, hostname, token, snapshot_sha)
    if token.nil?
      raise TokenError, 'Token provided was nil. Request cannot be made to revert vm'
    end

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
