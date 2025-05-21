class EventLoop
  attr_accessor :readers, :writers, :num_tasks, :ready

  def initialize
    @num_tasks = 0
    @readers = {}
    @writers = {}
    @ready = Queue.new
  end

  def register(socket, event, action, future)
    case event
    when :read
      @readers[socket] = [action, future]
    when :write
      @writers[socket] = [action, future]
    else
      raise "Invalid event '#{event}'"
    end
  end

  def add(task)
    ready << [task, nil]
    self.num_tasks += 1
  end

  def ready(task, msg: nil)
    ready << [task, msg]
  end

  def run(task, msg)
    future = task.call(msg)
    future.coroutine(task)
  rescue StandardError
    self.num_tasks -= 1
  end

  def loop
    while num_tasks > 0
      if queue.empty?
        reader_sockets = readers.keys
        writer_sockets = writers.keys
        ready_readers, ready_writers = select(reader_sockets, writer_sockets)

        ready_readers.each do |socket|
          source, _, action = @readers[socket]
          @readers.delete(fileno)
          action.call(source)
        end

        ready_writers.each do |socket|
          source, _, action = writers[socket]
          writers.delete(fileno)
          action.call(source)
        end
      end

      task, msg = queue.pop
      run(task, msg)
    end
  end
end
