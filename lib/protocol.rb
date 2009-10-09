module Orbited
  # Modules for encoding type of packet encoding
  # Codec must have an identifier (from csp spec)
  # Must have a decode and encode method
  module Codecs
    module PlainText
      Identifier = 0
      def self.echo _; _ end
      alias decode echo
      alias encode echo
    end
  
    module URL
      Identifier = 1

      require 'cgi'
      extend CGI
      extend self

      # use methods from CGI
      alias decode unescape
      alias encode escape
    end
    
    def self.find identifier
      self.constants.find{|codec| codec::Identifier == identifier }
    end
  end
  
  class Packet
    class NoCodec < StandardError; end
    class BadCodec < StandardError; end

    # Codec must be set first
    def initialize(id, codec, data)
      @codec = Codecs.find(codec)
      raise NoCodec unless @codec
      raise BadCodec unless @codec.respond_to?(:decode)
      self.id, self.data = id, data
    end
    
  private
    attr_accessor :id, :data
    
    # data can be nil to indicate close of connection
    def data= data=nil
      @data = codec.decode(data) if data
    end
    
    def data
      outbound_codec.encode(@data) if @data
    end
    
    # http://orbited.org/blog/files/csp.html#3312-packing-encodings
    # A server MUST send packets with PACKET_ENCODING = 1 whenever the PACKET_DATA contains 
    # byte values less than 32 or greater than 126. A server SHOULD use PACKET_ENCODING = 0 
    # when PACKET_DATA contains only byte values between 32 and 126, inclusive.
    PlainTextByteRange = (32..126).freeze
    def outbound_codec
      @data.each_byte do |byte|
       codec = Codecs::URL and break unless PlainTextByteRange.include?(byte)
      end
      codec ||= Codecs::PlainText
    end
    
    def to_json
      [id, outbound_codec::Identifier, data].to_json
    end
    
    def inspect
      "<##{self.class.to_s} to_json>"
    end
  end
  
  class PacketBatch
    def to_s
      "#{batch_prefix}(#{batch})#{batch_suffix}#{sse_id}"
    end
  end
  
  class Session
    class Param
      attr_reader :key, :value
      
      def initialize name, key, default
        @key, @default = key, default
      end
    end

    def self.params
      @parameters ||= []
    end

    def self.param name, key, options={:default => ""}
      parameters << Param.new(name, key, options[:default])
      alias_method name, key             # alias duration du
      delegate key, :to => :params       # delegate access to params
    end    

    # First argument to 'param' is the name of the parameter for humans.
    # Second argument to param is the name of the parameter on the wire.
    param :request_prefix, :rp
    param :request_suffix, :rs
    param :duration, :du, :default => 30
    param :is_streaming, :is, :default => 0 # false
    param :interval, :i, :default => 0
    param :prebuffer_size, :ps, :default => 0
    param :preamble, :p
    param :batch_prefix, :bp
    param :batch_suffix, :bs
    param :gzip_ok, :g
    param :sse, :se
    param :content_type, :ct, :default => "text/html"
# THESE VARIABLES ARE PER_REQUEST
    # NO_CACHE is ignored by server http://orbited.org/blog/files/csp.html#33316-no_cache
    param :session_key, :s
    param :ack_id, :a, :default => -1
    param :data, :d, :default => ""
    
    attr_reader :params
    
    def initialize params
      @params = params
      Session.params.each do |param|
        @params[param.key] ||= param.default
      end
    end
  end
  
  class Request
  end  
end