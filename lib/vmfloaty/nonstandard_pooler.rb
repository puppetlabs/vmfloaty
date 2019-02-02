# frozen_string_literal: true

require 'vmfloaty/errors'
require 'vmfloaty/http'
require 'faraday'
require 'json'

class NonstandardPooler
  def self.list(verbose, url, os_filter = nil)
    conn = Http.get_conn(verbose, url)

    response = conn.get 'status'
    response_body = JSON.parse(response.body)
    os_list = response_body.keys.sort
    os_list.delete 'ok'

    os_filter ? os_list.select { |i| i[/#{os_filter}/] } : os_list
  end

  def self.list_active(verbose, url, token)
    status = Auth.token_status(verbose, url, token)
    status['reserved_hosts'] || []
  end

  def self.retrieve(verbose, os_type, token, url)
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    os_string = os_type.map { |os, num| Array(os) * num }.flatten.join('+')
    if os_string.empty?
      raise MissingParamError, 'No operating systems provided to obtain.'
    end

    response = conn.post "host/#{os_string}"

    res_body = JSON.parse(response.body)

    if res_body['ok']
      res_body
    elsif response.status == 401
      raise AuthError, "HTTP #{response.status}: The token provided could not authenticate to the pooler.\n#{res_body}"
    else
      raise "HTTP #{response.status}: Failed to obtain VMs from the pooler at #{url}/host/#{os_string}. #{res_body}"
    end
  end

  def self.modify(verbose, url, hostname, token, modify_hash)
    if token.nil?
      raise TokenError, 'Token provided was nil; Request cannot be made to modify VM'
    end

    modify_hash.each do |key, value|
      unless [:reason, :reserved_for_reason].include? key
        raise ModifyError, "Configured service type does not support modification of #{key}"
      end
    end

    if modify_hash[:reason]
      # "reason" is easier to type than "reserved_for_reason", but nspooler needs the latter
      modify_hash[:reserved_for_reason] = modify_hash.delete :reason
    end

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token

    response = conn.put do |req|
      req.url "host/#{hostname}"
      req.body = modify_hash.to_json
    end

    response.body.empty? ? {} : JSON.parse(response.body)
  end

  def self.disk(verbose, url, hostname, token, disk)
    raise ModifyError, 'Configured service type does not support modification of disk space'
  end

  def self.snapshot(verbose, url, hostname, token)
    raise ModifyError, 'Configured service type does not support snapshots'
  end

  def self.revert(verbose, url, hostname, token, snapshot_sha)
    raise ModifyError, 'Configured service type does not support snapshots'
  end

  def self.delete(verbose, url, hosts, token)
    if token.nil?
      raise TokenError, 'Token provided was nil; Request cannot be made to delete VM'
    end

    conn = Http.get_conn(verbose, url)

    conn.headers['X-AUTH-TOKEN'] = token if token

    response_body = {}

    unless hosts.is_a? Array
      hosts = hosts.split(',')
    end
    hosts.each do |host|
      response = conn.delete "host/#{host}"
      res_body = JSON.parse(response.body)
      response_body[host] = res_body
    end

    response_body
  end

  def self.status(verbose, url)
    conn = Http.get_conn(verbose, url)

    response = conn.get '/status'
    JSON.parse(response.body)
  end

  def self.summary(verbose, url)
    conn = Http.get_conn(verbose, url)

    response = conn.get '/summary'
    JSON.parse(response.body)
  end

  def self.query(verbose, url, hostname)
    conn = Http.get_conn(verbose, url)

    response = conn.get "host/#{hostname}"
    JSON.parse(response.body)
  end
end
