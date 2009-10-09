# Do not require rubygems.
# http://tomayko.com/writings/require-rubygems-antipattern
require 'logger'
require 'yaml'
require 'base64'
require 'pathname'
require 'extlib/assertions'
require 'extlib/hook'
require 'json'
require 'rack'
require 'uuid'
require 'moneta'
require 'moneta/memory'
require 'eventmachine'
require 'rack/router'



module Orbited
  def self.logger
    @logger ||= begin
      @logger       = Logger.new STDOUT
      @logger.level = Logger::DEBUG
      @logger.progname = "orbited-ruby"
      @logger.info "Started Logging"
      @logger
    end
  end
  
  def self.root
    @root ||= Pathname.new(File.dirname __FILE__).expand_path
  end
  
  def self.config
    @config ||= { :tcp_session_storage => Moneta::Memory }
  end
end

# Hint: column orinted selection
require Orbited.root+'ext/rack'
require Orbited.root+'orbited/packet_batch'
require Orbited.root+'orbited/middleware'
require Orbited.root+'orbited/protocol'
require Orbited.root+'orbited/routes'
require Orbited.root+'orbited/codecs'
require Orbited.root+'orbited/packet'
require Orbited.root+'orbited/session_key'
require Orbited.root+'orbited/sessions_controller'
