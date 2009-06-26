module Orbited
  module Transport
    class Abstract
      include Headers
      include Extlib::Hook
      
      HeartbeatInterval = 5
      MaxBytes = 1048576
      
      attr_reader :open, :closed, :heartbeat_timer
      
      alias closed? closed
      alias open? open
      
      def initialize tcp_connection
        @tcp_connection = tcp_connection
        @renderer = DeferrableBody.new
        @open = false
        @closed = false
        render
      end

      def render
        @open = true
        @packets = []
        reset_heartbeat
        @tcp_connection.transport_opened self
        merge_default_headers
      end

      def response
        [200, headers, @renderer]
      end
      
      def reset_heartbeat
        @heartbeat_timer = EM::Timer.new(HeartbeatInterval) { do_heartbeat }
      end
  
      def send_data *data
        @renderer.call data.flatten
      end
  
      def do_heartbeat
        if closed?
          Orbited.logger.debug("heartbeat called - already closed", pretty_inspect)
        else
          write_heartbeat
          reset_heartbeat
        end
      end

      def send_packet(*packet)
        @packets << packet.flatten
      end

      def flush
        write @packets
        @packets = []
        @heartbeat_timer.cancel
        reset_heartbeat
      end

      def close
        Orbited.logger.debug('unbind called')

        if closed?
          Orbited.logger.debug("close called - already closed", pretty_inspect)
          return
        end
        
        @closed = true
        heartbeat_timer.cancel
        @open = false
      end

      def encode(packets)
        output = []
        packets.each do |packet|
          packet.each_with_index do |arg, index|
            if index == packet.size - 1
              output << '0'
            else
              output << '1'
            end
            output << "#{arg.to_s.length},#{arg}"
          end
        end
        return output.join
      end
      
      # Override these
      def write(packets)
        raise "Unimplemented"
      end

      def post_init
        raise "Unimplemented"
      end

      def write_heartbeat
        Orbited.logger.info "
          Call to unimplemented method write_heartbeat on #{pretty_inspect}
          Not neccessarily an error. Heartbeat does not always make sense.
        "
      end
    end
  end
end
