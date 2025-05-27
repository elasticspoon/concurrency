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
          task, args = @queue.pop
          puts "Thread #{Thread.current.name} got task: #{task} with args: #{args}"
          task&.call(*args)
        end
      end
    end
  end

  def add(*args, &block)
    @queue << [block, args]
  end

  def stop
    @queue.close
    @threads.each(&:join)
  end
end
