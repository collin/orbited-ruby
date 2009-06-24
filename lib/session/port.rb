module Orbited
  module Session
    class Port
#    copied from python comments, little wonky    
#    A cometsession.Port object can be used in two different ways.
#    Method 1
#    reactor.listenWith(cometsession.Port, 9999, SomeFactory)
#    
#    Method 2
#    root = twisted.web.resource.Resource
#    site = twisted.web.server.Site(root)
#    reactor.listenTcp(site, 9999)
#    reactor.listenWith(cometsession.Port, factory=SomeFactory, resource=root, child_name='tcp')
#    
#    Either of these methods should acheive the same effect, but Method2 allows you
#    To listen with multiple protocols on the same port by using different urls.

      def initialize(options={})
        @port         = options[:port]
        @factory      = options[:factory]
        @backlog      = options[:backlog]       || 50
        @interface    = options[:interface]     || ''
        @resource     = options[:resource]
        @child_name   = options[:child_name]
        @wrapped_port = options[:wrapped_Port]
        @listening    = false
      end
                
      def startListening
        logger.debug('startingListening')
        unless @listening
          @listening = true
          if @port
            logger.debug('creating new site and resource')
            @wrapped_factory = setup_site
            @wrapped_port = reactor.listenTCP(
              @port, 
              @wrapped_factory,
              @backlog, 
              @interface
            )
          elsif @resource and @child_name
            logger.debug("adding into existing resource as #{child_name}")
            @resource.put_child(@child_name, TCPResource)
          end
        else
          raise CannotListenError("Already listening...")
        end
      end

      def stop_listening
        logger.debug('stop_listening')
        if @wrapped_port
            @listening = false
            @wrapped_port.stop_listening
        elsif @resource
            #pass
            # TODO self.resource.removeChild(self.child_name) ?
        end
      end

      def connectionMade(transport_protocol)
#        proto is the tcp-emulation protocol
#        
#        protocol is the real protocol on top of the transport that depends
#        on proto
            
        logger.debug('connectionMade')
        protocol = @factory.buildProtocol(transport_protocol.getPeer)
        unless protocol
          transport_protocol.loseConnection
          return
        end
        
        transport = FakeTCPTransport(transport_protocol, protocol)
        transport_protocol.parent_transport = transport
        protocol.makeConnection(transport)
      end
         
      def getHost
        if @wrapped_port
          return @wrapped_port.getHost
        elsif @resource
#          pass
            # TODO how do we do getHost if we just have self.resource?
        end
      end    
    end
  end
end
