module Orbited
  module Session
    class TCPPing
      attr_reader :reason
      def initialize reason
        @reason = reason
      end
    end
  end
end
