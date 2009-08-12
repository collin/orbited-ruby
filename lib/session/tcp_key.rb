module Orbited
  module Session
    module TCPKey
      Orbited.logger.warn "
        Be certain this random key generator is secure enough for your needs.
        #{__FILE__}
      "
      
      def self.source
        @source ||= ("a".."z").to_a + (0..9).to_a
      end
      
      def self.generate keyspace, size=32
        key = nil
        while not(key) or keyspace.has_key?(key) do key = make(size) end
      end
      
      def self.make size
        size.take{ source[rand(source.size)] }.join        
      end
    end
  end
end
