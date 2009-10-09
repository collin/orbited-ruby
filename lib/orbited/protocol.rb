module Orbited
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
end
