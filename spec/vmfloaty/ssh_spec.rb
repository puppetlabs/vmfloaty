# frozen_string_literal: true

require 'spec_helper'
require 'vmfloaty/ssh'

class ServiceStub
  def retrieve(_verbose, os_types, _use_token, ondemand)
    if os_types.keys[0] == 'abs_host_string'
      return {
        os_types.keys[0] => { 'hostname' => ['abs-hostname.delivery.puppetlabs.net'] },
        'ok' => true
      }

    elsif os_types.keys[0] == 'vmpooler_api_v2_host_string'
      return {
        os_types.keys[0] => { 'hostname' => ['vmpooler-v2-hostname.delivery.puppetlabs.net'] },
        'ok' => true
      }

    else
      return {
        os_types.keys[0] => { 'hostname' => 'vmpooler-v1-hostname' },
        'domain' => 'delivery.puppetlabs.net',
        'ok' => true
      }
    end
  end

  def type
    return 'abs' if os_types == 'abs_host_string'
    return 'vmpooler' if os_types == 'vmpooler_api_v1_host_string' || os_types == 'vmpooler_api_v2_host_string'
  end

  def wait_for_request(verbose, requestid)
    return true
  end
end

describe Ssh do
  before :each do
  end

  context "for pooled requests" do
    it 'gets a hostname string for abs' do
      verbose = false
      service = ServiceStub.new
      host_os = 'abs_host_string'
      use_token = false
      cmd = Ssh.command_string(verbose, service, host_os, use_token)
      expect(cmd).to match(/ssh root@abs-hostname.delivery.puppetlabs.net/)
    end

    it 'gets a hostname string for vmpooler api v1' do
      verbose = true
      service = ServiceStub.new
      host_os = 'vmpooler_api_v1_host_string'
      use_token = false
      cmd = Ssh.command_string(verbose, service, host_os, use_token)
      expect(cmd).to match(/ssh root@vmpooler-v1-hostname.delivery.puppetlabs.net/)
    end

    it 'gets a hostname string for vmpooler api v2' do
      verbose = false
      service = ServiceStub.new
      host_os = 'vmpooler_api_v2_host_string'
      use_token = false
      cmd = Ssh.command_string(verbose, service, host_os, use_token)
      expect(cmd).to match(/ssh root@vmpooler-v2-hostname.delivery.puppetlabs.net/)
    end
  end

  context "for ondemand requests" do
    let(:service) { ServiceStub.new }
    let(:url) { 'http://pooler.example.com' }

    it 'gets a hostname string for abs' do
      verbose = false
      host_os = 'abs_host_string'
      use_token = false
      ondemand = true
      response = {'abs_host_string' => { 'hostname' => ['abs-hostname.delivery.puppetlabs.net']}}
      allow(service).to receive(:url)
      allow(service).to receive(:check_ondemandvm).and_return(response)
      cmd = Ssh.command_string(verbose, service, host_os, use_token, ondemand)
      expect(cmd).to match(/ssh root@abs-hostname.delivery.puppetlabs.net/)
    end

    it 'gets a hostname string for abs' do
      verbose = false
      host_os = 'vmpooler_api_v1_host_string'
      use_token = false
      ondemand = true
      response = {'vmpooler_api_v1_host_string' => { 'hostname' => ['vmpooler_api_v1_host_string.delivery.puppetlabs.net']}}
      allow(service).to receive(:url)
      allow(service).to receive(:check_ondemandvm).and_return(response)
      cmd = Ssh.command_string(verbose, service, host_os, use_token, ondemand)
      expect(cmd).to match(/ssh root@vmpooler_api_v1_host_string.delivery.puppetlabs.net/)
    end

    it 'gets a hostname string for abs' do
      verbose = false
      host_os = 'vmpooler_api_v2_host_string'
      use_token = false
      ondemand = true
      response = {'vmpooler_api_v2_host_string' => { 'hostname' => ['vmpooler_api_v2_host_string.delivery.puppetlabs.net']}}
      allow(service).to receive(:url)
      allow(service).to receive(:check_ondemandvm).and_return(response)
      cmd = Ssh.command_string(verbose, service, host_os, use_token, ondemand)
      expect(cmd).to match(/ssh root@vmpooler_api_v2_host_string.delivery.puppetlabs.net/)
    end
  end
end
