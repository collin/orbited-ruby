class String
  require 'enumerator'

  def bytes(&block)
    return to_enum(:each_byte) unless block_given?
    each_byte &block
  end
end unless ''.respond_to?(:bytes)


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
