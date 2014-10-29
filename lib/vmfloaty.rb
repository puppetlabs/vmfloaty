require 'vmfloaty/cli'
require 'vmfloaty/provision'
require 'vmfloaty/hosts'

class Vmfloaty

  def initialize(env)
    @vmpooler_url = env['VMPOOLER_URL']

    unless @vmpooler_url
      @vmpooler_url = 'http://vcloud.delivery.puppetlabs.net/vm'
    end
  end

  def start
    CLI.start(ARGV)
  end
end
