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
      stub_request(:get, 'http://foo/api/v2/status/platforms/vmpooler')
        .to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://foo/api/v2/status/platforms/ondemand_vmpooler')
        .to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://foo/api/v2/status/platforms/nspooler')
        .to_return(status: 200, body: '', headers: {})
      body = '{
                "aws_platforms": [
                  "amazon-6-x86_64",
                  "amazon-7-x86_64",
                  "amazon-7-arm64",
                  "centos-7-x86-64-west",
                  "redhat-8-arm64"
                ]
              }'
      stub_request(:get, 'http://foo/api/v2/status/platforms/aws')
        .to_return(status: 200, body: body, headers: {})

      results = ABS.list(false, 'http://foo')

      expect(results).to include('amazon-6-x86_64', 'amazon-7-x86_64', 'amazon-7-arm64', 'centos-7-x86-64-west',
                                 'redhat-8-arm64')
    end
    it 'legacy JSON string, prior to PR 306' do
      stub_request(:get, 'http://foo/api/v2/status/platforms/vmpooler')
        .to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://foo/api/v2/status/platforms/ondemand_vmpooler')
        .to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://foo/api/v2/status/platforms/nspooler')
        .to_return(status: 200, body: '', headers: {})
      body = '{
          "aws_platforms": "[\"amazon-6-x86_64\",\"amazon-7-x86_64\",\"amazon-7-arm64\",\"centos-7-x86-64-west\",\"redhat-8-arm64\"]"
      }'
      stub_request(:get, 'http://foo/api/v2/status/platforms/aws')
        .to_return(status: 200, body: body, headers: {})

      results = ABS.list(false, 'http://foo')

      expect(results).to include('amazon-6-x86_64', 'amazon-7-x86_64', 'amazon-7-arm64', 'centos-7-x86-64-west',
                                 'redhat-8-arm64')
    end
  end

  describe '#validate_queue_status_response' do
    it 'accepts 200 and 202' do
      expect { ABS.validate_queue_status_response(200, '', 'Check queue request', false) }.not_to raise_error
      expect { ABS.validate_queue_status_response(202, '', 'Check queue request', false) }.not_to raise_error
    end

    it 'does not raise for 502 and 503 so the queue is polled again' do
      expect { ABS.validate_queue_status_response(502, 'Bad Gateway', 'Check queue request', false) }.not_to raise_error
      expect { ABS.validate_queue_status_response(503, 'Service Unavailable', 'Check queue request', false) }
        .not_to raise_error
    end

    it 'says that ABS is not available when verbose' do
      message = ABS.validate_queue_status_response(503, '', 'Check queue request', true)

      expect(message).to include('503', 'will try again')
    end

    it 'raises for 404 with the body of the response' do
      expect { ABS.validate_queue_status_response(404, 'Resources were not available', 'Initial request', false) }
        .to raise_error(RuntimeError, /HTTP 404: Initial request request to ABS failed!\nResources were not available/)
    end

    it 'raises for other errors such as 422 and 500' do
      [422, 500].each do |code|
        expect { ABS.validate_queue_status_response(code, '{"ok":false}', 'Initial request', false) }
          .to raise_error(RuntimeError, /HTTP #{code}/)
      end
    end

    it 'raises AuthError for 401' do
      expect { ABS.validate_queue_status_response(401, '', 'Initial request', false) }
        .to raise_error(AuthError)
    end
  end

  describe '#check_queue' do
    let(:conn) { Http.get_conn(false, 'https://abs.example.com/api/v2/') }
    let(:req_obj) { { 'resources' => { 'centos-7-x86_64' => 1 }, 'job' => { 'id' => '1' } } }

    it 'returns the body for a 503 so the caller keeps polling' do
      stub_request(:post, 'https://abs.example.com/api/v2/request').to_return(status: 503, body: 'Service Unavailable')

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq('Service Unavailable')
    end

    it 'returns the body as text for a 503 whose body is a JSON object' do
      stub_request(:post, 'https://abs.example.com/api/v2/request')
        .to_return(status: 503, body: '{"error":"Service Unavailable"}')

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq('{"error":"Service Unavailable"}')
    end

    it 'returns the body as text for a 502 whose body is a JSON array' do
      stub_request(:post, 'https://abs.example.com/api/v2/request').to_return(status: 502, body: '[]')

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq('[]')
    end

    it 'returns an empty string for a 503 with no body' do
      stub_request(:post, 'https://abs.example.com/api/v2/request').to_return(status: 503, body: '')

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq('')
    end

    it 'still parses a JSON body of a 202' do
      stub_request(:post, 'https://abs.example.com/api/v2/request').to_return(status: 202, body: '{"a":1}')

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq('a' => 1)
    end

    it 'raises for a 404 instead of returning its body' do
      stub_request(:post, 'https://abs.example.com/api/v2/request').to_return(status: 404, body: 'gone')

      expect { ABS.check_queue(conn, '1', req_obj, false) }.to raise_error(RuntimeError, /HTTP 404/)
    end

    it 'returns the hosts once ABS answers 200' do
      stub_request(:post, 'https://abs.example.com/api/v2/request')
        .to_return(status: 200, body: '[{"hostname":"h1","type":"centos-7-x86_64","engine":"vmpooler"}]')

      hosts = [{ 'hostname' => 'h1', 'type' => 'centos-7-x86_64', 'engine' => 'vmpooler' }]

      expect(ABS.check_queue(conn, '1', req_obj, false)).to eq(hosts)
    end
  end

  describe '#generate_job_id' do
    it 'is the user, the milliseconds and a random suffix' do
      expect(ABS.generate_job_id('tester')).to match(/\Atester-\d{13}-[0-9a-f]{8}\z/)
    end

    it 'differs between calls in the same millisecond' do
      now = DateTime.now
      allow(DateTime).to receive(:now).and_return(now)

      ids = Array.new(50) { ABS.generate_job_id('tester') }

      expect(ids.uniq.length).to eq(50)
    end
  end

  describe '#retrieve' do
    let(:url) { 'https://abs.example.com/api/v2' }
    let(:os_types) { { 'centos-7-x86_64' => 1 } }
    let(:hosts_body) { '[{"hostname":"h1","type":"centos-7-x86_64","engine":"vmpooler"}]' }

    before { allow(ABS).to receive(:sleep) }

    def retrieve(continue = nil)
      ABS.retrieve(false, os_types, 'token', url, 'tester', {}, nil, continue)
    end

    it 'keeps polling through a 503 with a JSON object body and returns the hosts' do
      stub_request(:post, "#{url}/request").to_return(
        { status: 202, body: '' },
        { status: 503, body: '{"error":"Service Unavailable"}' },
        { status: 502, body: 'Bad Gateway' },
        { status: 200, body: hosts_body }
      )

      result = retrieve

      expect(result['ok']).to be(true)
      expect(result['centos-7-x86_64']['hostname']).to eq(['h1'])
      expect(ABS).to have_received(:sleep).twice
    end

    it 'keeps polling when the initial request gets a 503' do
      stub_request(:post, "#{url}/request").to_return(
        { status: 503, body: 'Service Unavailable' },
        { status: 200, body: hosts_body }
      )

      expect(retrieve['ok']).to be(true)
    end

    it 'fails on a 404 while polling' do
      stub_request(:post, "#{url}/request").to_return({ status: 202, body: '' }, { status: 404, body: 'gone' })

      expect { retrieve }.to raise_error(RuntimeError, /HTTP 404/)
    end

    it 'sends the same generated job_id on every poll' do
      stub_request(:post, "#{url}/request").to_return(
        { status: 202, body: '' }, { status: 503, body: '{}' }, { status: 200, body: hosts_body }
      )

      result = retrieve

      ids = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.map { |s| JSON.parse(s.body)['job']['id'] }
      expect(ids.uniq.length).to eq(1)
      expect(ids.first).to match(/\Atester-\d{13}-[0-9a-f]{8}\z/)
      expect(result['job_id']).to eq(ids.first)
    end

    it 'uses the job_id given with --continue unchanged' do
      stub_request(:post, "#{url}/request").to_return({ status: 202, body: '' }, { status: 200, body: hosts_body })

      expect(retrieve('tester-1234567890123-deadbeef')['job_id']).to eq('tester-1234567890123-deadbeef')
    end
  end

  describe '#format' do
    it 'returns an hash formatted like a vmpooler return, plus the job_id' do
      job_id = 'generated_by_floaty_12345'
      abs_formatted_response = [
        { 'hostname' => 'aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64',
          'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaab.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64',
          'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaac.delivery.puppetlabs.net', 'type' => 'ubuntu-7.2-x86_64',
          'engine' => 'vmpooler' }
      ]

      vmpooler_formatted_response = ABS.translated(abs_formatted_response, job_id)

      vmpooler_formatted_compare = {
        'centos-7.2-x86_64' => {},
        'ubuntu-7.2-x86_64' => {}
      }

      vmpooler_formatted_compare['centos-7.2-x86_64']['hostname'] =
        ['aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'aaaaaaaaaaaaaab.delivery.puppetlabs.net']
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
          'hostname' => 'host1'
        },
        {
          'hostname' => 'host2'
        }
      ]
      expect(ABS.all_job_resources_accounted_for(allocated_resources, hosts)).to eq(false)

      hosts = %w[host1 host2]
      allocated_resources = [
        {
          'hostname' => 'host1'
        },
        {
          'hostname' => 'host2'
        }
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
          .to_return(status: 200, body: @active_requests_response, headers: {})

        ret = ABS.get_active_requests(false, @abs_url, @test_user)

        expect(ret[0]).to include(
          'allocated_resources' => [{
            'hostname' => 'take-this.delivery.puppetlabs.net',
            'type' => 'win-2012r2-x86_64',
            'engine' => 'vmpooler'
          }]
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
        @return_request = {
          "job_id" => "1579300120799",
          "hosts" => [{"hostname"=>"craggy-chord.delivery.puppetlabs.net","type"=>"centos-7-x86_64","engine"=>"vmpooler"},
                      {"hostname"=>"visible-revival.delivery.puppetlabs.net","type"=>"centos-7-x86_64","engine"=>"vmpooler"}]
        }
        # rubocop:enable Layout/LineLength
        @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
        @test_user = 'test-user'
        # Job ID
        @hosts = ['1579300120799']
      end

      it 'will delete the whole job' do
        stub_request(:get, 'https://abs.example.com/api/v2/status/queue')
          .to_return(status: 200, body: @active_requests_response, headers: {})
        stub_request(:post, 'https://abs.example.com/api/v2/return')
          .with(headers: get_headers(content_type: 'application/x-www-form-urlencoded', token: @token), body: @return_request.to_json)
          .to_return(status: 200, body: 'OK', headers: {})

        ret = ABS.delete(false, @abs_url, @hosts, @token, @test_user)

        expect(ret).to include(
          'craggy-chord.delivery.puppetlabs.net' => { 'ok' => true }, 'visible-revival.delivery.puppetlabs.net' => { 'ok' => true }
        )
      end
    end
  end
end
