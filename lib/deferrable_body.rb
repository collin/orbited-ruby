class DeferrableBody
  include EventMachine::Deferrable

  def call(body)
    body.each do |chunk|
      @body_callback.call(chunk)
    end
  end

  def closed?
    !!@deferred_status
  end

  def each(&blk)
    @body_callback = blk
  end
end