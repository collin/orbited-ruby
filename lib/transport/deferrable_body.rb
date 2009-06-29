module Orbited
  module Transport
  # Based on version from James Tucker <raggi@rubyforge.org>
    class DeferrableBody
      include EM::Deferrable
    
      attr_reader :queue
      attr_accessor :all_sent
    
      def initialize
        @queue = []
        @all_sent = ""
      end
    
      def closed?
        !!@deferred_status
      end
    
      def call(body)
        @queue << body
        schedule_dequeue
      end
   
      def each(&blk)
        @body_callback = blk
        schedule_dequeue
      end
    
      def enqueued_size
        @queue.flatten.join.size
      end
    
      private
        def schedule_dequeue
          Orbited.logger.debug "@body_callback? #{@body_callback.pretty_inspect}"
          return unless @body_callback
          EM.next_tick do
            Orbited.logger.debug "running scheduled dequeue on queue #{@queue.inspect}"
            next unless body = @queue.shift
            body.each do |chunk|
              self.all_sent += chunk
              Orbited.logger.debug "sent on deferrable_body: #{all_sent}"
              @body_callback.call(chunk)
            end
            schedule_dequeue if @queue.any?
          end
        end
    end
  end
end

