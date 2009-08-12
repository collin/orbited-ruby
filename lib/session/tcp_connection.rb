module Orbited
  module Session
    class TCPConnection
      PingTimeout   = 5
      PingInterval  = 10
      TCPConnections = Orbited.config[:tcp_session_storage].new

      attr_reader :peer, :host, :request
      
      def self.get(id)
        TCPConnections[id.to_s]
      end

      def initialize
        @tcp_resource = tcp_resource
        @key = TCPKey.genereate(TCPConnections)
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

        TCPConnections[@key] = self
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

      def create_transport(klass)
        self.transport = klass.new(self)
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
      
      def deferred_renderer
        transport.deferred_renderer
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
