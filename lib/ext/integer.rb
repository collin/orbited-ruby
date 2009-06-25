class Integer
  def take &block
    took = []
    times{|n| took << block.call(n) }
    took
  end
end

