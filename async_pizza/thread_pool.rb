Thread::Queue.new

def cpu_waster(val)
  puts "Thread #{Thread.current.name}: #{val} done"
  sleep 3
end

class ThreadPool
  def initialize(size)
    @queue = Thread::Queue.new
    @threads = (0...size).map do |i|
      Thread.new do
        Thread.current.name = "Thread-#{i}"
        until @queue.closed? && @queue.empty?
          puts "Thread #{Thread.current.name} waiting for task..."
          # looks like the implementation of pop has some sort of waiter in there
          # that rechecks the queue for new tasks, closing the queue tells it to stop
          # blocking
          task, val = @queue.pop
          puts "Thread #{Thread.current.name} got task: #{task} with value: #{val}"
          task&.call(val)
        end
      end
    end
  end

  def add_task(val, &block)
    @queue << [block, val]
  end

  def wait_completion
    @queue.close
    @threads.each(&:join)
  end

  def work; end
end
pool = ThreadPool.new(5)
(1..20).each { |i| pool.add_task(i) { |val| cpu_waster(val) } }
puts 'Waiting for all tasks to complete...'
pool.wait_completion
puts 'All tasks completed.'
