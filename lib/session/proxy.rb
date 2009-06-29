module Orbited
  module Session
    class Proxy
      InvalidHandshake = 102
      RemoteConnectionTimeout = 104
      Unauthorized = 106
      RemoteConnectionFailed = 108
      
      def initialize tcp_connection_resource
        @tcp_connection_resource = tcp_connection_resource
      end
      
      def connection_made
        @state = :handshake
      end
      
      def data_received data
        return @outgoing_connection.write(data) if @outgoing_connection

        unless @state == :handshake
          @tcp_connection_resource.write("0" + InvalidHandshake)            
          @state = :closed
          @tcp_connection_resource.lose_connection      
          return
        end

        begin
          data.strip!
          host, port = data.split(':')
          port = port.to_i
          @handshake_complete = true
        rescue
          Orbited.logger.error("failed to connect on handshake")
          transport.write("0" + InvalidHandshake)
          transport.lose_connection
          return
        end

        peer = @transport.peer
        @from_host = peer.host
        @from_port = peer.port
        @to_host = host
        @to_port = port

        allowed = Orbited.config[:access].find do |source|
          source == @tcp_connection_resource.host_header or source == "*"
        end
        
        if not(allowed)
          Orbited.logger.warn(
            "Unauthorized connect from #{@from_host}:#{@from_port} to #{@to_host}:#{@to_port}"
          )
          @transport.write("0" + Unauthorized)
          @transport.lose_connection
          return
        end
        
        Orbited.logger.info(
          "new connection from from #{@from_host}:#{@from_port} to #{@to_host}:#{@to_port}"
        )
        
        self.state = 'connecting'
        @outgoing_connection = EM.attach(
          TCPSocket.new(@to_host, @to_port), 
          FakeTCPTransport, 
          @tcp_connection_resource
        )
      end
      
    end
  end
end
