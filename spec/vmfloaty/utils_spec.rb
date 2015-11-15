require 'spec_helper'
require 'json'
require_relative '../../lib/vmfloaty/utils'

describe Utils do

  describe "#get_hosts" do
    before :each do
      @hostname_hash = "{\"ok\":true,\"debian-7-i386\":{\"hostname\":[\"sc0o4xqtodlul5w\",\"4m4dkhqiufnjmxy\"]},\"debian-7-x86_64\":{\"hostname\":\"zb91y9qbrbf6d3q\"},\"domain\":\"company.com\"}"
      @format_hash = "{\"debian-7-i386\":[\"sc0o4xqtodlul5w\",\"4m4dkhqiufnjmxy\"],\"debian-7-x86_64\":\"zb91y9qbrbf6d3q\",\"domain\":\"company.com\"}"
    end

    it "formats a hostname hash into os, hostnames, and domain name" do

      expect(Utils.format_hosts(JSON.parse(@hostname_hash))).to eq @format_hash
    end
  end
end
