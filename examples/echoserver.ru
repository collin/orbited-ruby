require 'lib/csp'
class EchoSession < CSP::Session
  alias receive_data send_data
end
echo_app = CSP::Application.new(EchoSession, "/echo")
echo_app.mount(self)