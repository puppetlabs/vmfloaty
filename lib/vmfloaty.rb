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
          token = Auth.get_token(user, url, pass)
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
        # Do something or c.when_called Floaty::Commands::Query
        filter = options.filter
        url = options.url ||= config['url']

        Pooler.list(url, filter)
      end
    end

    command :query do |c|
      c.syntax = 'floaty query [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Floaty::Commands::Query
      end
    end

    command :modify do |c|
      c.syntax = 'floaty modify [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Floaty::Commands::Modify
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

        Pool.delete(hosts, url)
      end
    end

    command :snapshot do |c|
      c.syntax = 'floaty snapshot [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Floaty::Commands::Snapshot
      end
    end

    command :revert do |c|
      c.syntax = 'floaty revert [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Floaty::Commands::Revert
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

    run!
  end

  def read_config
    conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    conf
  end
end
