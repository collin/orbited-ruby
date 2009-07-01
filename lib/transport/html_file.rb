module Orbited
  module Transport
    class HTMLFile < Abstract
      initial_data = <<-HTML
        <html>
          <head>
            <script src="../static/HTMLFileFrame.js"></script>
          </head>
          <body>
      HTML
      
      InitialData = (' ' * [0, 256 - initial_data.size].max) + "\n"

      
      def initialize
        @total_bytes = 0
#        @close_timer = EM.add_timer(30) { close_connection_after_writing }

        Orbited.logger.debug('send initialData ', InitialData)
        send_data(InitialData)
      end

      def write(packets)
        # TODO make some JS code to remove the script elements from DOM
        #      after they are executed.
        payload = "<script>e(#{JSON.dump(packets)});</script>"
        Orbited.logger.debug('write ', payload)
        send_data(payload)
        @total_bytes += payload.size
        if @total_bytes > MAXBYTES
          Orbited.logger.debug('write closing because session MAXBYTES was exceeded')
          close_connection_after_writing
        end
      end

      def writeHeartbeat
        Orbited.logger.debug('writeHeartbeat')
        request.write('<script>h;</script>')
      end
    end

    class CloseResource
      def getChild(path, request)
        self
      end
    
      def render(request)      
        return format_block('
            <html>
             <head>
              <script src="../../static/HTMLFileClose.js"></script>
             </head>
             <body>
             </body>
            </html> 
        ')
      end
    end
  end
end
