module Orbited
  module Session
    class TCPResource
      include Extlib::Hook
      include Headers
      
      def self.connections
        @connections ||= Orbited.config[:tcp_session_storage].new
      end
      
      def connections
        @connections ||= self.class.connections
      end
      
      def initialize(listening_port=nil)
        @listening_port = listening_port
      end
    
      def session_id
        $1 if @request and @request.path[/\/tcp\/([\w]{32})/]
      end
      
      def transport_name
        $1 if @request and @request.path[/\/tcp\/[\w]{32}\/([\w]+)/]
      end
    
      # TODO: integrate Rack::Mount
      def call(env)
        @request = Rack::Request.new env
    
        Orbited.logger.debug "handling rack env: \n#{env.pretty_inspect}"

        connection = connections[session_id] if session_id
        Orbited.logger.debug "path #{@request.path}"
        Orbited.logger.debug "session_id #{session_id}"
        Orbited.logger.debug "transport_name #{transport_name}"
        Orbited.logger.debug "existing connection \n#{connection.pretty_inspect}"
        Orbited.logger.debug "existing connections \n#{connections.keys.pretty_inspect}"
        if connection 
          if transport_name
            return connection.handle_get @request, transport_name
          elsif env["REQUEST_METHOD"] == "POST"
            return connection.handle_post @request
          end
        end
      
        key = nil
        while not(key) or connections.has_key?(key) do key = TCPKey.generate(32) end
        
        # @request.client and @request.host should be address.IPv4Address classes
        host_header = @request.env["HTTP_HOST"]
        connections[key] = TCPConnectionResource.new(
          key, 
          @request.env["HTTP_USER_AGENT"], 
          @request.host, 
          host_header
        )
#        @listening_port.connectionMade(connections[key])
        Orbited.logger.debug("created conn: \n#{connections[key].pretty_inspect}")
        merge_default_headers
        [200, headers, key]
      end
         
      def remove_connection(connection)
        connections.delete connection.key
      end

#      def connection_made(connection)
#        @listening_port.connection_made(connection)
#      end
    end
  end
end
