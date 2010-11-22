# TODO: Implement SSE
# TODO: Implement Streaming
# TODO: CSP protocol verification testing(automated)
require 'eventmachine'
require 'pathname'
require 'uuid'
require 'json'
require 'logger'
require 'base64'
require 'rack'

module CSP
  AsyncResponse = [-1, {}, []].freeze
  
  RequestPrefix = "rp".freeze
  RequestSuffix = "rs".freeze
  Duration      = "du".freeze
  IsStreaming   = "is".freeze
  Interval      = "i" .freeze
  PrebufferSize = "ps".freeze
  Preamble      = "p" .freeze
  BatchPrefix   = "bp".freeze
  BatchSuffix   = "bs".freeze
  SSE           = "se".freeze
  ContentType   = "ct".freeze
  Prebuffer     = "prebuffer".freeze
  SSEId         = "sse_id".freeze
  CometSessionSettings = [RequestPrefix, RequestSuffix, Duration, IsStreaming,
                          Interval, PrebufferSize, Preamble, BatchPrefix, 
                          BatchSuffix, SSE, ContentType, Prebuffer, SSEId].freeze
  
  SessionKey    = "s".freeze
  AckId         = "a".freeze
  Data          = "d".freeze
  
  Handshake = '/handshake'.freeze
  Comet = '/comet'.freeze
  Send = '/send'.freeze
  Close = '/close'.freeze
  Reflect = '/reflect'.freeze
  Static = '/static'.freeze
    
  def self.root
    @root ||= Pathname.new(__FILE__).dirname.expand_path
  end
  
  def self.logger
    @logger ||= begin
      #TODO configurable logging
      logger       = Logger.new STDOUT
      logger.level = Logger::DEBUG
      logger.progname = "rack/csp"
      logger.info "Started Logging"
      logger
    end
  end
end

require CSP.root+'csp/async_request'
require CSP.root+'csp/async_body'
require CSP.root+'csp/packet'
require CSP.root+'csp/session'
require CSP.root+'csp/application'
