module Orbited
  module Transport
    class XHRStreaming < Abstract
      ContentType = 'application/x-orbited-event-stream'
      
      def opened
        @total_bytes = 0
        request.headers['content-type'] = ContentType
        # Safari/Tiger may need 256 bytes
        request.write(' ' * 256)
      end

      def trigger_close_timeout
        logger.debug('trigger_close_timeout called')
        close
      end

      def write(packets)
        logger.debug('write %r' % packets)
        # TODO why join the packets here?  why not do N request.write?
        payload = encode(packets)
        logger.debug('WRITE ' + payload)
        request.write(payload)
        @total_bytes += payload.size
        if @total_bytes > MaxBytes
          logger.debug('over maxbytes limit')
          close
        end
      end

      def write_heartbeat
        logger.debug("writeHeartbeat #{inspect}")
        request.write('x')
      end
    end
  end
end
