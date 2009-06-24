module Orbited
  module Transport
    class Packet
      attr_reader :id, :name, :data
      
      def initialize id, name, data={}
        self.id = id
        self.name = name
        self.data = data
      end
    end
  end
end
