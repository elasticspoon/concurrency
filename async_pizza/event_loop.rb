class EventLoop
  attr_accessor :readers, :writers, :unready, :queue

  def initialize
    @unready = 0
    @readers = {}
    @writers = {}
    @queue = Queue.new
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
