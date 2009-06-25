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
    
      before(:call) { merge_default_headers }
      def call(env)
        key = nil
        while not(key) or connections.contains?(key) { key = TCPKey.generate(32) }
        
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
