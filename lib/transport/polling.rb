module Orbited
  module Transport
    class Pollling < Abstract
      def opened
        request.headers['cache-control'] = CacheControl
      end

    # NOTE we override this so we can close as soon as we send out any waiting
    #       packets. We can't put the self.close call inside of self.write
    #       because sometimes there will be no packets to write.
      def flush
        logger.debug('flush')
        comet_transport.flush
        close
      end

      def write(packets)
        logger.debug('write %r' % packets)
        payload = encode(packets)
        logger.debug('WRITE ' + payload)
        request.write(payload)
      end

      def writeHeartbeat
        # NOTE no heartbeats...
#        pass
      end
    end
  end
end
