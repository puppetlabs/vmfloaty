# frozen_string_literal: true

require 'yaml'

class Conf
  def self.read_config
    conf = {}
    begin
      conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    rescue StandardError
      # ignore
    end
    conf
  end
end
