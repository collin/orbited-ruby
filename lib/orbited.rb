require 'logger'
require 'yaml'
require 'pathname'
require 'extlib/assertions'
require 'extlib/hook'
require 'json'
require 'rack'
require 'uuid'
require 'moneta/memory'

Pathname.send :alias_method, :/, :+

module Orbited
  NotFound = [404, {}, []].freeze

  def self.logger
    return @logger if @logger
    @logger       = Logger.new STDOUT
    @logger.level = Logger::DEBUG
    @logger.progname = "orbited-ruby"
    @logger.info "Started Logging"
    @logger
  end
  
  def self.root
    @root ||= Pathname.new(File.dirname __FILE__).expand_path
  end
  
  def self.config
    @config ||= YAML.load( (root/'config.yml') ).merge {
      :tcp_session_storage => Moneta::Memory
    }
  end
  
end
