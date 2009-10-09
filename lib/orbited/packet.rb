module Orbited
  class Packet
    class NoCodec < StandardError; end
    class BadCodec < StandardError; end

    # Codec must be set first
    def initialize(id, codec, data)
      @codec = Codecs.find(codec)
      raise NoCodec unless @codec
      raise BadCodec unless @codec.respond_to?(:decode)
      self.id, self.data = id, data
    end
    
  private
    attr_accessor :id, :data
    
    # data can be nil to indicate close of connection
    def data= data=nil
      @data = codec.decode(data) if data
    end
    
    def data
      outbound_codec.encode(@data) if @data
    end
    
    # http://orbited.org/blog/files/csp.html#3312-packing-encodings
    # A server MUST send packets with PACKET_ENCODING = 1 whenever the PACKET_DATA contains 
    # byte values less than 32 or greater than 126. A server SHOULD use PACKET_ENCODING = 0 
    # when PACKET_DATA contains only byte values between 32 and 126, inclusive.
    PlainTextByteRange = (32..126).freeze
    def outbound_codec
      @data.each_byte do |byte|
       codec = Codecs::URL and break unless PlainTextByteRange.include?(byte)
      end
      codec ||= Codecs::PlainText
    end
    
    def to_json
      [id, outbound_codec::Identifier, data].to_json
    end
    
    def inspect
      "<##{self.class.to_s} #{to_json}>"
    end
  end
end
