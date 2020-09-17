# frozen_string_literal: true

require 'vmfloaty/abs'
require 'vmfloaty/nonstandard_pooler'
require 'vmfloaty/pooler'
require 'vmfloaty/conf'

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

    # abs pooler response body example when `floaty get` arguments are :
    # {
    #   "hostname"=>"thin-soutane.delivery.puppetlabs.net",
    #   "type"=>"centos-7.2-tmpfs-x86_64",
    #   "engine"=>"vmpooler"
    # }

    raise ArgumentError, "Bad GET response passed to format_hosts: #{response_body.to_json}" unless response_body.delete('ok')

    # vmpooler reports the domain separately from the hostname
    domain = response_body.delete('domain')

    result = {}

    # ABS has a job_id associated with hosts so pass that along
    abs_job_id = response_body.delete('job_id')
    result['job_id'] = abs_job_id unless abs_job_id.nil?

    filtered_response_body = response_body.reject { |key, _| key == 'request_id' || key == 'ready' }
    filtered_response_body.each do |os, value|
      hostnames = Array(value['hostname'])
      hostnames.map! { |host| "#{host}.#{domain}" } if domain
      result[os] = hostnames
    end

    result
  end

  def self.format_host_output(hosts)
    hosts.flat_map do |os, names|
      # Assume hosts are stored in Arrays and ignore everything else
      names.map { |name| "- #{name} (#{os})" } if names.is_a? Array
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
      os_types[os_arr[0]] = os_arr.size == 1 ? 1 : os_arr[1].to_i
    end
    os_types
  end

  def self.pretty_print_hosts(verbose, service, hostnames = [], print_to_stderr = false, indent = 0)
    fetched_data = self.get_host_data(verbose, service, hostnames)
    fetched_data.each do |hostname, host_data|
      case service.type
      when 'ABS'
        # For ABS, 'hostname' variable is the jobID
        #
        # Create a vmpooler service to query each hostname there so as to get the metadata too

        vmpooler_service = service.clone
        vmpooler_service.silent = true
        vmpooler_service.maybe_use_vmpooler
        puts "- [JobID:#{host_data['request']['job']['id']}] <#{host_data['state']}>"
        host_data['allocated_resources'].each do |vm_name, _i|
          self.pretty_print_hosts(verbose, vmpooler_service, vm_name['hostname'].split('.')[0], print_to_stderr, indent+2)
        end
      when 'Pooler'
        tag_pairs = []
        tag_pairs = host_data['tags'].map { |key, value| "#{key}: #{value}" } unless host_data['tags'].nil?
        duration = "#{host_data['running']}/#{host_data['lifetime']} hours"
        metadata = [host_data['template'], duration, *tag_pairs]
        puts "- #{hostname}.#{host_data['domain']} (#{metadata.join(', ')})".gsub(/^/, ' ' * indent)
      when 'NonstandardPooler'
        line = "- #{host_data['fqdn']} (#{host_data['os_triple']}"
        line += ", #{host_data['hours_left_on_reservation']}h remaining"
        line += ", reason: #{host_data['reserved_for_reason']}" unless host_data['reserved_for_reason'].empty?
        line += ')'
        puts line
      else
        raise "Invalid service type #{service.type}"
      end
    end
  end

  def self.get_host_data(verbose, service, hostnames = [])
    result = {}
    hostnames = [hostnames] unless hostnames.is_a? Array
    hostnames.each do |hostname|
      begin
        response = service.query(verbose, hostname)
        host_data = response[hostname]
        if block_given?
          yield host_data result
        else
          case service.type
          when 'ABS'
            # For ABS, 'hostname' variable is the jobID
            if host_data['state'] == 'allocated' || host_data['state'] == 'filled'
              result[hostname] = host_data
            end
          when 'Pooler'
            result[hostname] = host_data
          when 'NonstandardPooler'
            result[hostname] = host_data
          else
            raise "Invalid service type #{service.type}"
          end
        end
      rescue StandardError => e
        FloatyLogger.error("Something went wrong while trying to gather information on #{hostname}:")
        FloatyLogger.error(e)
      end
    end
    result
  end

  def self.pretty_print_status(verbose, service)
    status_response = service.status(verbose)

    case service.type
    when 'Pooler'
      message = status_response['status']['message']
      pools = status_response['pools']
      pools.select! { |_, pool| pool['ready'] < pool['max'] } unless verbose

      width = pools.keys.map(&:length).max
      pools.each do |name, pool|
        begin
          max = pool['max']
          ready = pool['ready']
          pending = pool['pending']
          missing = max - ready - pending
          char = 'o'
          puts "#{name.ljust(width)} #{(char * ready).green}#{(char * pending).yellow}#{(char * missing).red}"
        rescue StandardError => e
          FloatyLogger.error "#{name.ljust(width)} #{e.red}"
        end
      end
      puts message.colorize(status_response['status']['ok'] ? :default : :red)
    when 'NonstandardPooler'
      pools = status_response
      pools.delete 'ok'
      pools.select! { |_, pool| pool['available_hosts'] < pool['total_hosts'] } unless verbose

      width = pools.keys.map(&:length).max
      pools.each do |name, pool|
        begin
          max = pool['total_hosts']
          ready = pool['available_hosts']
          pending = pool['pending'] || 0 # not available for nspooler
          missing = max - ready - pending
          char = 'o'
          puts "#{name.ljust(width)} #{(char * ready).green}#{(char * pending).yellow}#{(char * missing).red}"
        rescue StandardError => e
          FloatyLogger.error "#{name.ljust(width)} #{e.red}"
        end
      end
    when 'ABS'
      FloatyLogger.error 'ABS Not OK' unless status_response
      puts 'ABS is OK'.green if status_response
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
    abs_strings = %w[abs alwaysbescheduling always_be_scheduling]
    nspooler_strings = %w[ns nspooler nonstandard nonstandard_pooler]
    vmpooler_strings = %w[vmpooler]
    if abs_strings.include? type.downcase
      ABS
    elsif nspooler_strings.include? type.downcase
      NonstandardPooler
    elsif vmpooler_strings.include? type.downcase
      Pooler
    else
      Pooler
    end
  end

  def self.get_service_config(config, options)
    # The top-level url, user, and token values in the config file are treated as defaults
    service_config = {
      'url'   => config['url'],
      'user'  => config['user'],
      'token' => config['token'],
      'type'  => config['type'] || 'vmpooler',
    }

    if config['services']
      if options.service.nil?
        # If the user did not specify a service name at the command line, but configured services do exist,
        # use the first configured service in the list by default.
        _, values = config['services'].first
        service_config.merge! values
      else
        # If the user provided a service name at the command line, use that service if posible, or fail
        raise ArgumentError, "Could not find a configured service named '#{options.service}' in ~/.vmfloaty.yml" unless config['services'][options.service]

        # If the service is configured but some values are missing, use the top-level defaults to fill them in
        service_config.merge! config['services'][options.service]
      end
    # No config file but service is declared on command line
    elsif !config['services'] && options.service
      service_config['type'] = options.service
    end

    # Prioritize an explicitly specified url, user, or token if the user provided one
    service_config['priority'] = options.priority unless options.priority.nil?
    service_config['url'] = options.url unless options.url.nil?
    service_config['token'] = options.token unless options.token.nil?
    service_config['user'] = options.user unless options.user.nil?

    service_config
  end

  # This method gets the vmpooler service configured in ~/.vmfloaty
  def self.get_vmpooler_service_config
    config = Conf.read_config
    # The top-level url, user, and token values in the config file are treated as defaults
    service_config = {
        'url'   => config['url'],
        'user'  => config['user'],
        'token' => config['token'],
        'type'  => 'vmpooler',
    }

    # at a minimum, the url needs to be configured
    if config['services'] && config['services']['vmpooler'] && config['services']['vmpooler']['url']
      # If the service is configured but some values are missing, use the top-level defaults to fill them in
      service_config.merge! config['services']['vmpooler']
    else
      raise ArgumentError, "Could not find a configured service named 'vmpooler' in ~/.vmfloaty.yml use this format:\nservices:\n  vmpooler:\n    url: 'http://vmpooler.com'\n    user: 'superman'\n    token: 'kryptonite'"
    end

    service_config
  end
end
