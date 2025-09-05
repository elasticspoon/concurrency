# frozen_string_literal: true

def cpu_waster(val)
  puts "Thread #{Thread.current.name}: #{val} done"
  sleep 3
end

class ThreadPool
  def initialize(size)
    @queue = Thread::Queue.new
    @threads = start_threads(size)
  end

  def add_task(val, &block)
    @queue << [block, val]
  end

  def wait_completion
    @queue.close
    @threads.each(&:join)
  end

  def start_threads(count)
    (0...count).map do |i|
      Thread.new do
        until @queue.closed? && @queue.empty?
          task, val = @queue.pop
          task&.call(val)
        end
      end
    end
  end
end

if __FILE__ == $0
  pool = ThreadPool.new(5)
  (1..20).each { |i| pool.add_task(i) { |val| cpu_waster(val) } }
  puts 'Waiting for all tasks to complete...'
  pool.wait_completion
  puts 'All tasks completed.'
end
