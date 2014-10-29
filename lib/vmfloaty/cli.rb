require 'thor'
require 'net/http'
require 'uri'
require 'json'

class CLI < Thor
  desc "get <OPERATING SYSTEM,...> [--withpe version]", "Gets a VM"
  option :withpe
  def get(os_list)
    # HTTP POST -d os_list vmpooler.company.com/vm

    uri = URI.parse("#{$vmpooler_url}/vm/#{os_list.gsub(",","+")}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    response = http.request(request)

    host_res = JSON.parse(response.body)

    puts host_res

    if options[:withpe]
      # say "Get a #{os_list} VM here and provision with PE verison #{options[:withpe]}"
    else
      # ?
    end
  end

  desc "modify <HOSTNAME>", "Modify a VM"
  def modify(hostname)
    say 'Modify a vm'
  end

  desc "status", "List status of all active VMs"
  def status
    say 'List of active VMs'
  end

  desc "list [PATTERN]", "List all open VMs"
  def list(pattern=nil)
    # HTTP GET vmpooler.company.com/vm
    uri = URI.parse("#{$vmpooler_url}/vm")
    response = Net::HTTP.get_response(uri)
    host_res = JSON.parse(response.body)

    if pattern
      # Filtering VMs based on pattern
      hosts = host_res.select { |i| i[/#{pattern}/] }
    else
      hosts = host_res
    end

    puts hosts
  end

  desc "release [HOSTNAME,...]", "Schedules a VM for deletion"
  def release(hostname_list)
    # HTTP DELETE vmpooler.company.com/vm/#{hostname}
    # { "ok": true }

    hostname_arr = hostname_list.split(',')

    hostname_arr.each do |hostname|
      say "Releasing host #{hostname}..."
      uri = URI.parse("#{$vmpooler_url}/vm/#{hostname}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Delete.new(uri.request_uri)
      response = http.request(request)
      res = JSON.parse(response.body)

      puts res
    end
  end
end
