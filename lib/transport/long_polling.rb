module Orbited
  module Transport
    class LongPolling < Abstract
    
      def opened
        # Force reconnect ever 45 seconds
        @close_timer = reactor.callLater(30) { trigger_close_timeout }
        request.headers['cache-control'] = CacheControl
      end

      def trigger_close_timeout
        close
      end

      def write(packets)
        # TODO we can optimize this. In the case where packets contains a
        #       single packet, and its a ping, just don't send it. (instead,
        #       close the connection. the re-open will prompt the ack)
        
        logger.debug('write %r' % packets)
        payload = encode(packets)
        logger.debug('WRITE ' + payload)        
        request.write(payload)
        close
      end

      def writeHeartbeat
        # NOTE no heartbeats...
#        pass
      end
    end
  end
end
