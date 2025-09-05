# frozen_string_literal: true

require 'benchmark'

class Runner
  def fibonacci(count = 1_000_000)
    return count if count <= 1

    a = 0
    b = 1
    (2..count).each do
      a, b = b, a + b
    end
    b
  end

  def run_sleep(time = 5)
    sleep time
  end

  def run_fork(method, concurrency: 3)
    concurrency.times do
      fork do
        self.send(method)
        exit 0
      end
    end
    Process.waitall
  end

  def run_thread(method, concurrency: 3)
    threads = []
    concurrency.times do
      thread = Thread.new do
        self.send(method)
      end
      threads << thread
    end
    threads.map(&:join)
  end
end

# time = Benchmark.realtime do
#   Runner.new.fibonacci
#   Runner.new.fibonacci
#   Runner.new.fibonacci
# end
# puts "Serial fib 1M took #{time} seconds"
#
# time = Benchmark.realtime do
#   Runner.new.run_fork(:fibonacci)
# end
# puts "Fork fib 1M took #{time} seconds"
#
# time = Benchmark.realtime do
#   Runner.new.run_thread(:fibonacci)
# end
# puts "Thread fib 1M took #{time} seconds"
#
def fibonacci(count = 1_000_000)
  return count if count <= 1

  a = 0
  b = 1
  (2..count).each do
    a, b = b, a + b
  end
  b
end

io_time = 0.01
time = Benchmark.realtime do
  sleep io_time 
  fibonacci 20000
end
puts "default took #{time} seconds"
puts "io was #{(io_time / time) * 100}"

time = Benchmark.realtime do
  fibonacci 300_000
  fibonacci 300_000
  fibonacci 300_000
end
puts "Serial fibonacci took #{time} seconds"

time = Benchmark.realtime do
  threads = []
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads.each(&:join)
end
puts "Parallel fibonacci took #{time} seconds"

# time = Benchmark.realtime do
#   sleep 2
#   sleep 2
#   sleep 2
# end
# puts "Serial sleep took #{time} seconds"
#
# time = Benchmark.realtime do
#   threads = []
#   threads << Thread.new { sleep 2 }
#   threads << Thread.new { sleep 2 }
#   threads << Thread.new { sleep 2 }
#   threads.each(&:join)
# end
# puts "Serial sleep took #{time} seconds"
#
# time = Benchmark.realtime do
#   Runner.new.run_sleep
#   Runner.new.run_sleep
#   Runner.new.run_sleep
# end
# puts "Serial sleep 5 took #{time} seconds"
#
# time = Benchmark.realtime do
#   Runner.new.run_fork(:run_sleep)
# end
# puts "Fork sleep 5 took #{time} seconds"
#
# time = Benchmark.realtime do
#   Runner.new.run_thread(:run_sleep)
# end
# puts "Thread sleep 5 took #{time} seconds"
#
