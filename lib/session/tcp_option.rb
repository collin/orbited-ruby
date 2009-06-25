module Orbited
  module Session
    class TCPOption
      attr_reader :payload
      def initialize(name, val)
        @payload = str(name) + ',' + str(val)
      end
    end
  end
end

