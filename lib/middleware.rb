module Orbited
  module Middleware
    def self.included klass
      klass.instance_eval do
        use Rack::Static, :urls => ['/static'], Orbited.root
        map '/tcp' do
          use Orbited::Session::TcpResource
        end
      end
    end
  end
end
