post "/csp",
  :to => CSPController.action(:create)
  
post "/csp/:id", 
  :to => CSPController.action(:write)
  
get "/csp/:id/:transport_name", 
  :to => CSPController.action(:connect)

get '/static/*',
  :to => Rack::Directory.new(Orbited.root/'../static'.to_s)
  