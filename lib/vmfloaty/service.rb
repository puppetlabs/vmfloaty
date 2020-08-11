# frozen_string_literal: true

require 'commander/user_interaction'
require 'commander/command'
require 'vmfloaty/utils'
require 'vmfloaty/ssh'

class Service
  attr_reader :config

  def initialize(options, config_hash = {})
    options ||= Commander::Command::Options.new
    @config = Utils.get_service_config config_hash, options
    @service_object = Utils.get_service_object @config['type']
  end

  def method_missing(method_name, *args, &block)
    if @service_object.respond_to?(method_name)
      @service_object.send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, *)
    @service_object.respond_to?(method_name) || super
  end

  def url
    @config['url']
  end

  def type
    @service_object.name
  end

  def user
    unless @config['user']
      Vmfloaty.logger.info "Enter your #{@config['url']} service username:"
      @config['user'] = STDIN.gets.chomp
    end
    @config['user']
  end

  def token
    unless @config['token']
      Vmfloaty.logger.info 'No token found. Retrieving a token...'
      @config['token'] = get_new_token(nil)
    end
    @config['token']
  end

  def get_new_token(verbose)
    username = user
    pass = Commander::UI.password "Enter your #{@config['url']} service password:", '*'
    Auth.get_token(verbose, url, username, pass)
  end

  def delete_token(verbose, token_value = @config['token'])
    username = user
    pass = Commander::UI.password "Enter your #{@config['url']} service password:", '*'
    Auth.delete_token(verbose, url, username, pass, token_value)
  end

  def token_status(verbose, token_value)
    token_value ||= @config['token']
    Auth.token_status(verbose, url, token_value)
  end

  def list(verbose, os_filter = nil)
    @service_object.list verbose, url, os_filter
  end

  def list_active(verbose)
    @service_object.list_active verbose, url, token, user
  end

  def retrieve(verbose, os_types, use_token = true, ondemand = nil)
    Vmfloaty.logger.info 'Requesting a vm without a token...' unless use_token
    token_value = use_token ? token : nil
    @service_object.retrieve verbose, os_types, token_value, url, user, @config, ondemand
  end

  def wait_for_request(verbose, requestid)
    @service_object.wait_for_request verbose, requestid, url
  end

  def ssh(verbose, host_os, use_token = true)
    token_value = nil
    if use_token
      begin
        token_value = token || get_new_token(verbose)
      rescue TokenError => e
        Vmfloaty.logger.error e
        Vmfloaty.logger.info 'Could not get token... requesting vm without a token anyway...'
      end
    end
    Ssh.ssh(verbose, self, host_os, token_value)
  end

  def query(verbose, hostname)
    @service_object.query verbose, url, hostname
  end

  def modify(verbose, hostname, modify_hash)
    @service_object.modify verbose, url, hostname, token, modify_hash
  end

  def delete(verbose, hosts)
    @service_object.delete verbose, url, hosts, token, user
  end

  def status(verbose)
    @service_object.status verbose, url
  end

  def summary(verbose)
    @service_object.summary verbose, url
  end

  def snapshot(verbose, hostname)
    @service_object.snapshot verbose, url, hostname, token
  end

  def revert(verbose, hostname, snapshot_sha)
    @service_object.revert verbose, url, hostname, token, snapshot_sha
  end

  def disk(verbose, hostname, disk)
    @service_object.disk(verbose, url, hostname, token, disk)
  end
end
