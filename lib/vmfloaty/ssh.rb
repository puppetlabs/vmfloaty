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

  def self.command_string(verbose, service, host_os, use_token)
    ssh_path = which('ssh')
    raise 'Could not determine path to ssh' unless ssh_path

    os_types = {}
    os_types[host_os] = 1

    response = service.retrieve(verbose, os_types, use_token)
    raise "Could not get vm from #{service.type}:\n #{response}" unless response['ok']

    user = /win/.match?(host_os) ? 'Administrator' : 'root'

    hostname = response[host_os]['hostname']
    hostname = response[host_os]['hostname'][0] if response[host_os]['hostname'].is_a?(Array)
    hostname = "#{hostname}.#{response['domain']}" unless hostname.end_with?('puppetlabs.net')

    "#{ssh_path} #{user}@#{hostname}"
  end

  def self.ssh(verbose, service, host_os, use_token)
    cmd = command_string(verbose, service, host_os, use_token)
    # TODO: Should this respect more ssh settings? Can it be configured
    #       by users ssh config and does this respect those settings?
    Kernel.exec(cmd)
    nil
  end
end
