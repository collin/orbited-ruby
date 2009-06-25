module Orbited
  module Session
    class TCPResource
      include Headers
      
      def self.connections
        @connections ||= Orbited.config[:tcp_session_storage].new
      end
      
      def connections
        @connections ||= self.class.connections
      end
      
      def initialize(listening_port)
        @listening_port = listening_port
      end
    
      def session_id
        $1 if @request and @request.path_info[/\/tcp\/([\w]{32})/]
      end
      
      def transport_name
        $1 if @request and @request.path_info[/\/tcp\/[\w]{32}\/([\w]+)/]
      end
    
      # TODO: integrate Rack::Mount
      before(:call) { merge_default_headers }
      def call(env)
        @request = Rack::Request.new env

        connection = connections[session_id] if session_id
        if connection 
          return if transport_name
            connection.handle_get @request, transport_name
          else
            connection.handle_post @request
          end
        end
      
        key = nil
        while not(key) or connections.has_key?(key) { key = TCPKey.generate(32) }
        
        # request.client and request.host should be address.IPv4Address classes
        host_header = request.headers['host']
        connections[key] = TCPConnectionResource(key, request.client, request.host, host_header)
        @listening_port.connectionMade(connections[key])
        Orbited.logger.debug('created conn: ', connections[key].inspect)
        [200, headers, key]
      end
         
      def remove_connection(connection)
        connections.delete connection.key
      end

      def connection_made(connection)
        @listening_port.connection_made(connection)
      end
    end
  end
end
