# frozen_string_literal: true

class Future
  attr_accessor :done, :callback
  attr_reader :result

  def initialize
    @done = false
    @callback = nil
    @result = nil
  end

  def result=(result)
    @result = result
    @done = true
  end
end
