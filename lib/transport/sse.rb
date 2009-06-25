module Orbited
  module Transport
    class SSE < Abstract
      HeartbeatInterval = 30
            
      def write(packets)
        payload = JSON.dumph(packets)
        data =
          'Event payload\n'                                           +
          payload.split("\n").map{|line| "data #{line}"}.join("\n")   +
          '\n\n'
        send_data(data)
      end
        
      def writeHeartbeat
        Orbited.logger.debug('writeHeartbeat');
        request.write('Event heartbeat\n\n')
      end
    end
  end
end
