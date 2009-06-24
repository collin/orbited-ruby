module Orbited
  module Transport
    class Abstract
      HeartbeatInterval = 5
      MaxBytes = 1048576
      CacheControl = 'no-cache, must-revalidate'
      
      attr_accessor :connection
      attr_accessor :open
      attr_accessor :closed
      attr_accessor :heartbeat_timer
      
      alias closed? closed
      alias open? open
      
      def initialize connection
        self.connection = connection
        @open = false
        @closed = false
      end
      
      def render(request)
        @open = true
        self.packets = []
        self.request = request
        @opened
        self.resetHeartbeat
#        self.closeDeferred = defer.Deferred
#        self.conn.transportOpened
#        return server.NOT_DONE_YET
      end

     def resetHeartbeat
        self.heartbeat_timer = 
          EventMachine::add_timer(HeartbeatInterval) do
            do_heartbeat
          end
      end
  
      def do_heartbeat
        if closed?
          
        else
          write_heartbeat
          reset_heartbeat
        end
      end

      def sendPacket(packet)
        self.packets << packet
      end

      def flush
        write packets
        self.packets = []
        heartbeat_timer.cancel
        reset_heartbeat
      end

      def onClose
        logger.debug('onClose called')
        return self.closeDeferred

      def close
        if closed?
            logger.debug('close called - already closed')
            return
        end
        @closed = true
        heartbeat_timer.cancel
        @open = false
        
        if request
          logger.debug('calling finish')
          request.finish
        end
        
        self.request = nil
        self.closeDeferred.callback
        self.closeDeferred = nil
      end

      def encode(packets)
        output = []
        packets.each do |packet|
          packet.each_with_index do |index, arg|
            if index == packet.size - 1
              output << '0'
            else
              output << '1'
            end
            output << "#{arg.length},#{arg}"
          end
        return output.join
      end
      
      # Override these
      def write(packets)
        raise "Unimplemented"
      end

      def opened
        raise "Unimplemented"
      end

      def writeHeartbeat
        raise "Unimplemented"
      end
    end
  end
end
