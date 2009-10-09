# Orbited-Ruby

> Orbited provides a pure JavaScript/HTML socket in the browser. It is a web router and firewall that allows you to integrate web applications with arbitrary back-end systems. You can implement any network protocol in the browser—without resorting to plugins.
##### From Orbited.org

![Orbited-Ruby Logo](http://img505.imageshack.us/img505/1465/orbitedruby.png "Orbited-Ruby")

All the awesomeness of Orbited.

Packed neatly into your Ruby workflow.

    #example.ru
    require 'lib/orbited'
    use Orbited::Middleware
    

Want to give it a try?

Hold up slice!

Haven't you heard? Orbited switched gears and is working on the 0.8 server.

Which includes this awesome awesome thing: Comet Session Protocol

http://orbited.org/blog/files/csp.html

This server is being gutted to implement 0.8.

It works even less than before. But also has wonderfully smaller amounts of code.

Still need to hook up the deferrable body and the proxy socket. Also some http behaviors missing
