module CSP
  class AsyncRequest < Rack::Request
    AsyncCallback = 'async.callback'.freeze
    def respond_asynchronously(*args)
      # next_tick schedules a block to run in
      # the next iteration of the EventMachine loop.
      EventMachine.next_tick { env[AsyncCallback].call *args }
    end
  end
end