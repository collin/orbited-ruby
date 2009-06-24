module Orbited
  module Session
    class FakeTCPTransport
      def initialize(transport_protocol, protocol)
        @transport_protocol = transport_protocol
        @protocol = protocol
      end
          
      # "Real" protocol facing API
    
      def write(data)
        @transport_protocol.write(data)
      end
  
      def write_sequence(data)
        @transport_protocol.write(data)
      end

      def lose_connection
        @transport_protocol.lose_connection
      end

      def getPeer
        @transport_protocol.get_peer
      end

      def getHost
        @transport_protocol.get_host
      end

      # transport emulation facing API
        
      def data_received(data)
        @protocol.data_received(data)
      end
        
      def connection_lost
        @protocol.connection_lost
      end
            
      def host_header
        @transport_protocol.host_header
      end
    
      def _get_ping_timeout
        @transport_protocol._ping_timeout
      end
    
      def _get_ping_interval
        @transport_protocol._ping_interval
      end
    
      def _set_ping_timeout(timeout)
        @transport_protocol.ping_timeout = timeout
        @transport_protocol.send(TCPOption('ping_timeout', timeout))
      end
        
      def _set_ping_interval(interval)
        @transport_protocol.ping_interval = interval
        @transport_protocol.send(TCPOption('ping_interval', interval))
      end
        
      # Determines timeout interval after ping has been sent
#      ping_timeout = property(_get_ping_timeout, _set_ping_timeout)
      # Determines interval to wait before sending a ping
#      ping_interval = property(_get_ping_interval, _set_ping_interval)
    end
  end
end
