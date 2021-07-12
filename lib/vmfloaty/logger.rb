# frozen_string_literal: true

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
    case level
    when 'debug'
      logger.level = ::Logger::DEBUG
    when 'info'
      logger.level = ::Logger::INFO
    when 'error'
      logger.level = ::Logger::ERROR
    else
      error('set loglevel to debug, info or error')
    end
  end

  def initialize
    super($stderr)
    self.level = ::Logger::INFO
    self.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end
  end
end
