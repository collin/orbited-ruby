module CSP
  # TODO: decide whether or not to make individual attr_readers for each setting
  class Session < Hash
    DefaultDuration = 2

    attr_reader :id, :request
    attr_accessor :async_body
    
    # Override these methods in subclasses of Session to build specific applications
    def post_init; end
    def receive_data(data); end
    def unbind; end
    
    # For this implementation we'll just store everything in memory.
    @@all_sessions = {}
    
    def self.get(id)
      @@all_sessions[id]
    end
    
    def self.discard_session(session)
      @@all_sessions.delete(session.id)
      session.async_body.succeed if session.open?
    end
    
    def initialize(request)
      update_settings(request)
      @id = UUID.generate
      @@all_sessions[@id] = self
      @unacknowledged_packets = [] # Still storing everything in memory.
      @unsent_packets = []
      super()
    end
    
    def acknowledge(packet_id)
      @unacknowledged_packets.reject!{ |packet| packet.id <= packet_id.to_i }
      Session.discard_session(self) if closed?
    end
    
    def cancel_timer
      if @timer
        EventMachine.cancel_timer(@timer) 
        @timer = nil
      end
    end
    
    def close!
      send_data(nil)
      @closed = true
    end
    
    def closed?
      @closed and @unacknowledged_packets.length == 0
    end
    
    def created
      "#{self[RequestPrefix]}({\"session\":\"#{id}\"})#{self[RequestSuffix]}"
    end
    
    def inspect
      "#<#{self.class.name}#{@id} " +
      "closed:#{closed?.inspect} " +
      "open:#{open?.inspect} " +
      "#{@unacknowledged_packets.size} unacknowledged_packets " +
      "#{@unsent_packets.size} unsent_packets>"
    end
    alias to_s inspect
    
    def mark_packets_as_sent!
      @unacknowledged_packets |= @unsent_packets
      @unsent_packets = []
    end
    
    def next_packet_id
      @last_packet_id ||= 0
      @last_packet_id += 1
    end
    
    def okay
      "#{self[RequestPrefix]}(\"OK\")#{self[RequestSuffix]}"
    end
    
    def open?
      async_body && async_body.open?
    end
    
    def send_data(data)
      @unsent_packets << Packet.new(next_packet_id, data)
      if open?
        CSP.logger.info("Sending unsent packets. #{inspect}")
        async_body.send_data(serialize_packet_batch(@unsent_packets))
        async_body.succeed unless self[IsStreaming]
        mark_packets_as_sent!
      end
    end
    
    def start_timer(&block)
      cancel_timer # If there is already a timer running, cancel it.
      CSP.logger.info("Starting #{self[Duration] || DefaultDuration} second timer for #{self}")
      @timer = EventMachine.add_timer(self[Duration] || DefaultDuration) do
        # once the timer has been used, cancel it and set it to nil
        # CSP requires a packet batch, even if it's empty.
        # TODO: UNDERSTAND THIS and maybe get it fixed if it's a bug in js.io
        async_body.send_data(serialize_packet_batch([]))
        async_body.succeed
        CSP.logger.info("Cancelled timer for #{self}")
      end
    end
    
    def serialize_packet_batch(packets)
      "#{self[BatchPrefix]}(#{packets.to_json})#{self[BatchSuffix]}#{self[SSEId]};"
    end
    
    def unacknowledged_and_unsent_packets
      serialize_packet_batch(@unacknowledged_packets | @unsent_packets)
    end
    
    def update_settings(request)
      # TODO: decide whether or not to make individual attr_readers for each setting
      CometSessionSettings.each{ |key| self[key] = request.params[key] if request.params[key] }
      @request = request
    end    
  end
end
