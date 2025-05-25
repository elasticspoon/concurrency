class EventLoop
  attr_accessor :readers, :writers, :num_tasks, :ready

  def initialize
    @num_tasks = 0
    @readers = {}
    @writers = {}
    @ready = Queue.new
  end

  def register_reader(socket, action, future)
    @readers[socket] = [action, future]
  end

  def register_writer(socket, action, future)
    @writers[socket] = [action, future]
  end

  def add_task(task)
    ready << [task, nil]
    self.num_tasks += 1
  end

  def add_ready(task, msg: nil)
    ready << [task, msg]
  end

  def run(task, msg)
    future = task.resume(msg)
    future.coroutine.call(self, task)
  rescue StandardError
    self.num_tasks -= 1
  end

  def loop
    while num_tasks.positive?
      if ready.empty?
        reader_sockets = readers.keys
        writer_sockets = writers.keys
        puts 'waiting on sockets...'
        ready_readers, ready_writers = select(reader_sockets, writer_sockets)

        ready_readers.each do |socket|
          action, future = readers.delete(socket)
          future.coroutine.call(self, action)
        end

        ready_writers.each do |socket|
          action, future = writers.delete[socket]
          future.coroutine.call(self, action)
        end
      end

      task, msg = ready.pop
      run(task, msg)
    end
  end
end
