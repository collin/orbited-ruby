module Rack
  class Request
    def async_callback(*args) 
      EM.next_tick { env["async.callback"].call *args }
    end
  end
  
  class Router
    %w(get post put delete).each do |type|
      send(:eval, <<RUBY
        def #{type}(path, options) 
          map path {:method => '#{type}'}.merge(options)
        end
      RUBY)
    end
  end
end