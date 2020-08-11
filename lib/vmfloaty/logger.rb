require 'logger'

class FloatyLogger < ::Logger
  def initialize
    super(STDERR)
    self.level = ::Logger::INFO
    self.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
    end
  end
end