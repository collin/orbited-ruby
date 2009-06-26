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
        Orbited.logger.debug("writing packets #{packets}")
        payload = encode(packets)
        Orbited.logger.debug("writing payload #{payload}")
        
        send_data(payload)
        @total_bytes += payload.size
        if @total_bytes > MaxBytes
          Orbited.logger.debug('over maxbytes limit')
          close_connection_after_writing
        end
      end

      def write_heartbeat
        Orbited.logger.debug("write_heartbeat #{pretty_inspect}")
        send_data 'x'
      end
      
    end
  end
end
