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
      
      InitialData = ([0, 256 - initial_data.size].max * ' ') + "\n"
      Pragma = 'no-cache'
      Expires = -1
      
      def opened
        logger.debug('opened!')
        # Force reconnect ever 30 seconds
        @total_bytes = 0
#        @close_timer = reactor.callLater(5, self.triggerCloseTimeout)
        # See "How to prevent caching in Internet Explorer"
        #     at http://support.microsoft.com/kb/234067
        request.headers['cache-control'] = CacheControl
        request.headers['pragma'] = Pragma
        request.headers['expires'] = Expires
        logger.debug('send initialData ', InitialData)
        request.write(InitialData)

      def trigger_close_timeout
        close
      end

      def write(packets)
        # TODO make some JS code to remove the script elements from DOM
        #      after they are executed.
        payload = "<script>e(#{json.encode(packets)});</script>"
        logger.debug('write ', payload)
        request.write(payload)
        @total_bytes += len(payload)
        if @total_bytes > MAXBYTES
          logger.debug('write closing because session MAXBYTES was exceeded')
          close
        end
      end

      def writeHeartbeat
        logger.debug('writeHeartbeat')
        request.write('<script>h;</script>')
      end
    end

    class CloseResource(resource.Resource)
      def getChild(path, request)
        self
      end
    
      def render(request)      
        return format_block("
            <html>
             <head>
              <script src="../../static/HTMLFileClose.js"></script>
             </head>
             <body>
             </body>
            </html> 
        ")
      end
    end
  end
end
