module Orbited
  module Session
    class TCPOption
      attr_reader :payload
      def initialize(name, val)
        @payload = "#{name},#{val}"
        Orbited.logger.debug "created TCPOption with payload: #{@payload}"
      end
    end
  end
end

