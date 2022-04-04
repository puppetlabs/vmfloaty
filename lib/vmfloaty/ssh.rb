# frozen_string_literal: true

class Ssh
  def self.which(cmd)
    # Gets path of executable for given command

    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      end
    end
    nil
  end

  def self.command_string(verbose, service, host_os, use_token, ondemand = nil)
    ssh_path = which('ssh')
    raise 'Could not determine path to ssh' unless ssh_path
    os_types = Utils.generate_os_hash([host_os])
    os_types[host_os] = 1

    response = service.retrieve(verbose, os_types, use_token, ondemand)
    raise "Could not get vm from #{service.type}:\n #{response}" unless response['ok']

    user = /win/.match?(host_os) ? 'Administrator' : 'root'

    if ondemand
      requestid = response['request_id']
      service.wait_for_request(verbose, requestid)
      hosts = service.check_ondemandvm(verbose, requestid, service.url)
      if hosts['domain'].nil?
        hostname = hosts[host_os]['hostname']
        hostname = hosts[host_os]['hostname'][0] if hosts[host_os]['hostname'].is_a?(Array)
      else
        # Provides backwards compatibility with VMPooler API v1
        hostname = "#{hosts[host_os]['hostname']}.#{hosts['domain']}"
        hostname = "#{hosts[host_os]['hostname'][0]}.#{hosts['domain']}" if hosts[host_os]['hostname'].is_a?(Array)
      end
    else
      if response['domain'].nil?
        hostname = response[host_os]['hostname']
        hostname = response[host_os]['hostname'][0] if response[host_os]['hostname'].is_a?(Array)
      else
        # Provides backwards compatibility with VMPooler API v1
        hostname = "#{response[host_os]['hostname']}.#{response['domain']}"
        hostname = "#{response[host_os]['hostname'][0]}.#{response['domain']}" if response[host_os]['hostname'].is_a?(Array)
      end
    end

    "#{ssh_path} #{user}@#{hostname}"
  end

  def self.ssh(verbose, service, host_os, use_token, ondemand)
    cmd = command_string(verbose, service, host_os, use_token, ondemand)
    # TODO: Should this respect more ssh settings? Can it be configured
    #       by users ssh config and does this respect those settings?
    Kernel.exec(cmd)
    nil
  end
end
