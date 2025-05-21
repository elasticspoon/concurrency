class Future
  attr_accessor :done, :fiber
  attr_reader :result

  def initialize
    @done = false
    @fiber = nil
    @result = nil
  end

  def result=(result)
    @result = result
    @done = true
  end

  def resume
    raise StopIteration unless done

    result
  end
end

class EventLoop
  def initialize
    @tasks = Queue.new
  end

  def add_coroutine(task)
    @tasks << task
  end

  def run_coroutine(task)
    future = task.call
    future.fiber = task

    future.resume
    unless future.done
      future.fiber = task
      add_coroutine(task)
    end
  rescue StopIteration
    nil
  end

  def run
    run_coroutine(@tasks.shift) until @tasks.empty?
  end
end

def cook(on_done)
  burger = "Burger #{rand(20)}"
  puts "#{burger} is cooked"
  on_done.call(burger)
end

def cashier(burger, on_done)
  puts "#{burger} is ready for pick up!"
  on_done.call(burger)
end

def order_burger
  order = Future.new

  on_cashier_done = lambda { |burger|
    puts "#{burger}? That's me! Mmmmm."
    order.result = burger
  }
  on_cook_done = ->(burger) { cashier(burger, on_cashier_done) }

  cook(on_cook_done)
  order
end

loop = EventLoop.new
loop.add_coroutine(order_burger)
loop.run
