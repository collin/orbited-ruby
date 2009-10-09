module Orbited
  class CSPSocket
    class Param
      attr_reader :key, :value
      
      def initialize key, default
        @key, @default = key, default
      end
    end

    def self.params
      @parameters ||= []
    end

    def self.param name, key, options={:default => ""}
      parameters << Param.new(key, options[:default])
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
    # param :session_key, :s
    param :ack_id, :a, :default => -1
    param :data, :d, :default => ""
    
    attr_accessor :deferrable_body
    attr_reader :params, :session_key
    
    def initialize params
      @params = params
      Session.params.each do |param|
        @params[param.key] ||= param.default
      end
      
      @session_key = SessionKey.generate
      DB[@session_key] = self
      
      @proxy_socket = EM.connect @host, @port, Proxy, self
    end
    
    def send packet
      deferrable_body.call(packet.to_json)
    end
    
    # Orbited::Proxy delegates unbind and receive_data back to this object    
    # def unbind
    # end
    
    def receive_data data
    # Orbited, not CSP
    #   @buffer << data
    #   return unless frame_begins_at_index = @buffer.index('[') # Start of a json encoded frame
    #   size = @buffer[0, frame_begins_at_index].to_i
    #   frame_ends_at_index = size + size.to_s.size
    #   frame = @buffer[0, frame_ends_at_index]
    #   @buffer = @buffer[frame_ends_at_index, @buffer.size - frame_ends_at_index]
    #   socket_id, frame_type, data = *JSON.parse(frame)
    # rescue JSON::ParserError
    #   Orbited.logger.error("Failed to parse frame: #{frame}")
    end
    
    def streaming?
      is_streaming && duration > 0
    end
  end
end
