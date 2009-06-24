require 'logger'
require 'yaml'
require 'pathname'
require 'extlib/assertions'
require 'extlib/hook'
require 'json'

Pathname.send :alias_method, :/, :+

module Orbited
  
  def self.logger
    return @logger if @logger
    @logger       = Logger.new STDOUT
    @logger.level = Logger::DEBUG
    @logger.progname = "orbited-ruby"
    @logger.info "Started Logging"
    @logger
  end
  
  def self.root
    Pathname.new(File.dirname __FILE__)
  end
  
end
