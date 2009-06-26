module Orbited
  module Middleware
    def self.install builder
      builder.instance_eval do
        map '/static' do
          run Rack::Directory.new(Orbited.root/'../static'.to_s)
        end
        map '/tcp' do
          run Orbited::Session::TCPResource.new
        end
      end
    end
  end
end
