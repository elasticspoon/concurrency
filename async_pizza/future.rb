class Future
  attr_accessor :done, :coroutine
  attr_reader :result

  def initialize
    @done = false
    @coroutine = nil
    @result = nil
  end

  def result=(result)
    @result = result
    @done = true
  end

  def resume
    self.result = coroutine.resume
    result
  end
end
