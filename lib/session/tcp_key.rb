module Orbited
  module Session
    module TCPKey
      Orbited.logger.warn "
        I am not a crytographic expert.
        Be certain this random key is secure enough for your needs.
        #{__FILE__}
      "
      
      def self.source
        @source ||= ("a".."z").to_a + (0..9).to_a
      end
      
      def self.generate length=12
        length.take{ source[rand source.size] }.join
      end
    end
  end
end
