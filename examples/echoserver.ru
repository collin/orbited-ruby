# echoserver.ru - example app; echoes input text in list
#
#  Usage:
#
#    % bundle exec rackup -E none -s thin examples/echoserver.ru
#
#    http://localhost:9292/echo/static/echotest.html

require File.join(File.dirname(File.expand_path(__FILE__)),'..', 'lib', 'csp')

class EchoSession < CSP::Session
  alias receive_data send_data
end

echo_app = CSP::Application.new(EchoSession, "/echo")
echo_app.mount(self)
