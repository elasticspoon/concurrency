require_relative './thread_pool'

class Executor
  attr_reader :thread_pool

  def initialize
    @thread_pool = ThreadPool.new(3)
  end

  def execute(*args, &block)
    reader, writer = IO.pipe

    thread_pool.add do
      result = block.call(*args)
      reader.write(result)
      reader.close
    end

    writer
  end
end

class EventLoop
  attr_accessor :readers, :writers, :unready, :queue, :executor

  def initialize
    @unready = 0
    @readers = {}
    @writers = {}
    @queue = Queue.new
    @executor = Executor.new
  end

  def register_reader(socket, fiber, future)
    @readers[socket] = [fiber, future]
  end

  def register_writer(socket, fiber, future)
    @writers[socket] = [fiber, future]
  end

  def add_unready(fiber)
    queue << [fiber, nil]
    self.unready += 1
  end

  def add_ready(fiber, msg: nil)
    queue << [fiber, msg]
  end

  def run(fiber, msg)
    future = fiber.resume(msg)
    future.callback.call(self, fiber)
  rescue StandardError
    self.unready -= 1
  end

  def run_async(*args, &block)
    future_reader = executor.execute(*args, &block)
    future = Future.new

    handle_yield = lambda do |loop, task|
      msg = future_reader.read_nonblock(BUFFER_SIZE)
      loop.add_ready(task, msg: msg)
    rescue IO::WaitReadable
      loop.register_reader(future_reader, task, future)
    end

    future.callback = handle_yield
    future
  end

  def loop
    while unready.positive?
      if queue.empty?
        reader_sockets = readers.keys
        writer_sockets = writers.keys
        puts 'waiting on sockets...'
        ready_readers, ready_writers = select(reader_sockets, writer_sockets)

        ready_readers.each do |socket|
          fiber, future = readers.delete(socket)
          future.callback.call(self, fiber)
        end

        ready_writers.each do |socket|
          fiber, future = writers.delete[socket]
          future.callback.call(self, fiber)
        end
      end

      fiber, msg = queue.pop
      run(fiber, msg)
    end
  end
end
