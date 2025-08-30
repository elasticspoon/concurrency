# frozen_string_literal: true

class EventLoop
  def initialize
    @tasks = Queue.new
  end

  def add_coroutine(task)
    @tasks << task
  end

  def run_coroutine(task)
    task.resume
    add_coroutine(task)
  rescue FiberError
    puts 'Task complete'
  end

  def run
    until @tasks.empty?
      puts 'Event loop cycle'
      run_coroutine(@tasks.shift)
    end
  end
end

def fib(number)
  Fiber.new do
    a = 0
    b = 1
    number.times do |i|
      a, b = [b, a + b]
      puts "Fibonacci #{i}: #{a}"
      Fiber.yield
    end
  end
end

loop = EventLoop.new
loop.add_coroutine(fib(5))
loop.run
