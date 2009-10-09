module Orbited
  class Proxy < EventMachine::Connection
    extend ActiveSupport::Concern

    delegate :unbind, :to => :comet_session
    delegate :receive_data, :to => :comet_session
    
    def initialize comet_session
      @comet_session = comet_session
    end
  end
end