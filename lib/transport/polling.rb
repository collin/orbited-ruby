module Orbited
  module Transport
    class Polling < Abstract

    # NOTE we override this so we can close as soon as we send out any waiting
    #       packets. We can't put the self.close call inside of self.write
    #       because sometimes there will be no packets to write.
      def flush
        logger.debug('flush')
        @comet_transport.flush
#        close_connection_after_writing
      end

      def write(packets)
        Orbited.logger.debug("writing packets #{packets}")
        payload = encode(packets)
        Orbited.logger.debug("writing payload #{payload}")   
        request.write(payload)
      end

    end
  end
end
