# frozen_string_literal: true

require 'vmfloaty/errors'
require 'vmfloaty/http'
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

  def self.list_active(verbose, url, _token, user)
    all_jobs = []
    @active_hostnames = {}

    get_active_requests(verbose, url, user).each do |req_hash|
      all_jobs.push(req_hash['request']['job']['id'])
      @active_hostnames[req_hash['request']['job']['id']] = req_hash
    end

    all_jobs
  end

  def self.get_active_requests(verbose, url, user)
    conn = Http.get_conn(verbose, url)
    res = conn.get 'status/queue'
    requests = JSON.parse(res.body)

    ret_val = []

    requests.each do |req|
      next if req == 'null'

      req_hash = JSON.parse(req)

      begin
        next unless user == req_hash['request']['job']['user']

        ret_val.push(req_hash)
      rescue NoMethodError
        Vmfloaty.logger.warn "Warning: couldn't parse line returned from abs/status/queue: "
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

    Vmfloaty.logger.info "Trying to delete hosts #{hosts}" if verbose
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
            Vmfloaty.logger.info "When using ABS you must delete all vms that you requested at the same time: Can't delete #{req_hash['request']['job']['id']}: #{hosts} does not include all of #{req_hash['allocated_resources']}"
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

      Vmfloaty.logger.info "Deleting #{req_obj}" if verbose

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

    res_body = JSON.parse(res.body)
    os_list << '*** VMPOOLER Pools ***'
    os_list += JSON.parse(res_body['vmpooler_platforms'])

    res = conn.get 'status/platforms/ondemand_vmpooler'
    res_body = JSON.parse(res.body)
    unless res_body['ondemand_vmpooler_platforms'] == '[]'
      os_list << ''
      os_list << '*** VMPOOLER ONDEMAND Pools ***'
      os_list += JSON.parse(res_body['ondemand_vmpooler_platforms'])
    end

    res = conn.get 'status/platforms/nspooler'
    res_body = JSON.parse(res.body)
    os_list << ''
    os_list << '*** NSPOOLER Pools ***'
    os_list += JSON.parse(res_body['nspooler_platforms'])

    res = conn.get 'status/platforms/aws'
    res_body = JSON.parse(res.body)
    os_list << ''
    os_list << '*** AWS Pools ***'
    os_list += JSON.parse(res_body['aws_platforms'])

    os_list.delete 'ok'

    os_filter ? os_list.select { |i| i[/#{os_filter}/] } : os_list
  end

  # Retrieve an OS from ABS.
  def self.retrieve(verbose, os_types, token, url, user, options, _ondemand = nil)
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

    saved_job_id = DateTime.now.strftime('%Q')

    req_obj = {
      :resources => os_types,
      :job       => {
        :id   => saved_job_id,
        :tags => {
          :user => user,
        },
      },
    }

    if options['priority']
      req_obj[:priority] = if options['priority'] == 'high'
                             1
                           elsif options['priority'] == 'medium'
                             2
                           elsif options['priority'] == 'low'
                             3
                           else
                             options['priority'].to_i
                           end
    end

    Vmfloaty.logger.info "Posting to ABS #{req_obj.to_json}" if verbose

    # os_string = os_type.map { |os, num| Array(os) * num }.flatten.join('+')
    # raise MissingParamError, 'No operating systems provided to obtain.' if os_string.empty?
    Vmfloaty.logger.info "Requesting VMs with job_id: #{saved_job_id}.  Will retry for up to an hour."
    res = conn.post 'request', req_obj.to_json

    retries = 360

    raise AuthError, "HTTP #{res.status}: The token provided could not authenticate to the pooler.\n#{res_body}" if res.status == 401

    (1..retries).each do |i|
      queue_place, res_body = check_queue(conn, saved_job_id, req_obj)
      return translated(res_body) if res_body

      sleep_seconds = 10 if i >= 10
      sleep_seconds = i if i < 10
      Vmfloaty.logger.info "Waiting #{sleep_seconds} seconds to check if ABS request has been filled.  Queue Position: #{queue_place}... (x#{i})"

      sleep(sleep_seconds)
    end
    nil
  end

  #
  # We should fix the ABS API to be more like the vmpooler or nspooler api, but for now
  #
  def self.translated(res_body)
    vmpooler_formatted_body = {}

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

  def self.check_queue(conn, job_id, req_obj)
    queue_info_res = conn.get "status/queue/info/#{job_id}"
    queue_info = JSON.parse(queue_info_res.body)

    res = conn.post 'request', req_obj.to_json

    unless res.body.empty?
      res_body = JSON.parse(res.body)
      return queue_info['queue_place'], res_body
    end
    [queue_info['queue_place'], nil]
  end

  def self.snapshot(_verbose, _url, _hostname, _token)
    Vmfloaty.logger.info "Can't snapshot with ABS, use '--service vmpooler' (even for vms checked out with ABS)"
  end

  def self.status(verbose, url)
    conn = Http.get_conn(verbose, url)

    res = conn.get 'status'

    res.body == 'OK'
  end

  def self.summary(verbose, url)
    conn = Http.get_conn(verbose, url)

    res = conn.get 'summary'
    JSON.parse(res.body)
  end

  def self.query(verbose, url, hostname)
    return @active_hostnames if @active_hostnames

    Vmfloaty.logger.info "For vmpooler/snapshot information, use '--service vmpooler' (even for vms checked out with ABS)"
    conn = Http.get_conn(verbose, url)

    res = conn.get "host/#{hostname}"
    JSON.parse(res.body)
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
end
