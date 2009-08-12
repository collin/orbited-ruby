require 'rubygems'
require 'pp'
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

class Pathname
  alias / +
  def req path
    require self/path
  end
end

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
    @root ||= Pathname.new(File.dirname __FILE__).expand_path
  end
  
  def self.config
    @config ||= { :tcp_session_storage => Moneta::Memory }
  end
  
end


Orbited.root.instance_eval do
  (self/'ext').instance_eval do 
    req 'integer'
    req 'rack'
  end
  
  req 'headers'
  
  (self/'session').instance_eval do
    req 'fake_tcp_transport'
    req 'proxy'
    req 'tcp_close'
    req 'tcp_open'
    req 'tcp_key'
    req 'tcp_option'
    req 'tcp_ping'
    req 'tcp_connection_resource'
    req 'tcp_resource'
  end
  
  (self/'transport').instance_eval do
    req 'deferrable_body'
    req 'packet' 
    req 'abstract'
    req 'xhr_streaming'
    req 'html_file'
    req 'sse'
    req 'long_polling'
    req 'polling'
    req 'transport'
  end
  
  req 'middleware'
end

