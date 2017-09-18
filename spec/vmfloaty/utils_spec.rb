require 'spec_helper'
require 'json'
require_relative '../../lib/vmfloaty/utils'

describe Utils do

  describe "#get_hosts" do
    before :each do
      @hostname_hash = "{\"ok\":true,\"debian-7-i386\":{\"hostname\":[\"sc0o4xqtodlul5w\",\"4m4dkhqiufnjmxy\"]},\"debian-7-x86_64\":{\"hostname\":\"zb91y9qbrbf6d3q\"},\"domain\":\"company.com\"}"
      @format_hash = "{\"debian-7-i386\":[\"sc0o4xqtodlul5w.company.com\",\"4m4dkhqiufnjmxy.company.com\"],\"debian-7-x86_64\":\"zb91y9qbrbf6d3q.company.com\"}"
    end

    it "formats a hostname hash into os, hostnames, and domain name" do

      expect(Utils.format_hosts(JSON.parse(@hostname_hash))).to eq @format_hash
    end
  end

  describe "#get_service_from_config" do
    before :each do
      @default_config = {
          "url" => "http://default.url",
          "user" => "first.last.default",
          "token" => "default-token",
      }
      @services_config = {
          "services" => {
              "vm" => {
                  "url" => "http://vmpooler.url",
                  "user" => "first.last.vmpooler",
                  "token" => "vmpooler-token"
              },
              "ns" => {
                  "url" => "http://nspooler.url",
                  "user" => "first.last.nspooler",
                  "token" => "nspooler-token"
              }
          }
      }
    end

    it "returns the first service configured under 'services' as the default if available" do
      config = @default_config.merge @services_config
      expect(Utils.get_service_from_config(config)).to include @services_config['services']['vm']
    end

    it "uses top-level service config values as defaults when service values are missing" do
      config = {"services" => { "vm" => {}}}
      config.merge! @default_config
      expect(Utils.get_service_from_config(config, 'vm')).to include @default_config
    end

    it "allows selection by configured service key" do
      config = @default_config.merge @services_config
      expect(Utils.get_service_from_config(config, 'ns')).to include @services_config['services']['ns']
    end

    it "fills in missing values in configured services with the defaults" do
      config = @default_config.merge @services_config
      config["services"]['vm'].delete 'url'
      expect(Utils.get_service_from_config(config, 'vm')['url']).to eq 'http://default.url'
    end

    it "returns an empty hash if passed a service name that hasn't been configured" do
      config = @default_config.merge @services_config
      expect(Utils.get_service_from_config(config, 'nil')).to eq({})
    end
  end

  describe "#generate_os_hash" do
    before :each do
      @host_hash = {"centos"=>1, "debian"=>5, "windows"=>1}
    end

    it "takes an array of os arguments and returns a formatted hash" do
      host_arg = ["centos", "debian=5", "windows=1"]
      expect(Utils.generate_os_hash(host_arg)).to eq @host_hash
    end

    it "returns an empty hash if there are no arguments provided" do
      host_arg = []
      expect(Utils.generate_os_hash(host_arg)).to be_empty
    end
  end

  describe '#prettyprint_hosts' do
    let(:host_without_tags) { 'mcpy42eqjxli9g2' }
    let(:host_with_tags)    { 'aiydvzpg23r415q' }
    let(:url)               { 'http://pooler.example.com' }

    let(:host_info_with_tags) do
      {
        host_with_tags => {
          "template" => "redhat-7-x86_64",
          "lifetime" => 48,
          "running"  => 7.67,
          "tags"     => {
            "user" => "bob",
            "role" => "agent"
          },
          "domain" => "delivery.puppetlabs.net"
        }
      }
    end

    let(:host_info_without_tags) do
      {
        host_without_tags => {
          "template" => "ubuntu-1604-x86_64",
          "lifetime" => 12,
          "running"  => 9.66,
          "domain"   => "delivery.puppetlabs.net"
        }
      }
    end

    let(:output_with_tags)    { "- #{host_with_tags}.delivery.puppetlabs.net (redhat-7-x86_64, 7.67/48 hours, user: bob, role: agent)" }
    let(:output_without_tags) { "- #{host_without_tags}.delivery.puppetlabs.net (ubuntu-1604-x86_64, 9.66/12 hours)" }

    it 'prints an output with host fqdn, template and duration info' do
      allow(Utils).to receive(:get_vm_info).
        with(host_without_tags, false, url).
        and_return(host_info_without_tags)

      expect(Utils).to receive(:puts).with("Running VMs:")
      expect(Utils).to receive(:puts).with(output_without_tags)

      Utils.prettyprint_hosts(host_without_tags, false, url)
    end

    it 'prints an output with host fqdn, template, duration info, and tags when supplied' do
      allow(Utils).to receive(:get_vm_info).
        with(host_with_tags, false, url).
        and_return(host_info_with_tags)

      expect(Utils).to receive(:puts).with("Running VMs:")
      expect(Utils).to receive(:puts).with(output_with_tags)

      Utils.prettyprint_hosts(host_with_tags, false, url)
    end
  end
end
