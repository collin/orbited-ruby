module Orbited
  module Headers
    def self.[] config_name
      return @headers[config_name] if @headers
      @headers = YAML.load((Orbited.root/'headers.yml').read).freeze
      @headers[config_name]
    end
  
    def config_name
      @config_name ||= self.class.name.split("::").last
    end
    
    def headers
      @headers ||= {}
    end
  
    def merge_default_headers
      headers.merge! Headers[config_name]
    end
  end
end
