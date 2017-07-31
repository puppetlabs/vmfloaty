
require 'vmfloaty/pooler'

class Utils
  # TODO: Takes the json response body from an HTTP GET
  # request and "pretty prints" it
  def self.format_hosts(hostname_hash)
    host_hash = {}

    hostname_hash.delete("ok")
    domain = hostname_hash["domain"]
    hostname_hash.each do |type, hosts|
      if type != "domain"
        if hosts["hostname"].kind_of?(Array)
          hosts["hostname"].map!{|host| host + "." + domain }
        else
          hosts["hostname"] = hosts["hostname"] + "." + domain
        end

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

  def self.get_vm_info(hosts, verbose, url)
    vms = {}
    hosts.each do |host|
      vm_info = Pooler.query(verbose, url, host)
      if vm_info['ok']
        vms[host] = {}
        vms[host]['domain'] = vm_info[host]['domain']
        vms[host]['template'] = vm_info[host]['template']
        vms[host]['lifetime'] = vm_info[host]['lifetime']
        vms[host]['running'] = vm_info[host]['running']
        vms[host]['tags'] = vm_info[host]['tags']
      end
    end
    vms
  end

  def self.prettyprint_hosts(hosts, verbose, url)
    puts "Running VMs:"
    vm_info = get_vm_info(hosts, verbose, url)
    vm_info.each do |vm,info|
      domain = info['domain']
      template = info['template']
      lifetime = info['lifetime']
      running = info['running']
      tags = info['tags'] || {}

      tag_pairs = tags.map {|key,value| "#{key}: #{value}" }
      duration = "#{running}/#{lifetime} hours"
      metadata = [template, duration, *tag_pairs]

      puts "- #{vm}.#{domain} (#{metadata.join(", ")})"
    end
  end

  def self.get_all_token_vms(verbose, url, token)
    # get vms with token
    status = Auth.token_status(verbose, url, token)

    vms = status[token]['vms']
    if vms.nil?
      raise "You have no running vms"
    end

    running_vms = vms['running']
    running_vms
  end

  def self.prettyprint_status(status, message, pools, verbose)
    pools.select! {|name,pool| pool['ready'] < pool['max']} if ! verbose

    width = pools.keys.map(&:length).max
    pools.each do |name,pool|
      begin
        max = pool['max']
        ready = pool['ready']
        pending = pool['pending']
        missing = max - ready - pending
        char = 'o'
        puts "#{name.ljust(width)} #{(char*ready).green}#{(char*pending).yellow}#{(char*missing).red}"
      rescue => e
        puts "#{name.ljust(width)} #{e.red}"
      end
    end

    puts
    puts message.colorize(status['status']['ok'] ? :default : :red)
  end

  # Adapted from ActiveSupport
  def self.strip_heredoc(str)
    min_indent = str.scan(/^[ \t]*(?=\S)/).min
    min_indent_size = min_indent.nil? ? 0 : min_indent.size

    str.gsub(/^[ \t]{#{min_indent_size}}/, '')
  end
end
