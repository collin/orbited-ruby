module CSP
  class Application
    DefaultContentType = "text/html".freeze
    
    def initialize(session_class, mount_point)
      @session_class = session_class
      @mount_point = mount_point
    end
    
    def mount(rack_builder)
      app = self
      rack_builder.map(@mount_point) do
        use(Rack::Static, :urls => [Static], :root => CSP.root)
        map(Reflect)    { run app.action(:reflect) }
        map(Handshake)  { run app.action(:handshake) }
        map(Comet)      { run app.action(:comet) }
        map(Close)      { run app.action(:close) }
        map(Send)       { run app.action(:csp_send) }
      end
    end
    
    alias action method
    # def action(action_name)
    #   # Note the duplication. Each action runs in the context of a dup of this object.
    #   # This way per-request instance variables may be set without spillage. 
    #   dup.method(action_name)
    # end
    
    def environment_filters(env)
      request = AsyncRequest.new(env)
      session = @session_class.get(request.params[SessionKey])
      session.update_settings(request)
      session.acknowledge(request.params[AckId]) if request.params[AckId]
      [request, session]
    end
    
    def handshake(env)
      CSP.logger.info("Initiating handshake")
      request = AsyncRequest.new(env)
      session = @session_class.new(request)
      # go asynchronous. Handshakes should be fast.
      EventMachine.next_tick{ session.post_init }
      
      CSP.logger.info("Completed handshake for #{session}")
      [200, {"Content-Type" => session[ContentType]}, [session.created]]
    end

    def comet(env)
      request, session = *environment_filters(env)
      
      CSP.logger.info("Beginning /comet request for #{session}")
      
      # Close the previous request if it is still open.
      # CSP requires only one /comet request be open per session at a time.
      session.async_body.succeed if session.open?
      
      
      headers = { 'Content-Type'=> session[ContentType] || DefaultContentType,
                  'Cache'=>'nocache',
                  'Pragma'=>'nocache'}
      
      unless request[Duration] == 0
        # headers['TrasnsferEncoding'] = 'chunked'
        async_body = AsyncBody.new      
        request.respond_asynchronously([200, headers, async_body])
        # Send the immediate response on the next tick.
        # EventMachine.next_tick{ async_body.send_data(immediate_response) }
        session.async_body = async_body
        session.start_timer
        AsyncResponse
      else
        immediate_response = session.unacknowledged_and_unsent_packets
        session.mark_packets_as_sent!
        # Send the immediate response right away and close the connection.
        [200, headers, immediate_response]
      end
    end
    
    def csp_send(env)
      request, session = *environment_filters(env)
      
      data = request.body.read || request.params[Data]
      CSP.logger.info("Received data for #{session}\n    #{data}")
      
      CSP.logger.info request.params.inspect
      JSON.parse(data).each do |data|
        id, encoding, data = *data
        data = encoding == 1 ? "#{data}====".tr('-_','+/').unpack('m') : data
        EventMachine.next_tick{ session.receive_data(data) }
      end
      
      [200, {}, session.okay]
    end

    def close(env)
      request, session = *environment_filters(env)   
      
      session.close!
      
      EventMachine.next_tick{ session.unbind }
      
      [200, {}, session.okay]
    end
        
    def reflect(env)
      request = CSP::AsyncRequest(env)
      [200, {}, request.params[Data]] # send the Data param back directly.
    end
  end
end
