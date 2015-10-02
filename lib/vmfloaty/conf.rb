require 'yaml'

class Conf

  def self.read_config
    conf = {}
    begin
      conf = YAML.load_file("#{Dir.home}/.vmfloaty.yml")
    rescue
      STDERR.puts "WARNING: There was no config file at #{Dir.home}/.vmfloaty.yml"
    end
    conf
  end
end
