# env.ru - example app; displays env hash
#
#  Usage:
#
#    % rackup -E none -s thin examples/env.ru
#
#    http://localhost:9292/echo/static/env.html

print_env = Proc.new do |env|
  rows = []
  keys = env.keys.sort

  keys.each do |key|
    value = env[key].inspect.gsub(/</, '&lt;')
    rows << "      <dt>#{key}</dt>\n" +
            "      <dd><pre>#{value}</pre></dd>"
  end

  body = <<-EOT
<html>
  <head>
    <title>env.ru</title>
  </head>
  <body>
    <dl>
#{ rows.join("\n") }
    </dl>
  </body>
</html>
  EOT

  [200, {"Content-Type"=>"text/html"}, body]
end

run print_env