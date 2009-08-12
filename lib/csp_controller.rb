module Orbited
  class CSPController < ActionController::HTTP
    AsyncCallback = "async.callback".freeze
    NotFound      = [404, {}, []].freeze
    AsyncResponse = [-1, {}, []].freeze
    Okay          = [200, {}, 'OK'].freeze
        
    include AbstractController::Callbacks

    before :get_connection, :except => [:open]
    after  :acknowledge,    :except => [:open]

    def create
      [200, {}, TCPConnection.new.id.to_s]
    end
  
    def write
      Protocol.new(request.body).write_to_connection(@resource)
      Okay
    end
  
    def connec id, transport_name
      return NotFound unless @connection.create_transport(Transport[transport_name])
      request.async_callback [200, {}, @connection.deferred_renderer]
      AsyncResponse  
    end
  
  private
    def acknowledge
      params['ack'] and @connection.acknowledge(params['ack']) 
    end
    
    def get_connection
      @connection = TCPConnection.get params[:id]
      raise NotFound unless @connection
    end
  end
end
