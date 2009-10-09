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
      [200, {}, {:session => Orbited::Session.new(params).key}.to_json]
    end

    # the comet http connection
    # packets go OUT over this connection
    def comet
      return [200, {}, @comet_session.unacknowledged_packets.to_json] unless @comet_session.is_streaming?
      request.async_callback [200, {}, @comet_session.deferred_renderer]
      AsyncResponse        
    end
    
    def close
      @comet_session.close
      Okay
    end
    
    # incoming packets
    # a message from the client
    def send
      packet = Packet.new ...
      @comet_session.send packet
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
      ack and @comet_session ch.acknowledge(ack) 
    end
    
    def get_connection id
      @comet_session = Orbited::Session.get session_key
      raise NotFound unless @comet_session
    end
  end
end
