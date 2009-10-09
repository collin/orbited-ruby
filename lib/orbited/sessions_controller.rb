module Orbited
  class SessionsPController < ActionController::HTTP
    AsyncCallback = "async.callback".freeze
    NotFound      = [404, {}, []].freeze
    AsyncResponse = [-1, {}, []].freeze
    Okay          = [200, {}, 'OK'].freeze
        
    include AbstractController::Callbacks
    include AbstractController::ActionArgs

    before :get_connection, :except => [:handshake]
    before :acknowledge,    :except => [:handshake]
    
    def handshake
      @csp_socket = CSPSocket.new(params)
      [200, {}, {:session => @csp_socket.key}.to_json]
    end

    # the comet http connection
    # packets go OUT over this connection
    def comet
      return [200, {}, @csp_socket.unacknowledged_packets.to_json] unless @csp_socket.streaming?
      @csp_socket.deferrable_body = DeferrableBody.new
      EM.next_tick{ request.async_callback [200, {}, @csp_socket.deferrable_body] }
      AsyncResponse        
    end
    
    def close
      @csp_socket.close
      Okay
    end
    
    # incoming packets
    # a message from the client
    # data might be the request body
    def send d=nil
      data = d || request.body
      raise NotFound unless data
      packet = Packet.new(JSON.parse(data))
      @csp_socket.send packet
      Okay
    end

    # def reflect
    # 
    # end

    # def streamtest
    #   
    # end
  
  private
    def acknowledge ack=nil
      ack and @csp_socket ch.acknowledge(ack) 
    end
    
    def get_connection id
      @csp_socket = CSPSocket.get session_key
      raise NotFound unless @csp_socket
    end
  end
end
