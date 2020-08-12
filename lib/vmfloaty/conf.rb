# frozen_string_literal: true

require 'yaml'

class Conf
  def self.read_config
    conf = {}
    begin
      conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    rescue StandardError
      FloatyLogger.warn "WARNING: There was no config file at #{Dir.home}/.vmfloaty.yml"
    end
    conf
  end
end
