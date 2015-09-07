#!/usr/bin/env ruby

require 'rubygems'
require 'commander'
require 'yaml'
require 'vmfloaty/auth'
require 'vmfloaty/http'
require 'vmfloaty/pooler'

class Vmfloaty
  include Commander::Methods

  def run
    program :version, '0.2.0'
    program :description, 'A CLI helper tool for Puppet Labs vmpooler to help you stay afloat'

    config = read_config

    command :get do |c|
      c.syntax = 'floaty get [options]'
      c.summary = 'Gets a vm or vms based on the os flag'
      c.description = ''
      c.example 'Gets 3 vms', 'floaty get --user brian --url http://vmpooler.example.com --os centos,centos,debian'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--os STRING', String, 'Operating systems to retrieve'
      c.action do |args, options|
        token = options.token
        user = options.user ||= config['user']
        url = options.url ||= config['url']
        os_types = options.os
        pass = password "Enter your password please:", '*'

        unless options.token
          token = Auth.get_token(url, user, pass)
        end

        unless os_types.nil?
          Pooler.retrieve(os_types, token, url)
        else
          puts 'You did not provide an OS to get'
        end
      end
    end

    command :list do |c|
      c.syntax = 'floaty list [options]'
      c.summary = 'Shows a list of available vms from the pooler'
      c.description = ''
      c.example 'Filter the list on centos', 'floaty list --filter centos --url http://vmpooler.example.com'
      c.option '--filter STRING', String, 'A filter to apply to the list'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        filter = options.filter
        url = options.url ||= config['url']

        Pooler.list(url, filter)
      end
    end

    command :query do |c|
      c.syntax = 'floaty query [options]'
      c.summary = 'Get information about a given vm'
      c.description = ''
      c.example 'Get information about a sample host', 'floaty query --url http://vmpooler.example.com --host myvmhost.example.com'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to query'
      c.action do |args, options|
        url = options.url ||= config['url']
        hostname = options.hostname

        Pooler.query(url, hostname)
      end
    end

    command :modify do |c|
      c.syntax = 'floaty modify [options]'
      c.summary = 'Modify a vms tags and TTL'
      c.description = ''
      c.example 'description', 'command example'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--lifetime INT', Integer, 'VM TTL (Integer, in hours)'
      c.option '--tags HASH', Hash, 'free-form VM tagging'
      c.action do |args, options|
        url = options.url ||= config['url']
        hostname = options.hostname
        lifetime = options.lifetime
        tags = options.tags
        token = options.token

        Pooler.modify(url, hostname, token, lifetime, tags)
      end
    end

    command :delete do |c|
      c.syntax = 'floaty delete [options]'
      c.summary = 'Schedules the deletion of a host or hosts'
      c.description = ''
      c.example 'Schedules the deletion of a host or hosts', 'floaty delete --hosts myhost1,myhost2 --url http://vmpooler.example.com'
      c.option '--hosts STRING', String, 'Hostname(s) to delete'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        hosts = options.hosts
        url = options.url ||= config['url']

        Pool.delete(url, hosts)
      end
    end

    command :snapshot do |c|
      c.syntax = 'floaty snapshot [options]'
      c.summary = 'Takes a snapshot of a given vm'
      c.description = ''
      c.example 'Takes a snapshot for a given host', 'floaty snapshot --url http://vmpooler.example.com --host myvm.example.com --token a9znth9dn01t416hrguu56ze37t790bl'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        url = options.url ||= config['url']
        hostname = options.hostname
        token = options.token

        Pooler.snapshot(url, hostname, token)
      end
    end

    command :revert do |c|
      c.syntax = 'floaty revert [options]'
      c.summary = 'Reverts a vm to a specified snapshot'
      c.description = ''
      c.example 'Reverts to a snapshot for a given host', 'floaty revert --url http://vmpooler.example.com --host myvm.example.com --token a9znth9dn01t416hrguu56ze37t790bl --snapshot n4eb4kdtp7rwv4x158366vd9jhac8btq'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--snapshot STRING', String, 'SHA of snapshot'
      c.action do |args, options|
        url = options.url ||= config['url']
        hostname = options.hostname
        token = options.token
        snapshot_sha = options.snapshot

        Pooler.revert(url, hostname, token, snapshot_sha)
      end
    end

    command :status do |c|
      c.syntax = 'floaty status [options]'
      c.summary = 'Prints the status of vmpooler'
      c.description = ''
      c.example 'Gets the current vmpooler status', 'floaty status --url http://vmpooler.example.com'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        url = options.url ||= config['url']

        Pooler.status(url)
      end
    end

    command :summary do |c|
      c.syntax = 'floaty summary [options]'
      c.summary = 'Prints the summary of vmpooler'
      c.description = ''
      c.example 'Gets the current day summary of vmpooler', 'floaty summary --url http://vmpooler.example.com'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        url = options.url ||= config['url']

        Pooler.summary(url)
      end
    end

    command :token do |c|
      c.syntax = 'floaty token [get | delete | status]'
      c.summary = 'Retrieves or deletes a token'
      c.description = ''
      c.example '', ''
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        action = args.first
        url = options.url ||= config['url']
        token = options.token
        user = options.user ||= config['user']
        pass = password "Enter your password please:", '*'

        case action
        when "get"
          puts Auth.get_token(url, user, pass)
        when "delete"
          Auth.delete_token(url, user, pass, token)
        when "status"
          Auth.token_status(url, user, pass, token)
        else
          puts "Unknown action: #{action}"
        end
      end
    end

    run!
  end

  def read_config
    conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    conf
  end
end
