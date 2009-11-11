module CSP
  class Packet
    PlainTextByteRange = (32..126).freeze
    Base64 = 1
    PlainText = 0
  
    attr_reader :id
  
    def initialize(id, data)
      @id = id
      @data = data
    end
  
    def base64_encode?
      @data.to_s.bytes.find{ |byte| PlainTextByteRange.include?(byte) }
    end
  
    def data
      base64_encode? ? @data.pack("m").tr('+/','-_').gsub("\n",'') : @data
    end
  
    def encoding
      base64_encode? ? Base64 : PlainText
    end
  
    def to_json
      %{[#{@id},#{encoding},"#{data}"]}
    end
  end
end