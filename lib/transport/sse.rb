module Orbited
  module Transport
    class SSE < Abstract
      HeartbeatInterval = 30
      ContentType = 'application/x-dom-event-stream'
      
      def opened
        request.headers['content-type'] = ContentType
        request.headers['cache-control'] = CacheControl
      end
            
      def write(packets)
        payload = json.encode(packets)
        data =
          'Event payload\n'                                           +
          payload.split("\n").map{|line| "data #{line}"}.join("\n")   +
          '\n\n'
        request.write(data)
      end
        
      def writeHeartbeat
        logger.debug('writeHeartbeat');
        request.write('Event heartbeat\n\n')
      end
    end
  end
end
