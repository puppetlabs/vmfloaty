
require 'vmfloaty/pooler'

class Utils
  # TODO: Takes the json response body from an HTTP GET
  # request and "pretty prints" it
  def self.format_hosts(hostname_hash)
    host_hash = {}

    hostname_hash.delete("ok")
    hostname_hash.each do |type, hosts|
      if type == "domain"
        host_hash[type] = hosts
      else
        host_hash[type] = hosts["hostname"]
      end
    end

    host_hash.to_json
  end

  def self.generate_os_hash(os_args)
    # expects args to look like:
    # ["centos", "debian=5", "windows=1"]

    # Build vm hash where
    #
    #  [operating_system_type1 -> total,
    #   operating_system_type2 -> total,
    #   ...]
    os_types = {}
    os_args.each do |arg|
      os_arr = arg.split("=")
      if os_arr.size == 1
        # assume they didn't specify an = sign if split returns 1 size
        os_types[os_arr[0]] = 1
      else
        os_types[os_arr[0]] = os_arr[1].to_i
      end
    end
    os_types
  end

  def self.prettyprint_hosts(hosts, verbose, url)
    puts "Running VMs:"
    hosts.each do |vm|
      vm_info = Pooler.query(verbose, url, vm)
      if vm_info['ok']
        domain = vm_info[vm]['domain']
        template = vm_info[vm]['template']
        lifetime = vm_info[vm]['lifetime']
        running = vm_info[vm]['running']

        puts "- #{vm}#{domain} (#{running}/#{lifetime} hours)"
      end
    end
  end
end
