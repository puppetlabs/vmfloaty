require 'thor'

class CLI < Thor
  desc "get", "Gets a vm"
  def get
    say 'Get a vm here'
  end

  desc "modify", "Modify a vm"
  def modify
    say 'Modify a vm'
  end

  desc "list", "List all active vms"
  def list
    say 'Listing your vms'
  end

  desc "release", "Schedules a vm for deletion"
  def release
    say 'Releases a vm'
  end
end

CLI.start(ARGV)
