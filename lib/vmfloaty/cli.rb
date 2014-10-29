require 'thor'
require 'net/http'
require 'uri'
require 'json'

class CLI < Thor
  desc "get <OPERATING SYSTEM,...>", "Gets a VM"
  def get(os_list)
    # HTTP POST -d os_list vmpooler.company.com/vm

    uri = URI.parse("#{$vmpooler_url}/vm/#{os_list.gsub(",","+")}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    response = http.request(request)

    host_res = JSON.parse(response.body)

    puts host_res

    # parse host names/os's and save
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

  desc "release <HOSTNAME,...> [--all]", "Schedules a VM for deletion"
  option :all
  def release(hostname_list=nil)
    # HTTP DELETE vmpooler.company.com/vm/#{hostname}
    # { "ok": true }

    if options[:all]
      # release all hosts managed by vmfloaty
    else
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
end
