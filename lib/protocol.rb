module Orbited
  class Protocol
    def initialize(data)
      @frames = JSON.parse(data)
    end
    
    def write_to_connection(connection)
      @frames.each do |frame|
        case frame[0]
        when 'data': connection.write(frame[1])
        when 'ping': 
        when 'close': connection.lose
        end
      end
    end
  end   
end