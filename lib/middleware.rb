module Orbited
  module Middleware
    def self.included klass
      klass.instance_eval do
        use Rack::Static, :urls => ['/static'], Orbited.root
        use Orbited
      end
    end
  end
end
