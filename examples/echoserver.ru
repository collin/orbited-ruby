require '../lib/csp'
class EchoConnection < CSP::Connection
  alias receive_data send_data
end
echo_app = CSP::Application.new(EchoConnection, "/echo")
echo_app.mount(self)