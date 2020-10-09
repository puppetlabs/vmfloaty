# frozen_string_literal: true

require 'vmfloaty/errors'
require 'vmfloaty/http'
require 'vmfloaty/utils'
require 'faraday'
require 'json'

class ABS
  # List active VMs in ABS
  # This is what a job request looks like:
  # {
  #   "state":"filled",
  #   "last_processed":"2019-10-31 20:59:33 +0000",
  #   "allocated_resources": [
  #     {
  #       "hostname":"h3oyntawjm7xdch.delivery.puppetlabs.net",
  #       "type":"centos-7.2-tmpfs-x86_64",
  #       "engine":"vmpooler"}
  #     ],
  #   "audit_log":{
  #     "2019-10-30 20:33:12 +0000":"Allocated h3oyntawjm7xdch.delivery.puppetlabs.net for job 1572467589"
  #   },
  #   "request":{
  #     "resources":{
  #       "centos-7.2-tmpfs-x86_64":1
  #     },
  #   "job": {
  #     "id":1572467589,
  #     "tags": {
  #           "user":"mikker",
  #           "url_string":"floaty://mikker/1572467589"
  # },
  #           "user":"mikker",
  #           "time-received":1572467589
  #         }
  #       }
  #     }
  #
  @active_hostnames = {}

  def self.list_active_job_ids(verbose, url, user)
    all_job_ids = []
    @active_hostnames = {}
    get_active_requests(verbose, url, user).each do |req_hash|
      @active_hostnames[req_hash['request']['job']['id']] = req_hash # full hash saved for later retrieval
      all_job_ids.push(req_hash['request']['job']['id'])
    end

    all_job_ids
  end

  def self.list_active(verbose, url, _token, user)
    hosts = []
    get_active_requests(verbose, url, user).each do |req_hash|
      if req_hash.key?('allocated_resources')
        req_hash['allocated_resources'].each do |onehost|
          hosts.push(onehost['hostname'])
        end
      end
    end

    hosts
  end

  def self.get_active_requests(verbose, url, user)
    conn = Http.get_conn(verbose, url)
    res = conn.get 'status/queue'
    if valid_json?(res.body)
      requests = JSON.parse(res.body)
    else
      FloatyLogger.warn "Warning: couldn't parse body returned from abs/status/queue"
    end

    ret_val = []

    requests.each do |req|
      next if req == 'null'

      if valid_json?(req) # legacy ABS had another JSON string always-be-scheduling/pull/306
        req_hash = JSON.parse(req)
      elsif req.is_a?(Hash)
        req_hash = req
      else
        FloatyLogger.warn "Warning: couldn't parse request returned from abs/status/queue"
        next
      end

      begin
        next unless user == req_hash['request']['job']['user']

        ret_val.push(req_hash)
      rescue NoMethodError
        FloatyLogger.warn "Warning: couldn't parse user returned from abs/status/queue: "
      end
    end

    ret_val
  end

  def self.all_job_resources_accounted_for(allocated_resources, hosts)
    allocated_host_list = allocated_resources.map { |ar| ar['hostname'] }
    (allocated_host_list - hosts).empty?
  end

  def self.delete(verbose, url, hosts, token, user)
    # In ABS terms, this is a "returned" host.
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    FloatyLogger.info "Trying to delete hosts #{hosts}" if verbose
    requests = get_active_requests(verbose, url, user)

    jobs_to_delete = []

    ret_status = {}
    hosts.each do |host|
      ret_status[host] = {
        'ok' => false,
      }
    end

    requests.each do |req_hash|
      next unless req_hash['state'] == 'allocated' || req_hash['state'] == 'filled'

      if hosts.include? req_hash['request']['job']['id']
        jobs_to_delete.push(req_hash)
        next
      end

      req_hash['allocated_resources'].each do |vm_name, _i|
        if hosts.include? vm_name['hostname']
          if all_job_resources_accounted_for(req_hash['allocated_resources'], hosts)
            ret_status[vm_name['hostname']] = {
              'ok' => true,
            }
            jobs_to_delete.push(req_hash)
          else
            FloatyLogger.info "When using ABS you must delete all vms that you requested at the same time: Can't delete #{req_hash['request']['job']['id']}: #{hosts} does not include all of #{req_hash['allocated_resources']}"
          end
        end
      end
    end

    response_body = {}

    jobs_to_delete.each do |job|
      req_obj = {
        'job_id' => job['request']['job']['id'],
        'hosts'  => job['allocated_resources'],
      }

      FloatyLogger.info "Deleting #{req_obj}" if verbose

      return_result = conn.post 'return', req_obj.to_json
      req_obj['hosts'].each do |host|
        response_body[host['hostname']] = { 'ok' => true } if return_result.body == 'OK'
      end
    end

    response_body
  end

  # List available VMs in ABS
  def self.list(verbose, url, os_filter = nil)
    conn = Http.get_conn(verbose, url)

    os_list = []

    res = conn.get 'status/platforms/vmpooler'
    if valid_json?(res.body)
      res_body = JSON.parse(res.body)
      if res_body.key?('vmpooler_platforms')
        os_list << '*** VMPOOLER Pools ***'
        if res_body['vmpooler_platforms'].is_a?(String)
          os_list += JSON.parse(res_body['vmpooler_platforms']) # legacy ABS had another JSON string always-be-scheduling/pull/306
        else
          os_list += res_body['vmpooler_platforms']
        end
      end
    end

    res = conn.get 'status/platforms/ondemand_vmpooler'
    if valid_json?(res.body)
      res_body = JSON.parse(res.body)
      if res_body.key?('ondemand_vmpooler_platforms') && res_body['ondemand_vmpooler_platforms'] != '[]'
        os_list << ''
        os_list << '*** VMPOOLER ONDEMAND Pools ***'
        if res_body['ondemand_vmpooler_platforms'].is_a?(String)
          os_list += JSON.parse(res_body['ondemand_vmpooler_platforms']) # legacy ABS had another JSON string always-be-scheduling/pull/306
        else
          os_list += res_body['ondemand_vmpooler_platforms']
        end
      end
    end

    res = conn.get 'status/platforms/nspooler'
    if valid_json?(res.body)
      res_body = JSON.parse(res.body)
      if res_body.key?('nspooler_platforms')
        os_list << ''
        os_list << '*** NSPOOLER Pools ***'
        if res_body['nspooler_platforms'].is_a?(String)
          os_list += JSON.parse(res_body['nspooler_platforms']) # legacy ABS had another JSON string always-be-scheduling/pull/306
        else
          os_list += res_body['nspooler_platforms']
        end
      end
    end

    res = conn.get 'status/platforms/aws'
    if valid_json?(res.body)
      res_body = JSON.parse(res.body)
      if res_body.key?('aws_platforms')
        os_list << ''
        os_list << '*** AWS Pools ***'
        if res_body['aws_platforms'].is_a?(String)
          os_list += JSON.parse(res_body['aws_platforms']) # legacy ABS had another JSON string always-be-scheduling/pull/306
        else
          os_list += res_body['aws_platforms']
        end
      end
    end

    os_list.delete 'ok'

    os_filter ? os_list.select { |i| i[/#{os_filter}/] } : os_list
  end

  # Retrieve an OS from ABS.
  def self.retrieve(verbose, os_types, token, url, user, config, _ondemand = nil)
    #
    # Contents of post must be like:
    #
    # {
    #   "resources": {
    #     "centos-7-i386": 1,
    #     "ubuntu-1404-x86_64": 2
    #   },
    #   "job": {
    #     "id": "12345",
    #     "tags": {
    #       "user": "username",
    #     }
    #   }
    # }

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    saved_job_id = user + "-" + DateTime.now.strftime('%Q')
    vmpooler_config = Utils.get_vmpooler_service_config(config['vmpooler_fallback'])
    req_obj = {
      :resources => os_types,
      :job       => {
        :id   => saved_job_id,
        :tags => {
          :user => user,
        },
      },
      :vm_token => vmpooler_config['token'] # request with this token, on behalf of this user
    }

    if config['priority']
      req_obj[:priority] = if config['priority'] == 'high'
                             1
                           elsif config['priority'] == 'medium'
                             2
                           elsif config['priority'] == 'low'
                             3
                           else
                             config['priority'].to_i
                           end
    end

    FloatyLogger.info "Posting to ABS #{req_obj.to_json}" if verbose

    # os_string = os_type.map { |os, num| Array(os) * num }.flatten.join('+')
    # raise MissingParamError, 'No operating systems provided to obtain.' if os_string.empty?
    FloatyLogger.info "Requesting VMs with job_id: #{saved_job_id}.  Will retry for up to an hour."
    res = conn.post 'request', req_obj.to_json

    retries = 360

    validate_queue_status_response(res.status, res.body, "Initial request", verbose)

    (1..retries).each do |i|
      queue_place, res_body = check_queue(conn, saved_job_id, req_obj, verbose)
      return translated(res_body, saved_job_id) if res_body

      sleep_seconds = 10 if i >= 10
      sleep_seconds = i if i < 10
      FloatyLogger.info "Waiting #{sleep_seconds} seconds to check if ABS request has been filled.  Queue Position: #{queue_place}... (x#{i})"

      sleep(sleep_seconds)
    end
    nil
  end

  #
  # We should fix the ABS API to be more like the vmpooler or nspooler api, but for now
  #
  def self.translated(res_body, job_id)
    vmpooler_formatted_body = {'job_id' => job_id}

    res_body.each do |host|
      if vmpooler_formatted_body[host['type']] && vmpooler_formatted_body[host['type']]['hostname'].class == Array
        vmpooler_formatted_body[host['type']]['hostname'] << host['hostname']
      else
        vmpooler_formatted_body[host['type']] = { 'hostname' => [host['hostname']] }
      end
    end
    vmpooler_formatted_body['ok'] = true

    vmpooler_formatted_body
  end

  def self.check_queue(conn, job_id, req_obj, verbose)
    queue_info_res = conn.get "status/queue/info/#{job_id}"
    if valid_json?(queue_info_res.body)
      queue_info = JSON.parse(queue_info_res.body)
    else
      FloatyLogger.warn "Could not parse the status/queue/info/#{job_id}"
      return [nil, nil]
    end

    res = conn.post 'request', req_obj.to_json
    validate_queue_status_response(res.status, res.body, "Check queue request", verbose)

    unless res.body.empty? || !valid_json?(res.body)
      res_body = JSON.parse(res.body)
      return queue_info['queue_place'], res_body
    end
    [queue_info['queue_place'], nil]
  end

  def self.snapshot(_verbose, _url, _hostname, _token)
    raise NoMethodError, "Can't snapshot with ABS, use '--service vmpooler' (even for vms checked out with ABS)"
  end

  def self.status(verbose, url)
    conn = Http.get_conn(verbose, url)

    res = conn.get 'status'

    res.body == 'OK'
  end

  def self.summary(verbose, url)
    raise NoMethodError, 'summary is not defined for ABS'
  end

  def self.query(verbose, url, job_id)
    # return saved hostnames from the last time list_active was run
    # preventing having to query the API again.
    # This works as long as query is called after list_active
    return @active_hostnames if @active_hostnames && !@active_hostnames.empty?

    # If using the cli query job_id
    conn = Http.get_conn(verbose, url)
    queue_info_res = conn.get "status/queue/info/#{job_id}"
    if valid_json?(queue_info_res.body)
      queue_info = JSON.parse(queue_info_res.body)
    else
      FloatyLogger.warn "Could not parse the status/queue/info/#{job_id}"
    end
    queue_info
  end

  def self.modify(_verbose, _url, _hostname, _token, _modify_hash)
    raise NoMethodError, 'modify is not defined for ABS'
  end

  def self.disk(_verbose, _url, _hostname, _token, _disk)
    raise NoMethodError, 'disk is not defined for ABS'
  end

  def self.revert(_verbose, _url, _hostname, _token, _snapshot_sha)
    raise NoMethodError, 'revert is not defined for ABS'
  end

  # Validate the http code returned during a queue status request.
  #
  # Return a success message that can be displayed if the status code is
  # success, otherwise raise an error.
  def self.validate_queue_status_response(status_code, body, request_name, verbose)
    case status_code
    when 200
      "#{request_name} returned success (Code 200)" if verbose
    when 202
      "#{request_name} returned accepted, processing (Code 202)" if verbose
    when 401
      raise AuthError, "HTTP #{status_code}: The token provided could not authenticate.\n#{body}"
    else
      raise "HTTP #{status_code}: #{request_name} request to ABS failed!\n#{body}"
    end
  end

  def self.valid_json?(json)
    JSON.parse(json)
    return true
  rescue TypeError, JSON::ParserError => e
    return false
  end
end
