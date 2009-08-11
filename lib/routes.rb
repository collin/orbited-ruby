map "/tcp",     
  :method => 'post',
  :to => TCPResourcesController.action(:create)
  
map "/tcp/:id", 
  :method => 'get',  
  :to => TCPResourcesController.action(:show)
  
map "/tcp/:id/:transport", 
  :method => 'get', 
  :toh => TCPResourcesController.action(:transport)

map '/static/*',
  :method => 'get',
  :to => Rack::Directory.new(Orbited.root/'../static'.to_s)