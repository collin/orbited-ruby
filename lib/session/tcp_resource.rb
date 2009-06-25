module Orbited
  module Session
    class TCPResource
      def self.connections
        @connections ||= Orbited.config[:tcp_session_storage].new
      end
      
      def initialize(listening_port)
        @listening_port = listening_port
      end

      def render(request)
        key = nil
        while key is nil or connections.contains?(key)
            key = TCPKey.generate(32)
        end
        # request.client and request.host should be address.IPv4Address classes
        host_header = request.headers['host']
        connections[key] = TCPConnectionResource(key, request.client, request.host, host_header)
        @listening_port.connectionMade(self.connections[key])
        Orbited.logger.debug('created conn: ', self.connections[key].inspect)
        request.setHeader('cache-control', 'no-cache, must-revalidate')
        return key
      end

      def getChild(path, request)
        if path == 'static':
            return self.static_files
        if path not in self.connections:
            if 'htmlfile' in request.path:
                return transports.htmlfile.CloseResource();
            return error.NoResource("<script>alert('whoops');</script>")
#        print 'returning self.connections[%s]' % (path,)
        return self.connections[path]
      end
         
      def removeConn(conn)
        if conn.key in self.connections:
            del self.connections[conn.key]
        end
      end

      def connectionMade(conn)
        @listening_port.connectionMade(conn)
      end
    end
  end
end
