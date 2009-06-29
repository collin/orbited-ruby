module Orbited
  module Session
    class TCPClose
      attr_reader :reason
      def initialize reason
        @reason = reason
      end
    end
  end
end
