module Orbited
  class PacketBatch < Array
    def to_json
      "#{batch_prefix}(#{super})#{batch_suffix}#{sse_id}"
    end
  end  
end