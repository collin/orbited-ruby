module Orbited
  # Modules for encoding type of packet encoding
  # Codec must have an identifier (from csp spec)
  # Must have a decode and encode method
  module Codecs
    def self.find identifier
      self.constants.find{|codec| codec::Identifier == identifier }
    end

    module PlainText
      Identifier = 0
      def self.echo _; _ end
      alias decode echo
      alias encode echo
    end
  
    module Base64
      Identifier = 1

      require 'base64'
      extend Base64
      extend self

      # use methods from Base64 
      alias decode decode_64
      alias encode encode_64
    end
    
  end
end