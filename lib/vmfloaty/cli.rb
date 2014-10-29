require 'thor'
require 'net/http'
require 'uri'
require 'json'

class CLI < Thor
  desc "get <OPERATING SYSTEM,...> [--withpe version]", "Gets a VM"
  option :withpe
  def get(os_list)
    # POST -d os_list vmpooler.company.com/vm

    if options[:withpe]
      say "Get a #{os_list} VM here and provision with PE verison #{options[:withpe]}"
    else
      say "Get a #{os_list} VM here"
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

  desc "release <HOSTNAME>", "Schedules a VM for deletion"
  def release(hostname)
    # HTTP DELETE vmpooler.company.com/vm/#{hostname}
    # { "ok": true }
    say 'Releases a VM'
  end
end
