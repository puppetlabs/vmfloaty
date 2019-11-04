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

  @@active_hostnames = Hash.new

  def self.list_active(verbose, url, _token, user)
    all_jobs = Array.new()
    @@active_hostnames = Hash.new

    self.get_active_requests(verbose, url, user).each do |reqHash|
      all_jobs.push(reqHash['request']['job']['id'])
      @@active_hostnames[reqHash['request']['job']['id']] = reqHash
    end

    all_jobs
  end

  def self.get_active_requests verbose, url, user
    conn = Http.get_conn(verbose, url)
    res = conn.get 'status/queue'
    requests = JSON.parse(res.body)

    retVal = []
    requests.each do |req|
      reqHash = JSON.parse(req)
      next unless user == reqHash['request']['job']['user']
      retVal.push(reqHash)
    end

    retVal
  end

  def self.all_job_resources_accounted_for(allocated_resources, hosts)
    allocated_host_list = allocated_resources.map {|ar| ar["hostname"] }
    return (allocated_host_list-hosts).empty?
  end

  def self.delete(verbose, url, hosts, token, user)
    # In ABS terms, this is a "returned" host.
    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    puts "Trying to delete hosts #{hosts}" if verbose
    requests = self.get_active_requests(verbose, url, user)

    jobs_to_delete = []

    requests.each do |reqHash|
      if reqHash['state'] == 'allocated' || reqHash['state'] == 'filled'
        reqHash['allocated_resources'].each do |vm_name, i|
          if hosts.include? vm_name["hostname"]
            if (all_job_resources_accounted_for(job['allocated_resources'], hosts))
              jobs_to_delete.push(reqHash)
            else
              puts "Can't delete #{job_id}: #{hosts} does not include all of #{job['allocated_resources']}"
            end
          end
        end
      end
    end

    response_body = {}

    jobs_to_delete.each do |job|
      reqObj = {
        'job_id': job['request']['job']['id'],
        'hosts': job['allocated_resources'],
      }

      puts "Deleting #{reqObj}" if verbose

      res = conn.post 'api/v2/return', reqObj.to_json
      response_body[job_id] = res_body
    end

    return response_body
  end


  # List available VMs in ABS
  def self.list(verbose, url, os_filter = nil)
    conn = Http.get_conn(verbose, url)

    os_list = []

    res = conn.get 'status/platforms/vmpooler'

    res_body = JSON.parse(res.body)
    os_list << '*** VMPOOLER Pools ***'
    os_list += JSON.parse(res_body['vmpooler_platforms'])

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
  def self.retrieve(verbose, os_types, token, url, user)
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
    #       "user": "jenkins",
    #       "jenkins_build_url": "https://jenkins/job/platform_puppet_intn-van-sys_master"
    #     }
    #   }
    # }

    conn = Http.get_conn(verbose, url)
    conn.headers['X-AUTH-TOKEN'] = token if token

    saved_job_id = Time.now.to_i

    reqObj = {
      :resources => os_types,
      :job       => {
        :id   => saved_job_id,
        :tags => {
          :user       => user,
          :url_string => "floaty://#{user}/#{saved_job_id}",
        },
      },
    }

    # os_string = os_type.map { |os, num| Array(os) * num }.flatten.join('+')
    # raise MissingParamError, 'No operating systems provided to obtain.' if os_string.empty?
    puts "Requesting VMs with job_id: #{saved_job_id}.  Will retry for up to an hour."
    res = conn.post 'api/v2/request', reqObj.to_json

    i = 0
    retries = 360

    raise AuthError, "HTTP #{res.status}: The token provided could not authenticate to the pooler.\n#{res_body}" if res.status == 401

    (1..retries).each do |i|
      queue_place, res_body = check_queue(conn, saved_job_id, reqObj)
      return translated(res_body) if res_body

      puts "Waiting 10 seconds to check if ABS request has been filled.  Queue Position: #{queue_place}... (x#{i})"
      sleep(10)
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

  def self.check_queue(conn, job_id, reqObj)
    queue_info_res = conn.get "/status/queue/info/#{job_id}"
    queue_info = JSON.parse(queue_info_res.body)

    res = conn.post 'api/v2/request', reqObj.to_json

    unless res.body.empty?
      res_body = JSON.parse(res.body)
      return queue_info['queue_place'], res_body
    end
    [queue_info['queue_place'], nil]
  end

  def self.snapshot(verbose, url, hostname, token)
    puts "Can't snapshot with ABS, use '--service vmpooler' (even for vms checked out with ABS)"
  end

  def self.status(verbose, url)
    conn = Http.get_conn(verbose, url)

    res = conn.get '/status'
    JSON.parse(res.body)
  end

  def self.summary(verbose, url)
    conn = Http.get_conn(verbose, url)

    res = conn.get '/summary'
    JSON.parse(res.body)
  end

  def self.query(verbose, url, hostname)
    return @@active_hostnames if @@active_hostnames
    puts "For vmpooler/snapshot information, use '--service vmpooler' (even for vms checked out with ABS)"
    conn = Http.get_conn(verbose, url)

    res = conn.get "host/#{hostname}"
    JSON.parse(res.body)
  end
end
