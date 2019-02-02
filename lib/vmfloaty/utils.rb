# frozen_string_literal: true

require 'vmfloaty/pooler'
require 'vmfloaty/nonstandard_pooler'

class Utils
  # TODO: Takes the json response body from an HTTP GET
  # request and "pretty prints" it
  def self.standardize_hostnames(response_body)
    # vmpooler response body example when `floaty get` arguments are `ubuntu-1610-x86_64=2 centos-7-x86_64`:
    # {
    #   "ok": true,
    #   "domain": "delivery.mycompany.net",
    #   "ubuntu-1610-x86_64": {
    #     "hostname": ["gdoy8q3nckuob0i", "ctnktsd0u11p9tm"]
    #   },
    #   "centos-7-x86_64": {
    #     "hostname": "dlgietfmgeegry2"
    #   }
    # }

    # nonstandard pooler response body example when `floaty get` arguments are `solaris-11-sparc=2 ubuntu-16.04-power8`:
    # {
    #   "ok": true,
    #   "solaris-10-sparc": {
    #     "hostname": ["sol10-10.delivery.mycompany.net", "sol10-11.delivery.mycompany.net"]
    #   },
    #   "ubuntu-16.04-power8": {
    #     "hostname": "power8-ubuntu1604-6.delivery.mycompany.net"
    #   }
    # }

    unless response_body.delete('ok')
      raise ArgumentError, "Bad GET response passed to format_hosts: #{response_body.to_json}"
    end

    # vmpooler reports the domain separately from the hostname
    domain = response_body.delete('domain')

    result = {}

    response_body.each do |os, value|
      hostnames = Array(value['hostname'])
      if domain
        hostnames.map! {|host| "#{host}.#{domain}"}
      end
      result[os] = hostnames
    end

    result
  end

  def self.format_host_output(hosts)
    hosts.flat_map do |os, names|
      names.map { |name| "- #{name} (#{os})" }
    end.join("\n")
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
      os_arr = arg.split('=')
      if os_arr.size == 1
        # assume they didn't specify an = sign if split returns 1 size
        os_types[os_arr[0]] = 1
      else
        os_types[os_arr[0]] = os_arr[1].to_i
      end
    end
    os_types
  end

  def self.pretty_print_hosts(verbose, service, hostnames = [])
    hostnames = [hostnames] unless hostnames.is_a? Array
    hostnames.each do |hostname|
      begin
        response = service.query(verbose, hostname)
        host_data = response[hostname]

        case service.type
          when 'Pooler'
            tag_pairs = []
            unless host_data['tags'].nil?
              tag_pairs = host_data['tags'].map {|key, value| "#{key}: #{value}"}
            end
            duration = "#{host_data['running']}/#{host_data['lifetime']} hours"
            metadata = [host_data['template'], duration, *tag_pairs]
            puts "- #{hostname}.#{host_data['domain']} (#{metadata.join(", ")})"
          when 'NonstandardPooler'
            line = "- #{host_data['fqdn']} (#{host_data['os_triple']}"
            line += ", #{host_data['hours_left_on_reservation']}h remaining"
            unless host_data['reserved_for_reason'].empty?
              line += ", reason: #{host_data['reserved_for_reason']}"
            end
            line += ')'
            puts line
          else
            raise "Invalid service type #{service.type}"
        end
      rescue => e
        STDERR.puts("Something went wrong while trying to gather information on #{hostname}:")
        STDERR.puts(e)
      end
    end
  end

  def self.pretty_print_status(verbose, service)
    status_response = service.status(verbose)

    case service.type
      when 'Pooler'
        message = status_response['status']['message']
        pools = status_response['pools']
        pools.select! {|_, pool| pool['ready'] < pool['max']} unless verbose

        width = pools.keys.map(&:length).max
        pools.each do |name, pool|
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
        puts message.colorize(status_response['status']['ok'] ? :default : :red)
      when 'NonstandardPooler'
        pools = status_response
        pools.delete 'ok'
        pools.select! {|_, pool| pool['available_hosts'] < pool['total_hosts']} unless verbose

        width = pools.keys.map(&:length).max
        pools.each do |name, pool|
          begin
            max = pool['total_hosts']
            ready = pool['available_hosts']
            pending = pool['pending'] || 0 # not available for nspooler
            missing = max - ready - pending
            char = 'o'
            puts "#{name.ljust(width)} #{(char*ready).green}#{(char*pending).yellow}#{(char*missing).red}"
          rescue => e
            puts "#{name.ljust(width)} #{e.red}"
          end
        end
      else
        raise "Invalid service type #{service.type}"
    end
  end

  # Adapted from ActiveSupport
  def self.strip_heredoc(str)
    min_indent = str.scan(/^[ \t]*(?=\S)/).min
    min_indent_size = min_indent.nil? ? 0 : min_indent.size

    str.gsub(/^[ \t]{#{min_indent_size}}/, '')
  end

  def self.get_service_object(type = '')
    nspooler_strings = ['ns', 'nspooler', 'nonstandard', 'nonstandard_pooler']
    if nspooler_strings.include? type.downcase
      NonstandardPooler
    else
      Pooler
    end
  end

  def self.get_service_config(config, options)
    # The top-level url, user, and token values in the config file are treated as defaults
    service_config = {
        'url' => config['url'],
        'user' => config['user'],
        'token' => config['token'],
        'type' => config['type'] || 'vmpooler'
    }

    if config['services']
      if options.service.nil?
        # If the user did not specify a service name at the command line, but configured services do exist,
        # use the first configured service in the list by default.
        _, values = config['services'].first
        service_config.merge! values
      else
        # If the user provided a service name at the command line, use that service if posible, or fail
        if config['services'][options.service]
          # If the service is configured but some values are missing, use the top-level defaults to fill them in
          service_config.merge! config['services'][options.service]
        else
          raise ArgumentError, "Could not find a configured service named '#{options.service}' in ~/.vmfloaty.yml"
        end
      end
    end

    # Prioritize an explicitly specified url, user, or token if the user provided one
    service_config['url'] = options.url unless options.url.nil?
    service_config['token'] = options.token unless options.token.nil?
    service_config['user'] = options.user unless options.user.nil?

    service_config
  end
end
