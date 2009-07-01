module Orbited
  module Session
    class TCPConnectionResource
      PingTimeout   = 5
      PingInterval  = 10
      AsyncCallback = "async.callback".freeze
      

      attr_reader :peer, :host, :request

      def initialize(tcp_resource, key, request)
        @tcp_resource = tcp_resource
        @key = key
        @request = request
        
        Orbited.logger.debug "initializing #{self.pretty_inspect}"
        
        @comet_transport = nil
        @msg_queue = []
        @unacknowledge_queue = []
        @last_acknowledge_id = 0
        @packet_id = 0
        
        @ping_timer = nil
        @timeout_timer = nil
        @close_timer = nil
        
        @lost_triggered = false

        @open = false
        @closed = false
        @closing = false
        @proxy = Orbited::Session::Proxy.new self
        Orbited.logger.debug "Opened Proxy: #{@proxy.pretty_inspect}"

        reset_ping_timer
      end

      def host
        @request.host
      end
      
      def port
        @request.port
      end

      def lose_connection
        # TODO self.close ?
        close('loseConnection', true)
      end

      def close(reason="", now=false)
        if @closed
          Orbited.logger.debug('close called - already closed')
          return
        end
        @closing = true
         
        Orbited.logger.debug("close reason=#{reason} #{pretty_inspect}")
        send(TCPClose.new(reason))
        if now
          hard_close
        elsif not(@closing)
          cancel_timers
          @close_timer = EM.next_tick { hard_close }
        end
      end


      def unbind
        Orbited.logger.debug("connectionLost... already triggered? #{@lost_triggered}")
        unless @lost_triggered
          Orbited.logger.debug('do trigger');
          @lost_triggered = true
          lose_connection
          @proxy.unbind 
          @tcp_resource.remove_connection @key
        end
      end

      def handle_get(request, transport_name)
        @request = request
        transport = Transport.create(transport_name, self)
        transport.on_close do 
          Orbited.logger.info "Connection closed"
        end
        EM.next_tick { @request.env[AsyncCallback].call transport.render }
        AsyncResponse
      end

      def handle_post(request) 
        @request = request
        parse_data @request.body.read
        render
      end
      
      def render
        Orbited.logger.debug("render request=#{request}");
        
        acknowledge
        
        encoding = @request.env["HTTP_TCP_ENCODING"]
        # TODO instead of .write/.finish just return OK?
        reset_ping_timer
        [200, {}, 'OK']
      end

      def parse_data(data)
        # TODO this method is filled with areas that really should be put
        #       inside try/except blocks. We don't want errors caused by
        #       malicious IO.
        Orbited.logger.debug('RECV ' + data)
        frames = []
        current_frame  = []
        while data.size > 0
          is_last = data[0,1] == '0'
          l, data = data[1, data.size].split(',', 2)
          l = l.to_i
          arg = data[0,l]
          data = data[l, data.size]
          current_frame << arg
          if is_last
            frames << current_frame
            current_frame = []
          end
          Orbited.logger.debug([data, frames, current_frame].inspect)
        end

        # TODO do we really need the id? maybe we should take it out
        #       of the protocol...
        #       -mcarter 7-29-08
        #       I think its a safenet for unintentinal bugs;  we should
        #       compare it with the last one we received, and error or
        #       ignore if its not what we expect.
        #       -- rgl
        frames.each do |args|
          Orbited.logger.debug("parse_data frame=#{args.inspect}")
          id = args[0]
          name = args[1]
          if name == 'close'
            if len(args) != 2
              # TODO kill the connection with error.
              pass
            end
            lose_connection
          elsif name == 'data'
            # TODO should there be a try/except around this block?
            #       we don't want app-level code to break and cause
            #       only some packets to be delivered.
            if args.size != 3
              # TODO kill the connection with error.
#              pass
            end
            data = Base64.decode64(args[2])
            Orbited.logger.debug "transport is-a FakeTCPTransport #{@proxy.pretty_inspect}"
            @proxy.data_received(data)
          elsif name == 'ping'
            if args.size != 2
              # TODO kill the connection with error.
#              pass
            end
            # TODO do we have to do anything? I don't think so...
            #       -mcarter 7-30-08
            Orbited.logger.debug('parse_data PING? PONG!');
          end
        end
      end

      # Called by the callback attached to the comet_transport
      def transport_closed(transport)
        @comet_transport = nil if transport == @comet_transport
      end

      def post_init
        @init ||= 0
        @init += 1
        if @init > 1
          raise "WTF"
        end
        send "1"
      end
      
      # Called by transports.comet_transport.render
      def transport_opened(transport)
        reset_ping_timer
        if @comet_transport and transport != @comet_transport
          @comet_transport.close
          @comet_transport = nil
        end
        
        Orbited.logger.debug("opened transport #{transport.pretty_inspect}")
        @comet_transport = transport
#        transport.after(:close) { transport_closed transport }
        
        acknowledge
        resend_unacknowledge_queue
        send_msg_queue
        unless @open
          @open = true
          send TCPOption.new('pingTimeout', PingTimeout)
          send TCPOption.new('pingInterval', PingInterval)
          @comet_transport.send_packet('open', @packet_id.to_s)
        end
        @comet_transport.flush
      end

      def reset_ping_timer
        cancel_timers
        @ping_timer = EM::Timer.new(PingInterval) { send_ping }
      end

      def send_ping
        @ping_timer = nil
        send(TCPPing)
        @timeout_timer = EM::Timer.new(PingTimeout) { timeout }
      end

      def timeout
        @timeout_timer = nil
        close("timeout", true)
      end

      def cancel_timers
        if @timeout_timer
          @timeout_timer.cancel
          @timeout_timer = nil
        end
        if @ping_timer
          @ping_timer.cancel
          @ping_timer = nil
        end
      end

      def hard_close
        @closed = true
        cancel_timers
        if @close_timer
          @close_timer.cancel
          @close_timer = nil
        end
        if @comet_transport
          @comet_transport.close
          @comet_transport = nil
        end
        unbind
      end

      def inspect
        "#<#{self.class.name}:#{@key}>"
      end

      def acknowledge
        Orbited.logger.debug @request.params.inspect
        return unless @request && @request.params['ack']
        acknowledge_id = @request.params['ack'].to_i 
        acknowledge_id = [acknowledge_id, @packet_id].min
        Orbited.logger.debug("acknowledge acknowledge_id=#{acknowledge_id}")
        Orbited.logger.debug("last ack #{@last_acknowledge_id}")
        Orbited.logger.debug("#{@unacknowledge_queue.inspect}")
        return if acknowledge_id <= @last_acknowledge_id
        
        (acknowledge_id - @last_acknowledge_id).times do
          data, packet_id = @unacknowledge_queue.pop
          close("close acknowledged", true) if data.is_a?(TCPClose)
        end
        @last_acknowledge_id = acknowledge_id
      end

      def send_msg_queue
        while @msg_queue.any? and @comet_transport do
          Orbited.logger.debug "sending message #{@msg_queue.first}"
          send(@msg_queue.pop, false)
        end
      end

      def send(data, flush=true)
        if not(@comet_transport)
          @msg_queue << data
        else
          @packet_id += 1
          _send(data, @packet_id)
          @unacknowledge_queue << [data, @packet_id]
          if flush
            @comet_transport.flush
          end
        end
      end

      def _send(data, packet_id="")
        Orbited.logger.debug("_send #{data.inspect}")
        if data == TCPPing
          @comet_transport.send_packet('ping', packet_id.to_s)
        elsif data.is_a? TCPClose
          @comet_transport.send_packet('close', packet_id.to_s, data.reason)
        elsif data.is_a? TCPOption
          @comet_transport.send_packet('opt', packet_id.to_s, data.payload)
        else
          @comet_transport.send_packet('data', packet_id.to_s, Base64.b64encode(data).gsub("\n", ""))
        end
      end
      alias error _send

      def resend_unacknowledge_queue
        return unless @unacknowledge_queue.any?

        @unacknowledge_queue.each{|atom| _send atom.first, atom.last }
        
        acknowledge_id = @last_acknowledge_id + @unacknowledge_queue.size
      end
    end
  end
end
