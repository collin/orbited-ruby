module CSP
  class AsyncBody
    include EventMachine::Deferrable
    
    # When 'each' gets called, instead of executing the block, we stash it for later use.
    def each &blk
      @body_callback = blk
    end
    
    # And when 'send_data' gets called, we use the block to send data down the wire.
    def send_data(body)
      @body_callback.call body
    end
    
    def open?
      # @deferred_status will be :success or :failure when closed
      @deferred_status == :unknown
    end
  end
  
end