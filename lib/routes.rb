%w(comet handshake close send reflect streamtest).each do |action|
  %w(get post) do |_method|
    map "/csp/#{action}", :method => _method, :to => CSPController.action(action)
  end
end
