# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/vmfloaty/pooler'

describe Pooler do
  before :each do
    @vmpooler_url = 'https://vmpooler.example.com'
  end

  describe '#list' do
    before :each do
      @list_response_body = '["debian-7-i386","debian-7-x86_64","centos-7-x86_64"]'
    end

    it 'returns a hash with operating systems from the pooler' do
      stub_request(:get, "#{@vmpooler_url}/vm").
        to_return(:status => 200, :body => @list_response_body, :headers => {})

      list = Pooler.list(false, @vmpooler_url, nil)
      expect(list).to be_an_instance_of Array
    end

    it 'filters operating systems based on the filter param' do
      stub_request(:get, "#{@vmpooler_url}/vm").
        to_return(:status => 200, :body => @list_response_body, :headers => {})

      list = Pooler.list(false, @vmpooler_url, 'deb')
      expect(list).to be_an_instance_of Array
      expect(list.size).to equal 2
    end

    it 'returns nothing if the filter does not match' do
      stub_request(:get, "#{@vmpooler_url}/vm").
        to_return(:status => 200, :body => @list_response_body, :headers => {})

      list = Pooler.list(false, @vmpooler_url, 'windows')
      expect(list).to be_an_instance_of Array
      expect(list.size).to equal 0
    end
  end

  describe '#retrieve' do
    before :each do
      @retrieve_response_body_single = '{"ok":true,"debian-7-i386":{"hostname":"fq6qlpjlsskycq6"}}'
      @retrieve_response_body_double = '{"ok":true,"debian-7-i386":{"hostname":["sc0o4xqtodlul5w","4m4dkhqiufnjmxy"]},"centos-7-x86_64":{"hostname":"zb91y9qbrbf6d3q"}}'
    end

    it 'raises an AuthError if the token is invalid' do
      stub_request(:post, "#{@vmpooler_url}/vm/debian-7-i386").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 401, :body => '{"ok":false}', :headers => {})

      vm_hash = {}
      vm_hash['debian-7-i386'] = 1
      expect{ Pooler.retrieve(false, vm_hash, 'mytokenfile', @vmpooler_url) }.to raise_error(AuthError)
    end

    it 'retrieves a single vm with a token' do
      stub_request(:post, "#{@vmpooler_url}/vm/debian-7-i386").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @retrieve_response_body_single, :headers => {})

      vm_hash = {}
      vm_hash['debian-7-i386'] = 1
      vm_req = Pooler.retrieve(false, vm_hash, 'mytokenfile', @vmpooler_url)
      expect(vm_req).to be_an_instance_of Hash
      expect(vm_req['ok']).to equal true
      expect(vm_req['debian-7-i386']['hostname']).to eq 'fq6qlpjlsskycq6'
    end

    it 'retrieves a multiple vms with a token' do
      stub_request(:post, "#{@vmpooler_url}/vm/debian-7-i386+debian-7-i386+centos-7-x86_64").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @retrieve_response_body_double, :headers => {})

      vm_hash = {}
      vm_hash['debian-7-i386'] = 2
      vm_hash['centos-7-x86_64'] = 1
      vm_req = Pooler.retrieve(false, vm_hash, 'mytokenfile', @vmpooler_url)
      expect(vm_req).to be_an_instance_of Hash
      expect(vm_req['ok']).to equal true
      expect(vm_req['debian-7-i386']['hostname']).to be_an_instance_of Array
      expect(vm_req['debian-7-i386']['hostname']).to eq %w[sc0o4xqtodlul5w 4m4dkhqiufnjmxy]
      expect(vm_req['centos-7-x86_64']['hostname']).to eq 'zb91y9qbrbf6d3q'
    end
  end

  describe '#modify' do
    before :each do
      @modify_response_body_success = '{"ok":true}'
      @modify_response_body_fail = '{"ok":false}'
    end

    it 'raises a TokenError if token provided is nil' do
      expect{ Pooler.modify(false, @vmpooler_url, 'myfakehost', nil, {}) }.to raise_error(TokenError)
    end

    it 'modifies the TTL of a vm' do
      modify_hash = { :lifetime => 12 }
      stub_request(:put, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6").
        with(:body => { '{"lifetime":12}' => true },
             :headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @modify_response_body_success, :headers => {})

      modify_req = Pooler.modify(false, @vmpooler_url, 'fq6qlpjlsskycq6', 'mytokenfile', modify_hash)
      expect(modify_req['ok']).to be true
    end
  end

  describe '#delete' do
    before :each do
      @delete_response_body_success = '{"ok":true}'
      @delete_response = { 'fq6qlpjlsskycq6' => { 'ok' => true } }
    end

    it 'deletes a specified vm' do
      stub_request(:delete, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @delete_response_body_success, :headers => {})

      expect(Pooler.delete(false, @vmpooler_url, ['fq6qlpjlsskycq6'], 'mytokenfile')).to eq @delete_response
    end

    it 'raises a token error if no token provided' do
      expect{ Pooler.delete(false, @vmpooler_url, ['myfakehost'], nil) }.to raise_error(TokenError)
    end
  end

  describe '#status' do
    before :each do
      #smaller version
      @status_response_body = '{"capacity":{"current":716,"total":717,"percent": 99.9},"status":{"ok":true,"message":"Battle station fully armed and operational."}}'
    end

    it 'prints the status' do
      stub_request(:get, "#{@vmpooler_url}/status").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2' }).
        to_return(:status => 200, :body => @status_response_body, :headers => {})

      status = Pooler.status(false, @vmpooler_url)
      expect(status).to be_an_instance_of Hash
    end
  end

  describe '#summary' do
    before :each do
      @status_response_body = ''

      it 'prints the summary' do
      end
    end
  end

  describe '#query' do
    before :each do
      @query_response_body = '{"ok": true,"fq6qlpjlsskycq6":{"template":"debian-7-x86_64","lifetime": 2,"running": 0.08,"state":"running","snapshots":["n4eb4kdtp7rwv4x158366vd9jhac8btq" ],"domain": "delivery.puppetlabs.net"}}'
    end

    it 'makes a query about a vm' do
      stub_request(:get, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2' }).
        to_return(:status => 200, :body => @query_response_body, :headers => {})

      query_req = Pooler.query(false, @vmpooler_url, 'fq6qlpjlsskycq6')
      expect(query_req).to be_an_instance_of Hash
    end
  end

  describe '#snapshot' do
    before :each do
      @snapshot_response_body = '{"ok":true}'
    end

    it 'makes a snapshot for a single vm' do
      stub_request(:post, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6/snapshot").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @snapshot_response_body, :headers => {})

      snapshot_req = Pooler.snapshot(false, @vmpooler_url, 'fq6qlpjlsskycq6', 'mytokenfile')
      expect(snapshot_req['ok']).to be true
    end
  end

  describe '#revert' do
    before :each do
      @revert_response_body = '{"ok":true}'
    end

    it 'makes a request to revert a vm from a snapshot' do
      stub_request(:post, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6/snapshot/dAfewKNfaweLKNve").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).
        to_return(:status => 200, :body => @revert_response_body, :headers => {})

      revert_req = Pooler.revert(false, @vmpooler_url, 'fq6qlpjlsskycq6', 'mytokenfile', 'dAfewKNfaweLKNve')
      expect(revert_req['ok']).to be true
    end

    it "doesn't make a request to revert a vm if snapshot is not provided" do
      expect{ Pooler.revert(false, @vmpooler_url, 'fq6qlpjlsskycq6', 'mytokenfile', nil) }.to raise_error(RuntimeError, 'Snapshot SHA provided was nil, could not revert fq6qlpjlsskycq6')
    end

    it 'raises a TokenError if no token was provided' do
      expect{ Pooler.revert(false, @vmpooler_url, 'myfakehost', nil, 'shaaaaaaa') }.to raise_error(TokenError)
    end
  end

  describe '#disk' do
    before :each do
      @disk_response_body_success = '{"ok":true}'
      @disk_response_body_fail = '{"ok":false}'
    end

    it 'makes a request to extend disk space of a vm' do
      stub_request(:post, "#{@vmpooler_url}/vm/fq6qlpjlsskycq6/disk/12").
        with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Length' => '0', 'User-Agent' => 'Faraday v0.9.2', 'X-Auth-Token' => 'mytokenfile' }).  to_return(:status => 200, :body => @disk_response_body_success, :headers => {})

      disk_req = Pooler.disk(false, @vmpooler_url, 'fq6qlpjlsskycq6', 'mytokenfile', 12)
      expect(disk_req['ok']).to be true
    end

    it 'raises a TokenError if no token was provided' do
      expect{ Pooler.disk(false, @vmpooler_url, 'myfakehost', nil, 12) }.to raise_error(TokenError)
    end
  end
end
