#!/usr/bin/env ruby

require 'rubygems'
require 'commander'
require 'pp'
require 'vmfloaty/auth'
require 'vmfloaty/pooler'
require 'vmfloaty/version'
require 'vmfloaty/conf'
require 'vmfloaty/utils'
require 'vmfloaty/ssh'

class Vmfloaty
  include Commander::Methods

  def run
    program :version, Version.get
    program :description, 'A CLI helper tool for Puppet Labs vmpooler to help you stay afloat'

    config = Conf.read_config

    command :get do |c|
      c.syntax = 'floaty get os_type1=x ox_type2=y ...'
      c.summary = 'Gets a vm or vms based on the os flag'
      c.description = ''
      c.example 'Gets a few vms', 'floaty get centos=3 debian --user brian --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--notoken', 'Makes a request without a token'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        token = options.token || config['token']
        user = options.user ||= config['user']
        url = options.url ||= config['url']
        no_token = options.notoken

        if args.empty?
          STDERR.puts "No operating systems provided to obtain. See `floaty get --help` for more information on how to get VMs."
          exit 1
        end

        os_types = Utils.generate_os_hash(args)

        unless os_types.empty?
          if no_token
            begin
              response = Pooler.retrieve(verbose, os_types, nil, url)
            rescue MissingParamError
              STDERR.puts e
              STDERR.puts "See `floaty get --help` for more information on how to get VMs."
            rescue AuthError => e
              STDERR.puts e
              exit 1
            end
            puts Utils.format_hosts(response)
            exit 0
          else
            unless token
              puts "No token found. Retrieving a token..."
              if !user
                STDERR.puts "You did not provide a user to authenticate to vmpooler with"
                exit 1
              end
              pass = password "Enter your password please:", '*'
              begin
                token = Auth.get_token(verbose, url, user, pass)
              rescue TokenError => e
                STDERR.puts e
                exit 1
              end

              puts "\nToken retrieved!"
              puts token
            end

            begin
              response = Pooler.retrieve(verbose, os_types, token, url)
            rescue MissingParamError
              STDERR.puts e
              STDERR.puts "See `floaty get --help` for more information on how to get VMs."
            rescue AuthError => e
              STDERR.puts e
              exit 1
            end
            puts Utils.format_hosts(response)
            exit 0
          end
        else
          STDERR.puts "No operating systems provided to obtain. See `floaty get --help` for more information on how to get VMs."
          exit 1
        end
      end
    end

    command :list do |c|
      c.syntax = 'floaty list [options]'
      c.summary = 'Shows a list of available vms from the pooler'
      c.description = ''
      c.example 'Filter the list on centos', 'floaty list centos --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--active', 'Prints information about active vms for a given token'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        filter = args[0]
        url = options.url ||= config['url']
        token = options.token || config['token']
        active = options.active

        if active
          # list active vms
          begin
            status = Auth.token_status(verbose, url, token)
          rescue TokenError => e
            STDERR.puts e
            exit 1
          end

          # print vms
          vms = status[token]['vms']
          if vms.nil?
            STDERR.puts "You have no running vms"
            exit 0
          end

          running_vms = vms['running']

          if ! running_vms.nil?
            Utils.prettyprint_hosts(running_vms, verbose, url)
          end
        else
          # list available vms from pooler
          os_list = Pooler.list(verbose, url, filter)
          puts os_list
        end
      end
    end

    command :query do |c|
      c.syntax = 'floaty query [hostname] [options]'
      c.summary = 'Get information about a given vm'
      c.description = ''
      c.example 'Get information about a sample host', 'floaty query hostname --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = args[0]

        query_req = Pooler.query(verbose, url, hostname)
        pp query_req
      end
    end

    command :modify do |c|
      c.syntax = 'floaty modify [hostname] [options]'
      c.summary = 'Modify a vms tags, TTL, and disk space'
      c.description = ''
      c.example 'Modifies myhost1 to have a TTL of 12 hours and adds a custom tag', 'floaty modify myhost1 --lifetime 12 --url https://myurl --token mytokenstring --tags \'{"tag":"myvalue"}\''
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--lifetime INT', Integer, 'VM TTL (Integer, in hours)'
      c.option '--disk INT', Integer, 'Increases VM disk space (Integer, in gb)'
      c.option '--tags STRING', String, 'free-form VM tagging (json)'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = args[0]
        lifetime = options.lifetime
        disk = options.disk
        tags = JSON.parse(options.tags) if options.tags
        token = options.token || config['token']

        if lifetime || tags
          modify_req = Pooler.modify(verbose, url, hostname, token, lifetime, tags)

          if modify_req["ok"]
            puts "Successfully modified vm #{hostname}."
          else
            STDERR.puts "Could not modify given host #{hostname} at #{url}."
            puts modify_req
            exit 1
          end
        end

        if disk
          disk_req = Pooler.disk(verbose, url, hostname, token, disk)
          if disk_req["ok"]
            puts "Successfully updated disk space of vm #{hostname}."
          else
            STDERR.puts "Could not modify given host #{hostname} at #{url}."
            puts disk_req
            exit 1
          end
        else
        end
      end
    end

    command :delete do |c|
      c.syntax = 'floaty delete [hostname,...]'
      c.summary = 'Schedules the deletion of a host or hosts'
      c.description = ''
      c.example 'Schedules the deletion of a host or hosts', 'floaty delete myhost1,myhost2 --url http://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--all', 'Deletes all vms acquired by a token'
      c.option '-f', 'Does not prompt user when deleting all vms'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        hostnames = args[0]
        token = options.token || config['token']
        url = options.url ||= config['url']
        delete_all = options.all
        force = options.f

        if delete_all
          # get vms with token
          begin
            status = Auth.token_status(verbose, url, token)
          rescue TokenError => e
            STDERR.puts e
            exit 1
          end

          # print vms
          vms = status[token]['vms']
          if vms.nil?
            STDERR.puts "You have no running vms"
            exit 0
          end

          running_vms = vms['running']

          if ! running_vms.nil?
            Utils.prettyprint_hosts(running_vms, verbose, url)
            # query y/n
            puts

            if force
              ans = true
            else
              ans = agree("Delete all VMs associated with token #{token}? [y/N]")
            end

            if ans
              # delete vms
              puts "Scheduling all vms for for deletion"
              response = Pooler.delete(verbose, url, running_vms, token)
              response.each do |host,vals|
                if vals['ok'] == false
                  STDERR.puts "There was a problem with your request for vm #{host}."
                  STDERR.puts vals
                end
              end
            end
          end

          exit 0
        end

        if hostnames.nil?
          STDERR.puts "You did not provide any hosts to delete"
          exit 1
        else
          hosts = hostnames.split(',')
          Pooler.delete(verbose, url, hosts, token)
          exit 0
        end
      end
    end

    command :snapshot do |c|
      c.syntax = 'floaty snapshot [hostname] [options]'
      c.summary = 'Takes a snapshot of a given vm'
      c.description = ''
      c.example 'Takes a snapshot for a given host', 'floaty snapshot myvm.example.com --url http://vmpooler.example.com --token a9znth9dn01t416hrguu56ze37t790bl'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = args[0]
        token = options.token ||= config['token']

        snapshot_req = Pooler.snapshot(verbose, url, hostname, token)
        pp snapshot_req
      end
    end

    command :revert do |c|
      c.syntax = 'floaty revert [hostname] [snapshot] [options]'
      c.summary = 'Reverts a vm to a specified snapshot'
      c.description = ''
      c.example 'Reverts to a snapshot for a given host', 'floaty revert myvm.example.com n4eb4kdtp7rwv4x158366vd9jhac8btq --url http://vmpooler.example.com --token a9znth9dn01t416hrguu56ze37t790bl'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--snapshot STRING', String, 'SHA of snapshot'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        hostname = args[0]
        token = options.token || config['token']
        snapshot_sha = args[1] || options.snapshot

        if args[1] && options.snapshot
          STDERR.puts "Two snapshot arguments were given....using snapshot #{snapshot_sha}"
        end

        revert_req = Pooler.revert(verbose, url, hostname, token, snapshot_sha)
        pp revert_req
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
        pp status
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
        pp summary
      end
    end

    command :token do |c|
      c.syntax = 'floaty token [get | delete | status] [token]'
      c.summary = 'Retrieves or deletes a token'
      c.description = ''
      c.example 'Gets a token from the pooler', 'floaty token get'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        action = args.first
        url = options.url ||= config['url']
        token = args[1] ||= options.token ||= config['token']
        user = options.user ||= config['user']

        case action
        when "get"
          pass = password "Enter your password please:", '*'
          begin
            token = Auth.get_token(verbose, url, user, pass)
          rescue TokenError => e
            STDERR.puts e
            exit 1
          end
          puts token
          exit 0
        when "delete"
          pass = password "Enter your password please:", '*'
          begin
            result = Auth.delete_token(verbose, url, user, pass, token)
          rescue TokenError => e
            STDERR.puts e
            exit 1
          end
          puts result
          exit 0
        when "status"
          begin
            status = Auth.token_status(verbose, url, token)
          rescue TokenError => e
            STDERR.puts e
            exit 1
          end
          puts status
          exit 0
        when nil
          STDERR.puts "No action provided"
        else
          STDERR.puts "Unknown action: #{action}"
        end
      end
    end

    command :ssh do |c|
      c.syntax = 'floaty ssh os_type'
      c.summary = 'Grabs a single vm and sshs into it'
      c.description = ''
      c.example 'SSHs into a centos vm', 'floaty ssh centos7 --url https://vmpooler.example.com'
      c.option '--verbose', 'Enables verbose output'
      c.option '--url STRING', String, 'URL of vmpooler'
      c.option '--user STRING', String, 'User to authenticate with'
      c.option '--token STRING', String, 'Token for vmpooler'
      c.option '--notoken', 'Makes a request without a token'
      c.action do |args, options|
        verbose = options.verbose || config['verbose']
        url = options.url ||= config['url']
        token = options.token ||= config['token']
        user = options.user ||= config['user']
        no_token = options.notoken

        if args.empty?
          STDERR.puts "No operating systems provided to obtain. See `floaty ssh --help` for more information on how to get VMs."
          exit 1
        end

        host_os = args.first

        if !no_token && !token
          puts "No token found. Retrieving a token..."
          if !user
            STDERR.puts "You did not provide a user to authenticate to vmpooler with"
            exit 1
          end
          pass = password "Enter your password please:", '*'
          begin
            token = Auth.get_token(verbose, url, user, pass)
          rescue TokenError => e
            STDERR.puts e
            STDERR.puts 'Could not get token...requesting vm without a token anyway...'
          else
            puts "\nToken retrieved!"
            puts token
          end
        end

        Ssh.ssh(verbose, host_os, token, url)
        exit 0
      end
    end

    run!
  end
end
