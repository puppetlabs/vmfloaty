#!/usr/bin/env ruby

require 'rubygems'
require 'commander'
require 'yaml'
require 'vmfloaty/auth'
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
      c.option '--verbose', 'Enables verbose output'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--os STRING', String, 'Operating systems to retrieve'
      c.option '--notoken', 'Makes a request without a token'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        token = options.token || config['token']
        user = options.user ||= config['user']
        url = options.url ||= config['url']
        os_types = options.os
        no_token = options.notoken

        unless no_token.nil?
          response = Pooler.retrieve(verbose, os_types, token, url)
          puts response
          return
        end

        unless options.token
          pass = password "Enter your password please:", '*'
          token = Auth.get_token(verbose, url, user, pass)
        end

        unless os_types.nil?
          response = Pooler.retrieve(verbose, os_types, token, url)
          puts response
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
      c.option '--verbose', 'Enables verbose output'
      c.option '--filter STRING', String, 'A filter to apply to the list'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        filter = options.filter
        url = options.url ||= config['url']

        os_list = Pooler.list(verbose, url, filter)
        puts os_list
      end
    end

    command :query do |c|
      c.syntax = 'floaty query [options]'
      c.summary = 'Get information about a given vm'
      c.description = ''
      c.example 'Get information about a sample host', 'floaty query --url http://vmpooler.example.com --host myvmhost.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to query'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = options.host

        query = Pooler.query(verbose, url, hostname)
        puts query
      end
    end

    command :modify do |c|
      c.syntax = 'floaty modify [options]'
      c.summary = 'Modify a vms tags and TTL'
      c.description = ''
      c.example 'description', 'command example'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--lifetime INT', Integer, 'VM TTL (Integer, in hours)'
      c.option '--tags HASH', Hash, 'free-form VM tagging'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = options.hostname
        lifetime = options.lifetime
        tags = options.tags
        token = options.token

        res_body = Pooler.modify(verbose, url, hostname, token, lifetime, tags)
        puts res_body
      end
    end

    command :delete do |c|
      c.syntax = 'floaty delete [options]'
      c.summary = 'Schedules the deletion of a host or hosts'
      c.description = ''
      c.example 'Schedules the deletion of a host or hosts', 'floaty delete --hosts myhost1,myhost2 --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--hosts STRING', String, 'Hostname(s) to delete'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        hosts = options.hosts
        url = options.url ||= config['url']

        Pool.delete(verbose, url, hosts)
      end
    end

    command :snapshot do |c|
      c.syntax = 'floaty snapshot [options]'
      c.summary = 'Takes a snapshot of a given vm'
      c.description = ''
      c.example 'Takes a snapshot for a given host', 'floaty snapshot --url http://vmpooler.example.com --host myvm.example.com --token a9znth9dn01t416hrguu56ze37t790bl'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = options.hostname
        token = options.token

        res_body = Pooler.snapshot(verbose, url, hostname, token)
        puts res_body
      end
    end

    command :revert do |c|
      c.syntax = 'floaty revert [options]'
      c.summary = 'Reverts a vm to a specified snapshot'
      c.description = ''
      c.example 'Reverts to a snapshot for a given host', 'floaty revert --url http://vmpooler.example.com --host myvm.example.com --token a9znth9dn01t416hrguu56ze37t790bl --snapshot n4eb4kdtp7rwv4x158366vd9jhac8btq'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--host STRING', String, 'Hostname to modify'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--snapshot STRING', String, 'SHA of snapshot'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = options.hostname
        token = options.token
        snapshot_sha = options.snapshot

        res_body = Pooler.revert(verbose, url, hostname, token, snapshot_sha)
        puts res_body
      end
    end

    command :status do |c|
      c.syntax = 'floaty status [options]'
      c.summary = 'Prints the status of vmpooler'
      c.description = ''
      c.example 'Gets the current vmpooler status', 'floaty status --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']

        status = Pooler.status(verbose, url)
        puts status
      end
    end

    command :summary do |c|
      c.syntax = 'floaty summary [options]'
      c.summary = 'Prints the summary of vmpooler'
      c.description = ''
      c.example 'Gets the current day summary of vmpooler', 'floaty summary --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']

        summary = Pooler.summary(verbose, url)
        puts summary
      end
    end

    command :token do |c|
      c.syntax = 'floaty token [get | delete | status]'
      c.summary = 'Retrieves or deletes a token'
      c.description = ''
      c.example '', ''
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        action = args.first
        url = options.url ||= config['url']
        token = options.token
        user = options.user ||= config['user']
        pass = password "Enter your password please:", '*'

        case action
        when "get"
          puts Auth.get_token(verbose, url, user, pass)
        when "delete"
          Auth.delete_token(verbose, url, user, pass, token)
        when "status"
          Auth.token_status(verbose, url, user, pass, token)
        when nil
          STDERR.puts "No action provided"
        else
          STDERR.puts "Unknown action: #{action}"
        end
      end
    end

    run!
  end

  def read_config
    conf = {}
    begin
      conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    rescue
      STDERR.puts "There was no config file at #{Dir.home}/.vmfloaty.yml"
    end
    conf
  end
end
