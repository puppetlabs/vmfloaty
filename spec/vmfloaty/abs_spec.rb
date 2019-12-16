# frozen_string_literal: true

require 'spec_helper'
require 'vmfloaty/utils'
require 'vmfloaty/errors'
require 'vmfloaty/abs'

describe ABS do
  before :each do
  end

  describe '#format' do
    it 'returns an hash formatted like a vmpooler return' do
      abs_formatted_response = [
        { 'hostname' => 'aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64', 'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaab.delivery.puppetlabs.net', 'type' => 'centos-7.2-x86_64', 'engine' => 'vmpooler' },
        { 'hostname' => 'aaaaaaaaaaaaaac.delivery.puppetlabs.net', 'type' => 'ubuntu-7.2-x86_64', 'engine' => 'vmpooler' },
      ]

      vmpooler_formatted_response = ABS.translated(abs_formatted_response)

      vmpooler_formatted_compare = {
        'centos-7.2-x86_64' => {},
        'ubuntu-7.2-x86_64' => {},
      }

      vmpooler_formatted_compare['centos-7.2-x86_64']['hostname'] = ['aaaaaaaaaaaaaaa.delivery.puppetlabs.net', 'aaaaaaaaaaaaaab.delivery.puppetlabs.net']
      vmpooler_formatted_compare['ubuntu-7.2-x86_64']['hostname'] = ['aaaaaaaaaaaaaac.delivery.puppetlabs.net']

      vmpooler_formatted_compare['ok'] = true

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
        # rubocop:disable Metrics/LineLength
        @active_requests_response = '
        [
          "{ \"state\":\"allocated\",\"last_processed\":\"2019-12-16 23:00:34 +0000\",\"allocated_resources\":[{\"hostname\":\"take-this.delivery.puppetlabs.net\",\"type\":\"win-2012r2-x86_64\",\"engine\":\"vmpooler\"}],\"audit_log\":{\"2019-12-13 16:45:29 +0000\":\"Allocated take-this.delivery.puppetlabs.net for job 1576255517241\"},\"request\":{\"resources\":{\"win-2012r2-x86_64\":1},\"job\":{\"id\":\"1576255517241\",\"tags\":{\"user\":\"test-user\"},\"user\":\"test-user\",\"time-received\":1576255519},\"priority\":1}}",
          "null",
          "{\"state\":\"allocated\",\"last_processed\":\"2019-12-16 23:00:34 +0000\",\"allocated_resources\":[{\"hostname\":\"not-this.delivery.puppetlabs.net\",\"type\":\"win-2012r2-x86_64\",\"engine\":\"vmpooler\"}],\"audit_log\":{\"2019-12-13 16:46:14 +0000\":\"Allocated not-this.delivery.puppetlabs.net for job 1576255565159\"},\"request\":{\"resources\":{\"win-2012r2-x86_64\":1},\"job\":{\"id\":\"1576255565159\",\"tags\":{\"user\":\"not-test-user\"},\"user\":\"not-test-user\",\"time-received\":1576255566},\"priority\":1}}"
        ]'
        # rubocop:enable Metrics/LineLength
        @token = 'utpg2i2xswor6h8ttjhu3d47z53yy47y'
        @test_user = 'test-user'
      end

      it 'will skip a line with a null value returned from abs' do
        stub_request(:get, 'https://abs.example.com/status/queue')
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
  end
end
