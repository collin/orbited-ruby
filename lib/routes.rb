post "/tcp",
  :to => TCPController.action(:create)
  
post "/tcp/:id", 
  :to => TCPController.action(:write)
  
get "/tcp/:id/:transport_name", 
  :to => TCPController.action(:connect)

get '/static/*',
  :to => Rack::Directory.new(Orbited.root/'../static'.to_s)
  