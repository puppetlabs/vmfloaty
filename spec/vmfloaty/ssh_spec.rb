# frozen_string_literal: true

require 'spec_helper'
require 'vmfloaty/ssh'

class ServiceStub
  def retrieve(_verbose, os_types, _use_token)
    if os_types.keys[0] == 'abs_host_string'
      return {
        os_types.keys[0] => { 'hostname' => ['abs-hostname.delivery.puppetlabs.net'] },
        'ok' => true
      }
    end

    {
      os_types.keys[0] => { 'hostname' => 'vmpooler-hostname' },
      'domain' => 'delivery.puppetlabs.net',
      'ok' => true
    }
  end

  def type
    return 'abs' if os_types == 'abs_host_string'
    return 'vmpooler' if os_types == 'vmpooler_host_string'
  end
end

describe Ssh do
  before :each do
  end

  it 'gets a hostname string for abs' do
    verbose = false
    service = ServiceStub.new
    host_os = 'abs_host_string'
    use_token = false
    cmd = Ssh.command_string(verbose, service, host_os, use_token)
    expect(cmd).to match(/ssh root@abs-hostname.delivery.puppetlabs.net/)
  end

  it 'gets a hostname string for vmpooler' do
    verbose = false
    service = ServiceStub.new
    host_os = 'vmpooler_host_string'
    use_token = false
    cmd = Ssh.command_string(verbose, service, host_os, use_token)
    expect(cmd).to match(/ssh root@vmpooler-hostname.delivery.puppetlabs.net/)
  end
end
