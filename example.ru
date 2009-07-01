require 'lib/orbited'

Orbited.config.merge! :access => []
Orbited::Middleware.install self

