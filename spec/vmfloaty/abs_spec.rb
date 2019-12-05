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
  end
end
