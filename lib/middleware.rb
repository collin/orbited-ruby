Orbited::Middleware = Rack::Router.new
Orbited::Middleware.send :eval, File.read('config/routes.rb') 