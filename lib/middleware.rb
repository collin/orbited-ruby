module Orbited
  Middleware = Rack::Router.new.instance_eval(File.read('config/routes.rb')); 
end
