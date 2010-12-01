# chatserver.ru - echoes input text in list to all connected sessions
#
#  Usage:
#
#    % bundle exec rackup -E none -s thin examples/chatserver.ru
#
#    http://localhost:9292/echo/static/echotest.html
# 
require File.join(File.dirname(File.expand_path(__FILE__)),'..', 'lib', 'csp')

class EchoSession < CSP::Session
  def receive_data(data)
    @@all_sessions.each do |id, session|
      session.send_data(data)
    end
  end
end

echo_app = CSP::Application.new(EchoSession, "/echo")
echo_app.mount(self)
