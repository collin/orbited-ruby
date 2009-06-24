module Orbited
  module Transport
    Map = {
      'xhrstream' => XHRStreaming,
      'htmlfile' => HTMLFile,
      'sse' => SSE,
      'longpoll' => LongPolling,
      'poll' => Polling
    }
    
    def self.create transport_name, connection
      klass = Map[transport_name]
      return unless klass
      klass.new connection
    end
    
    def self.headers
      return @headers if @headers
      data = Orbited.root/'transport/headers.yaml').read
      @headers = YAML.load data
    end
  end
end
