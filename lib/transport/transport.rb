module Orbited
  module Transport
  
    Map = {
      'xhrstream' => XHRStreaming,
      'htmlfile' => HTMLFile,
      'sse' => SSE,
      'longpoll' => LongPolling,
      'poll' => Polling
    }
    
    def self.[](transport_name)
      Map[transport_name]
    end
    
  end
end
