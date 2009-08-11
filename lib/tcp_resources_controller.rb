class TCPResourcesController < ActionController::HTTP
  include AbstractController::Callbacks
  include ActionController::RackConvenience
  include ActionController::Renderer
  include ActionView::Context

  
end