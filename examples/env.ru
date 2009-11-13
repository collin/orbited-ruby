print_env = Proc.new do |env|
  body = ""
  body += "<dl>"
  env.each do |key, value|
    body += "<dt>#{key}</dt>"
    body += "<dd><pre>#{value}</pre></dd>"
  end
  body += "</dl>"
  [200, {"Content-Type"=>"text/html"}, body]
end

run print_env