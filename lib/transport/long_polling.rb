module Orbited
  module Transport
    class LongPolling < Abstract
    
      # Force reconnect ever 30 seconds
      # close_connection_after_writing may take a long time
      # This may cause subtle errors?
      def post_init
        @cancel_timer = EM.add_timer(30) { close_connection_after_writing }
      end

      def write(packets)
        # TODO we can optimize this. In the case where packets contains a
        #       single packet, and its a ping, just don't send it. (instead,
        #       close the connection. the re-open will prompt the ack)
        
        @cancel_timer.cancel
        
        Orbited.logger.debug("writing packets #{packets}")
        payload = encode(packets)
        Orbited.logger.debug("writing payload #{payload}")        
        
        send_data(payload)
        close_connection_after_writing
      end

    end
  end
end
