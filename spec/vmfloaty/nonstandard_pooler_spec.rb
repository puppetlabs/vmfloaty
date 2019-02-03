# frozen_string_literal: true

require 'spec_helper'
require 'vmfloaty/utils'
require 'vmfloaty/errors'
require 'vmfloaty/nonstandard_pooler'

describe NonstandardPooler do
  before :each do
    @nspooler_url = 'https://nspooler.example.com'
    @post_request_headers = {
      'Accept'          => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent'      => 'Faraday v0.9.2',
      'X-Auth-Token'    => 'token-value',
    }
    @get_request_headers = {
      'Accept'          => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent'      => 'Faraday v0.9.2',
      'X-Auth-Token'    => 'token-value',
    }
    @get_request_headers_notoken = @get_request_headers.tap do |headers|
      headers.delete('X-Auth-Token')
    end
  end

  describe '#list' do
    before :each do
      @status_response_body = <<~BODY
        {
            "ok": true,
            "solaris-10-sparc": {
                "total_hosts": 11,
                "available_hosts": 11
            },
            "ubuntu-16.04-power8": {
                "total_hosts": 10,
                "available_hosts": 10
            },
            "aix-7.2-power": {
                "total_hosts": 5,
                "available_hosts": 4
            }
        }
      BODY
    end

    it 'returns an array with operating systems from the pooler' do
      stub_request(:get, "#{@nspooler_url}/status")
        .to_return(:status => 200, :body => @status_response_body, :headers => {})

      list = NonstandardPooler.list(false, @nspooler_url, nil)
      expect(list).to be_an_instance_of Array
    end

    it 'filters operating systems based on the filter param' do
      stub_request(:get, "#{@nspooler_url}/status")
        .to_return(:status => 200, :body => @status_response_body, :headers => {})

      list = NonstandardPooler.list(false, @nspooler_url, 'aix')
      expect(list).to be_an_instance_of Array
      expect(list.size).to equal 1
    end

    it 'returns nothing if the filter does not match' do
      stub_request(:get, "#{@nspooler_url}/status")
        .to_return(:status => 199, :body => @status_response_body, :headers => {})

      list = NonstandardPooler.list(false, @nspooler_url, 'windows')
      expect(list).to be_an_instance_of Array
      expect(list.size).to equal 0
    end
  end

  describe '#list_active' do
    before :each do
      @token_status_body_active = <<~BODY
        {
          "ok": true,
          "user": "first.last",
          "created": "2017-09-18 01:25:41 +0000",
          "last_accessed": "2017-09-21 19:46:25 +0000",
          "reserved_hosts": ["sol10-9", "sol10-11"]
        }
      BODY
      @token_status_body_empty = <<~BODY
        {
          "ok": true,
          "user": "first.last",
          "created": "2017-09-18 01:25:41 +0000",
          "last_accessed": "2017-09-21 19:46:25 +0000",
          "reserved_hosts": []
        }
      BODY
    end

    it 'prints an output of fqdn, template, and duration' do
      allow(Auth).to receive(:token_status)
        .with(false, @nspooler_url, 'token-value')
        .and_return(JSON.parse(@token_status_body_active))

      list = NonstandardPooler.list_active(false, @nspooler_url, 'token-value')
      expect(list).to eql ['sol10-9', 'sol10-11']
    end
  end

  describe '#retrieve' do
    before :each do
      @retrieve_response_body_single = <<~BODY
        {
          "ok": true,
          "solaris-11-sparc": {
            "hostname": "sol11-4.delivery.puppetlabs.net"
          }
        }
      BODY
      @retrieve_response_body_many = <<~BODY
        {
          "ok": true,
          "solaris-10-sparc": {
            "hostname": [
              "sol10-9.delivery.puppetlabs.net",
              "sol10-10.delivery.puppetlabs.net"
            ]
          },
          "aix-7.1-power": {
            "hostname": "pe-aix-71-ci-acceptance.delivery.puppetlabs.net"
          }
        }
      BODY
    end

    it 'raises an AuthError if the token is invalid' do
      stub_request(:post, "#{@nspooler_url}/host/solaris-11-sparc")
        .with(:headers => @post_request_headers)
        .to_return(:status => 401, :body => '{"ok":false,"reason": "token: token-value does not exist"}', :headers => {})

      vm_hash = { 'solaris-11-sparc' => 1 }
      expect { NonstandardPooler.retrieve(false, vm_hash, 'token-value', @nspooler_url) }.to raise_error(AuthError)
    end

    it 'retrieves a single vm with a token' do
      stub_request(:post, "#{@nspooler_url}/host/solaris-11-sparc")
        .with(:headers => @post_request_headers)
        .to_return(:status => 200, :body => @retrieve_response_body_single, :headers => {})

      vm_hash = { 'solaris-11-sparc' => 1 }
      vm_req = NonstandardPooler.retrieve(false, vm_hash, 'token-value', @nspooler_url)
      expect(vm_req).to be_an_instance_of Hash
      expect(vm_req['ok']).to equal true
      expect(vm_req['solaris-11-sparc']['hostname']).to eq 'sol11-4.delivery.puppetlabs.net'
    end

    it 'retrieves a multiple vms with a token' do
      stub_request(:post, "#{@nspooler_url}/host/aix-7.1-power+solaris-10-sparc+solaris-10-sparc")
        .with(:headers => @post_request_headers)
        .to_return(:status => 200, :body => @retrieve_response_body_many, :headers => {})

      vm_hash = { 'aix-7.1-power' => 1, 'solaris-10-sparc' => 2 }
      vm_req = NonstandardPooler.retrieve(false, vm_hash, 'token-value', @nspooler_url)
      expect(vm_req).to be_an_instance_of Hash
      expect(vm_req['ok']).to equal true
      expect(vm_req['solaris-10-sparc']['hostname']).to be_an_instance_of Array
      expect(vm_req['solaris-10-sparc']['hostname']).to eq ['sol10-9.delivery.puppetlabs.net', 'sol10-10.delivery.puppetlabs.net']
      expect(vm_req['aix-7.1-power']['hostname']).to eq 'pe-aix-71-ci-acceptance.delivery.puppetlabs.net'
    end
  end

  describe '#modify' do
    before :each do
      @modify_response_body_success = '{"ok":true}'
    end

    it 'raises an error if the user tries to modify an unsupported attribute' do
      stub_request(:put, 'https://nspooler.example.com/host/myfakehost')
        .with(:body    => { '{}' => true },
              :headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'token-value' })
        .to_return(:status => 200, :body => '', :headers => {})
      details = { :lifetime => 12 }
      expect { NonstandardPooler.modify(false, @nspooler_url, 'myfakehost', 'token-value', details) }
        .to raise_error(ModifyError)
    end

    it 'modifies the reason of a vm' do
      modify_request_body = { '{"reserved_for_reason":"testing"}' => true }
      stub_request(:put, "#{@nspooler_url}/host/myfakehost")
        .with(:body    => modify_request_body,
              :headers => @post_request_headers)
        .to_return(:status => 200, :body => '{"ok": true}', :headers => {})

      modify_hash = { :reason => 'testing' }
      modify_req = NonstandardPooler.modify(false, @nspooler_url, 'myfakehost', 'token-value', modify_hash)
      expect(modify_req['ok']).to be true
    end
  end

  describe '#status' do
    before :each do
      @status_response_body = '{"capacity":{"current":716,"total":717,"percent": 99.9},"status":{"ok":true,"message":"Battle station fully armed and operational."}}'
      # TODO: make this report stuff like 'broken'
      @status_response_body = <<~BODY
        {
          "ok": true,
          "solaris-10-sparc": {
            "total_hosts": 11,
            "available_hosts": 10
          },
          "ubuntu-16.04-power8": {
            "total_hosts": 10,
            "available_hosts": 10
          },
          "aix-7.2-power": {
            "total_hosts": 5,
            "available_hosts": 4
          }
        }
      BODY
    end

    it 'prints the status' do
      stub_request(:get, "#{@nspooler_url}/status")
        .with(:headers => @get_request_headers)
        .to_return(:status => 200, :body => @status_response_body, :headers => {})

      status = NonstandardPooler.status(false, @nspooler_url)
      expect(status).to be_an_instance_of Hash
    end
  end

  describe '#summary' do
    before :each do
      @status_response_body = <<~BODY
        {
          "ok": true,
          "total": 57,
          "available": 39,
          "in_use": 16,
          "resetting": 2,
          "broken": 0
        }
      BODY
    end

    it 'prints the summary' do
      stub_request(:get, "#{@nspooler_url}/summary")
        .with(:headers => @get_request_headers)
        .to_return(:status => 200, :body => @status_response_body, :headers => {})

      summary = NonstandardPooler.summary(false, @nspooler_url)
      expect(summary).to be_an_instance_of Hash
    end
  end

  describe '#query' do
    before :each do
      @query_response_body = <<~BODY
        {
          "ok": true,
          "sol10-11": {
            "fqdn": "sol10-11.delivery.puppetlabs.net",
            "os_triple": "solaris-10-sparc",
            "reserved_by_user": "first.last",
            "reserved_for_reason": "testing",
            "hours_left_on_reservation": 29.12
          }
        }
      BODY
    end

    it 'makes a query about a vm' do
      stub_request(:get, "#{@nspooler_url}/host/sol10-11")
        .with(:headers => @get_request_headers_notoken)
        .to_return(:status => 200, :body => @query_response_body, :headers => {})

      query_req = NonstandardPooler.query(false, @nspooler_url, 'sol10-11')
      expect(query_req).to be_an_instance_of Hash
    end
  end

  describe '#delete' do
    before :each do
      @delete_response_success = '{"ok": true}'
      @delete_response_failure = '{"ok": false, "failure": "ERROR: fakehost does not exist"}'
    end

    it 'deletes a single existing vm' do
      stub_request(:delete, "#{@nspooler_url}/host/sol11-7")
        .with(:headers => @post_request_headers)
        .to_return(:status => 200, :body => @delete_response_success, :headers => {})

      request = NonstandardPooler.delete(false, @nspooler_url, 'sol11-7', 'token-value')
      expect(request['sol11-7']['ok']).to be true
    end

    it 'does not delete a nonexistant vm' do
      stub_request(:delete, "#{@nspooler_url}/host/fakehost")
        .with(:headers => @post_request_headers)
        .to_return(:status => 401, :body => @delete_response_failure, :headers => {})

      request = NonstandardPooler.delete(false, @nspooler_url, 'fakehost', 'token-value')
      expect(request['fakehost']['ok']).to be false
    end
  end

  describe '#snapshot' do
    it 'logs an error explaining that snapshots are not supported' do
      expect { NonstandardPooler.snapshot(false, @nspooler_url, 'myfakehost', 'token-value') }
        .to raise_error(ModifyError)
    end
  end

  describe '#revert' do
    it 'logs an error explaining that snapshots are not supported' do
      expect { NonstandardPooler.revert(false, @nspooler_url, 'myfakehost', 'token-value', 'snapshot-sha') }
        .to raise_error(ModifyError)
    end
  end

  describe '#disk' do
    it 'logs an error explaining that disk modification is not supported' do
      expect { NonstandardPooler.disk(false, @nspooler_url, 'myfakehost', 'token-value', 'diskname') }
        .to raise_error(ModifyError)
    end
  end
end
