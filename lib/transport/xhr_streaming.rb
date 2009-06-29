module Orbited
  module Transport
    class XHRStreaming < Abstract

      def initialize tcp_connection
        @total_bytes = 0
        super
        # Safari/Tiger may need 256 bytes
        send_data(' ' * 256)
      end

      def write(packets)
        # TODO why join the packets here?  why not do N request.write?
        Orbited.logger.debug("writing packets #{packets.pretty_inspect}")
        payload = encode(packets)
        Orbited.logger.debug("writing payload #{payload.pretty_inspect}")
        
        send_data(payload)
        @total_bytes += payload.size
        if @total_bytes > MaxBytes
          Orbited.logger.debug('over maxbytes limit')
          @renderer.succeed
        end
      end

      def encode(packets)
        output = []
        for packet in packets
          packet.each_with_index do |arg, i|
            if(i == (packet.size - 1))
                output.push('0')
            else
                output.push('1')
            end
            output.push(arg.size)
            output.push(',')
            output.push(arg)
          end
        end
        output.join
      end

      def write_heartbeat
        Orbited.logger.debug("write_heartbeat #{pretty_inspect}")
        send_data 'x'
      end
      
    end
  end
end
