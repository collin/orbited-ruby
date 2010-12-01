# Orbited-Ruby

> Orbited provides a pure JavaScript/HTML socket in the browser. It is a web router and firewall that allows you to integrate web applications with arbitrary back-end systems. You can implement any network protocol in the browser—without resorting to plugins.
##### From Orbited.org

![Orbited-Ruby Logo](http://img505.imageshack.us/img505/1465/orbitedruby.png "Orbited-Ruby")

All the awesomeness of Orbited.

Packed neatly into your Ruby workflow.

Hold up slice!

Haven't you heard? Orbited switched gears and is working on the 0.8 server.

Which includes this awesome awesome thing: Comet Session Protocol

http://orbited.org/blog/files/csp.html

This server has been replaced!
What we have here is a CSP server written for rack.

CSP is the substrate upon which RubyOrbited shall be built.
Here's an example CSP app in Ruby:

    # examples/echoserver.ru
    require '../lib/csp'
    class EchoSession < CSP::Session
      alias receive_data send_data
    end
    echo_app = CSP::Application.new(EchoSession, "/echo")
    echo_app.mount(self)
    

Want to give it a try?  You have to have thin installed.
As recent a version as you can manage.  I'm on 1.2.5.

    rackup -E none -s thin examples/echoserver.ru

Then browse to

    http://localhost:9292/echo/static/echotest.html

Alternatively, try:

    rackup -E none -s thin examples/env.ru

Then browse to

    http://localhost:9292/echo/static/env.html

Want to write your own? Just subclass CSP::Session.

    class MySessionClass < CSP::Session
      # And override these methods.
      def post_init; end
      def receive_data(data); end
      def unbind; end
    end

And look into lib/static/echotest.html
to get started with jsio on the client side.

