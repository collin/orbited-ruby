module Orbited
  class CSPController < ActionController::HTTP
    AsyncCallback = "async.callback".freeze
    NotFound      = [404, {}, []].freeze
    AsyncResponse = [-1, {}, []].freeze
    Okay          = [200, {}, 'OK'].freeze
        
    include AbstractController::Callbacks
    include AbstractController::ActionArgs

    before :get_connection, :except => [:handshake]
    before :acknowledge,    :except => [:handshake]

    comet handshake close send reflect streamtest
    
    def handshake data
      [200, {}, Orbited::Session.new.handshake]
    end

    def comet
      return [200, {}, @comet_session.unacknowledged_packets] unless @comet_session.is_streaming?
      request.async_callback [200, {}, @comet_session.deferred_renderer]
      AsyncResponse        
    end
    
    def close
      @comet_session.close
      Okay
    end
    
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
      ack and @connection.acknowledge(ack) 
    end
    
    def get_connection id
      @comet_session = Orbited::Session.get session_key
      raise NotFound unless @comet_session
    end
  end
end
