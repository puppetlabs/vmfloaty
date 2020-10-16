# frozen_string_literal: true

require 'spec_helper'
require 'vmfloaty/utils'
require 'vmfloaty/errors'
require 'vmfloaty/abs'

describe ABS do
  before :each do
  end

  describe '#list' do
    it 'skips empty platforms and lists aws' do
      stub_request(:get, "http://foo/api/v2/status/platforms/vmpooler").
          to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://foo/api/v2/status/platforms/ondemand_vmpooler").
          to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://foo/api/v2/status/platforms/nspooler").
          to_return(:status => 200, :body => "", :headers => {})
      body = '{
                "aws_platforms": [
                  "amazon-6-x86_64",
                  "amazon-7-x86_64",
                  "amazon-7-arm64",
                  "centos-7-x86-64-west",
                  "redhat-8-arm64"
                ]
              }'
      stub_request(:get, "http://foo/api/v2/status/platforms/aws").
          to_return(:status => 200, :body => body, :headers => {})


      results = ABS.list(false, "http://foo")

      expect(results).to include("amazon-6-x86_64", "amazon-7-x86_64", "amazon-7-arm64", "centos-7-x86-64-west", "redhat-8-arm64")
    end
    it 'legacy JSON string, prior to PR 306' do
      stub_request(:get, "http://foo/api/v2/status/platforms/vmpooler").
          to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://foo/api/v2/status/platforms/ondemand_vmpooler").
          to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://foo/api/v2/status/platforms/nspooler").
          to_return(:status => 200, :body => "", :headers => {})
      body = '{
          "aws_platforms": "[\"amazon-6-x86_64\",\"amazon-7-x86_64\",\"amazon-7-arm64\",\"centos-7-x86-64-west\",\"redhat-8-arm64\"]"
      }'
      stub_request(:get, "http://foo/api/v2/status/platforms/aws").
          to_return(:status => 200, :body => body, :headers => {})

      results = ABS.list(false, "http://foo")

      expect(results).to include("amazon-6-x86_64", "amazon-7-x86_64", "amazon-7-arm64", "centos-7-x86-64-west", "redhat-8-arm64")
    end
  end

  describe '#format' do
    it 'returns an hash formatted like a vmpooler return, plus the job_id' do
      job_id = "generated_by_floaty_12345"
      abs_formatted_response = [
        { 'hostname' => 'aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64', 'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaab.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64', 'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaac.delivery.puppetlabs.net', 'type' => 'ubuntu-7.2-x86_64', 'engine' => 'vmpooler' },
      ]

      vmpooler_formatted_response = ABS.translated(abs_formatted_response, job_id)

      vmpooler_formatted_compare = {
        'centos-7.2-x86_64' => {},
        'ubuntu-7.2-x86_64' => {},
      }

      vmpooler_formatted_compare['centos-7.2-x86_64']['hostname'] = ['aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'aaaaaaaaaaaaaab.delivery.puppetlabs.net']
      vmpooler_formatted_compare['ubuntu-7.2-x86_64']['hostname'] = ['aaaaaaaaaaaaaac.delivery.puppetlabs.net']

      vmpooler_formatted_compare['ok'] = true

      vmpooler_formatted_compare['job_id'] = job_id

      expect(vmpooler_formatted_response).to eq(vmpooler_formatted_compare)
      vmpooler_formatted_response.delete('ok')
      vmpooler_formatted_compare.delete('ok')
      expect(vmpooler_formatted_response).to eq(vmpooler_formatted_compare)
    end

    it 'won\'t delete a job if not all vms are listed' do
      hosts = ['host1']
      allocated_resources = [
        {
          'hostname' => 'host1',
        },
        {
          'hostname' => 'host2',
        },
      ]
      expect(ABS.all_job_resources_accounted_for(allocated_resources, hosts)).to eq(false)

      hosts = ['host1', 'host2']
      allocated_resources = [
        {
          'hostname' => 'host1',
        },
        {
          'hostname' => 'host2',
        },
      ]
      expect(ABS.all_job_resources_accounted_for(allocated_resources, hosts)).to eq(true)
    end

    before :each do
      @abs_url = 'https://abs.example.com'
    end

    describe '#test_abs_status_queue_endpoint' do
      before :each do
        # rubocop:disable Layout/LineLength
        @active_requests_response = '
        [
          { "state":"allocated","last_processed":"2019-12-16 23:00:34 +0000","allocated_resources":[{"hostname":"take-this.delivery.puppetlabs.net","type":"win-2012r2-x86_64","engine":"vmpooler"}],"audit_log":{"2019-12-13 16:45:29 +0000":"Allocated take-this.delivery.puppetlabs.net for job 1576255517241"},"request":{"resources":{"win-2012r2-x86_64":1},"job":{"id":"1576255517241","tags":{"user":"test-user"},"user":"test-user","time-received":1576255519},"priority":1}},
          "null",
          {"state":"allocated","last_processed":"2019-12-16 23:00:34 +0000","allocated_resources":[{"hostname":"not-this.delivery.puppetlabs.net","type":"win-2012r2-x86_64","engine":"vmpooler"}],"audit_log":{"2019-12-13 16:46:14 +0000":"Allocated not-this.delivery.puppetlabs.net for job 1576255565159"},"request":{"resources":{"win-2012r2-x86_64":1},"job":{"id":"1576255565159","tags":{"user":"not-test-user"},"user":"not-test-user","time-received":1576255566},"priority":1}}
        ]'
        # rubocop:enable Layout/LineLength
        @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
        @test_user = 'test-user'
      end

      it 'will skip a line with a null value returned from abs' do
        stub_request(:get, 'https://abs.example.com/api/v2/status/queue')
          .to_return(:status => 200, :body => @active_requests_response, :headers => {})

        ret = ABS.get_active_requests(false, @abs_url, @test_user)

        expect(ret[0]).to include(
          'allocated_resources' => [{
            'hostname' => 'take-this.delivery.puppetlabs.net',
            'type'     => 'win-2012r2-x86_64',
            'engine'   => 'vmpooler',
          }],
        )
      end
    end

    describe '#test_abs_delete_jobid' do
      before :each do
        # rubocop:disable Layout/LineLength
        @active_requests_response = '
        [
          { "state":"allocated", "last_processed":"2020-01-17 22:29:13 +0000", "allocated_resources":[{"hostname":"craggy-chord.delivery.puppetlabs.net", "type":"centos-7-x86_64", "engine":"vmpooler"}, {"hostname":"visible-revival.delivery.puppetlabs.net", "type":"centos-7-x86_64", "engine":"vmpooler"}], "audit_log":{"2020-01-17 22:28:45 +0000":"Allocated craggy-chord.delivery.puppetlabs.net, visible-revival.delivery.puppetlabs.net for job 1579300120799"}, "request":{"resources":{"centos-7-x86_64":2}, "job":{"id":"1579300120799", "tags":{"user":"test-user"}, "user":"test-user", "time-received":1579300120}, "priority":3}}
        ]'
        @return_request = { '{"job_id":"1579300120799","hosts":{"hostname":"craggy-chord.delivery.puppetlabs.net","type":"centos-7-x86_64","engine":"vmpooler"},{"hostname":"visible-revival.delivery.puppetlabs.net","type":"centos-7-x86_64","engine":"vmpooler"}}'=>true }
        # rubocop:enable Layout/LineLength
        @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
        @test_user = 'test-user'
        # Job ID
        @hosts = ['1579300120799']
      end

      it 'will delete the whole job' do
        stub_request(:get, 'https://abs.example.com/api/v2/status/queue')
          .to_return(:status => 200, :body => @active_requests_response, :headers => {})
        stub_request(:post, 'https://abs.example.com/api/v2/return')
          .with(:body => @return_request)
          .to_return(:status => 200, :body => 'OK', :headers => {})

        ret = ABS.delete(false, @abs_url, @hosts, @token, @test_user)

        expect(ret).to include(
          'craggy-chord.delivery.puppetlabs.net' => { 'ok'=>true }, 'visible-revival.delivery.puppetlabs.net' => { 'ok'=>true },
        )
      end
    end
  end
end
