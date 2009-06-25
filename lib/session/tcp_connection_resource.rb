module Orbited
  module Session
    class TCPConnectionResource
      PingTimeout = 30
      PingInterval = 30
      AsyncResponse = [-1, {}, []].freeze
      AsyncCallback = "async.callback".freeze

      attr_reader :peer, :host

      def initialize(root, key, peer, host, host_header)
        @root = root
        @key = key
        @peer = peer
        @host = host
        @host_header = host_header
        @transport = nil
        @comet_transport = nil
        @parent_transport = nil
        @options = {}
        @msg_queue = []
        @unack_queue = []
        @last_ack_id = 0
        @packet_id = 0
        @ping_timer = nil
        @timeout_timer = nil
        @close_timer = nil
        @lost_triggered = false
        reset_ping_timer
        @open = false
        @closed = false
        @closing = false
      end

      alias write send

      # this is never used, right?
      def write_sequence(data)
        data.each{|datum| write datam }
      end

      def lose_connection
        # TODO self.close ?
        close('lose_connection', true)
        nil
      end

      def connection_lost
        Orbited.logger.debug('connectionLost... already triggered?', @lost_triggered)
        unless @lost_triggered
          Orbited.logger.debug('do trigger');
          @lost_triggered = true
          @parent_transport.connection_lost
        end
      end

      def get_child(path, request)
        if Transport::Map.contain? path
          return Transport.create(path, self)
        else
          raise NoResource("No such child resource.")
        end
      end

      def call(env)
        @request = Rack::Request.new env
        Orbited.logger.debug("render request=#{request}");
        stream = request.body.read
        
        ack(@request.params['ack'].to_i) if @request.params['ack']
        
        encoding = request.headers['tcp-encoding']
        # TODO instead of .write/.finish just return OK?
        request.write('OK')
        request.finish
        reset_ping_timer
        # TODO why not call parse_data here?
        reactor.callLater(0, parse_data, stream)
        AsyncResponse
      end

      def parse_data(data)
        # TODO this method is filled with areas that really should be put
        #       inside try/except blocks. We don't want errors caused by
        #       malicious IO.
        Orbited.logger.debug('RECV ' + data)
        frames = []
        current_frame  = []
        while data
          Orbited.logger.debug([data, frames, current_frame])
          is_last = data[0] == '0'
          l, data = data[1].split(',', 2)
          l = int(l)
          arg = data[l]
          data = data[l]
          current_frame << arg
          if is_last
            frames << current_frame
            current_frame = []
          end
        end

        # TODO do we really need the id? maybe we should take it out
        #       of the protocol...
        #       -mcarter 7-29-08
        #       I think its a safenet for unintentinal bugs;  we should
        #       compare it with the last one we received, and error or
        #       ignore if its not what we expect.
        #       -- rgl
        for args in frames
          Orbited.logger.debug('parse_data frame=%r' % args);
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
            if len(args) != 3
              # TODO kill the connection with error.
              pass
            end
            data = Base64.decode64(args[2])
            # NB parent_transport is-a FakeTCPTransport.
            @parent_transport.date_received(data)
          elsif name == 'ping'
            if len(args) != 2
              # TODO kill the connection with error.
              pass
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

      # Called by transports.comet_transport.render
      def transport_opened(transport)
        reset_ping_timer
        if @comet_transport
          @comet_transport.close
          @comet_transport = nil
        end
        Orbited.logger.debug("new transport " + repr(transport))
        @comet_transport = transport
        transport.CONNECTION = self
        transport.onClose.addCallback(@transport_closed)
        
        ack(@request.params['ack'].to_i) if @request.params['ack']
        resend_unack_queue
        send_msg_queue
        unless @open
          @open = true
          @comet_transport.send_packet("open", @packet_id)
        end
        @comet_transport.flush
      end

      def reset_ping_timer
        cancel_timers
        @ping_timer = reactor.callLater(ping_interval, send_ping)
      end

      def send_ping
        @ping_timer = nil
        send(TCPPing)
        @timeout_timer = reactor.callLater(ping_timeout, timeout)
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

      def hardClose
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
        connectionLost
        @root.remove_conn
      end

      def close(reason="", now=false)
        if @closed
          Orbited.logger.debug('close called - already closed')
          return
        end
        @closing = true
        Orbited.logger.debug('close reason=%s %s' % (reason, repr))
        send(TCPClose(reason))
        if now
          hardClose
        elsif not(@closing)
          cancel_timers
          @close_timer = reactor.callLater(ping_interval, hardClose)
        end
      end

      def ack(ack_id)
        Orbited.logger.debug("ack ack_id=#{ack_id}")
        ack_id = [ack_id, @packet_id].min
        return if ack_id <= @last_ack_id
        (ack_id - @last_ack_id).times do
          data, packet_id = @unack_queue.pop
          close("close acked", true) if data.is_a?(TCPClose)
        end
        @last_ack_id = ack_id
      end

      def send_msg_queue
        while @msg_queue.any? and @comet_transport do
          send(@msg_queue.pop, false)
        end
      end

      def send(data, flush=true)
        if not(@comet_transport)
          @msg_queue << data
        else
          @packet_id += 1
          _send(data, @packet_id)
          @unack_queue.append([data, @packet_id])
          if flush
            @comet_transport.flush
          end
        end
      end

      def _send(data, packet_id="")
        Orbited.logger.debug("_send data=#{data} packet_id=#{packet_id}")
        if data.is_a? TCPPing
          @comet_transport.send_packet('ping', packet_id.to_s)
        elsif data.is_a? TCPClose
          @comet_transport.send_packet('close', packet_id.to_s, data.reason)
        elsif data.is_a? TCPOption
          @comet_transport.send_packet('opt', packet_id.to_s, data.payload)
        else
          @comet_transport.send_packet('data', packet_id.to_s, Base64.b64encode(data))
        end
      end

      def resend_unack_queue
        return unless @unack_queue.any?

        @unack_queue.each{|atom| _send atom.first, atom.last }
        
        ack_id = @last_ack_id + @unack_queue.size
      end
    end
  end
end
