module Orbited
  module Session
    class Proxy
      InvalidHandshake = "0102"
      RemoteConnectionTimeout = "0104"
      Unauthorized = "0106"
      RemoteConnectionFailed = "0108"
      
      def initialize tcp_connection_resource
        @tcp_connection_resource = tcp_connection_resource
        @state = :handshake
      end
      
      def unbind reason="reason unknown"
        Orbited.logger.debug("connectionLost #{reason}")
        @outgoing_connection.close_connection_after_writing if @outgoing_connection
        if @handshake_complete
          Orbited.logger.info(
            "closed connection from #{@from_host}:#{@from_port} to #{@to_host}:#{@to_port}"
          )
        end 
      end

      def data_received data
        return @outgoing_connection.send_data(data) if @outgoing_connection

        unless @state == :handshake
          @tcp_connection_resource.error(InvalidHandshake)            
          @state = :closed
          @tcp_connection_resource.lose_connection      
          return
        end
  
        Orbited.logger.debug "starting handshake #{data}"
        begin
          data.strip!
          host, port = data.split(':')
          port = port.to_i
          @handshake_complete = true
        rescue
          Orbited.logger.error("failed to connect on handshake")
          @tcp_connection_resource.error(InvalidHandshake)
          @tcp_connection_resource.lose_connection
          return
        end

        Orbited.logger.info(
          "new connection from from #{@from_host}:#{@from_port} to #{@to_host}:#{@to_port}"
        )

        @from_host = @tcp_connection_resource.host
        @from_port = @tcp_connection_resource.port
        @to_host = host
        @to_port = port

#        allowed = Orbited.config[:access].find do |source|
#          source == @tcp_connection_resource.host_header or source == "*"
#        end
#        if not(allowed)
#          Orbited.logger.warn(
#            "Unauthorized connect from #{@from_host}:#{@from_port} to #{@to_host}:#{@to_port}"
#          )
#          @tcp_connection_resource.error(Unauthorized)
#          @tcp_connection_resource.lose_connection
#          return
#        end
        
        
        @state = 'connecting'
        @outgoing_connection = EM.attach(
          TCPSocket.new(@to_host, @to_port), 
          FakeTCPTransport, 
          @tcp_connection_resource
        )
      end
      
    end
  end
end
