require 'logger'

class FloatyLogger < ::Logger
  def self.logger
    @@logger ||= FloatyLogger.new
  end

  def self.info(msg)
    FloatyLogger.logger.info msg
  end

  def self.warn(msg)
    FloatyLogger.logger.warn msg
  end

  def self.error(msg)
    FloatyLogger.logger.error msg
  end

  def self.setlevel=(level)
    level = level.downcase
    if level == "debug"
      self.logger.level = ::Logger::DEBUG
    elsif level == "info"
      self.logger.level = ::Logger::INFO
    elsif level == "error"
      self.logger.level = ::Logger::ERROR
    else
      error("set loglevel to debug, info or error")
    end
  end

  def initialize
    super(STDERR)
    self.level = ::Logger::INFO
    self.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
    end
  end
end
