class Ssh

  def self.which(cmd)
    # Gets path of executable for given command

    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    return nil
  end

  def self.ssh(verbose, host_os, token, url)
    ssh_path = which("ssh")
    if !ssh_path
      raise "Could not determine path to ssh"
    end
    os_types = {}
    os_types[host_os] = 1

    response = Pooler.retrieve(verbose, os_types, token, url)
    if response["ok"] == true
      if host_os =~ /win/
        user = "Administrator"
      else
        user = "root"
      end

      hostname = "#{response[host_os]["hostname"]}.#{response["domain"]}"
      cmd = "#{ssh_path} #{user}@#{hostname}"

      # TODO: Should this respect more ssh settings? Can it be configured
      #       by users ssh config and does this respect those settings?
      Kernel.exec(cmd)
    else
      raise "Could not get vm from vmpooler:\n #{response}"
    end
    return
  end
end
