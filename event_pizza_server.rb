# frozen_string_literal: true

require 'socket'

ADDRESS = ['127.0.0.1', 3000].freeze
BUFFER_SIZE = 1024

class EventLoop
  attr_accessor :readers, :writers

  def initialize
    @writers  = {}
    @readers  = {}
  end

  def register(source, event, action)
    case event
    when :read
      @readers[source] = [event, action]
    when :write
      @writers[source] = [event, action]
    else
      raise "Invalid event '#{event}'"
    end
  end

  def unregister(source)
    @writers.delete(source)
    @readers.delete(source)
  end

  def run
    loop do
      puts "Waiting on readers: #{readers.keys.map(&:fileno).join(', ')} and writers: #{writers.keys.map(&:fileno).join(', ')}"
      reader_sockets = readers.keys
      writer_sockets = writers.keys
      ready_readers, ready_writers = select(reader_sockets, writer_sockets)

      ready_readers.each do |socket|
        _, action = @readers[socket]
        @readers.delete(socket)
        action.call(socket)
      end

      ready_writers.each do |socket|
        _, action = writers[socket]
        writers.delete(socket)
        action.call(socket)
      end
    end
  end
end

class Server
  def initialize(event_loop)
    @event_loop = event_loop
    puts 'Starting server...'
    @server_socket = Socket.new(Socket::PF_INET, Socket::SOCK_STREAM)
    @server_socket.bind(Addrinfo.tcp(*ADDRESS))
    @server_socket.listen(5)
  end

  def start
    register(@server_socket, :read, ->(conn) { on_accept(conn) })
  end

  def register(...)
    @event_loop.register(...)
  end

  def unregister(...)
    @event_loop.unregister(...)
  end

  def on_accept(socket)
    conn, = socket.accept_nonblock
    puts 'Connected to client...'
    register(conn, :read, ->(s) { on_read(s) })
    start
    puts 'No connection to accept. Retrying...'
  rescue IO::WaitReadable
    puts 'failed'
  end

  def on_read(socket)
    data, = socket.recvfrom_nonblock(BUFFER_SIZE)
    if data.nil?
      unregister(socket)
      socket.close
      return
    end
    register(socket, :write, ->(s) { on_write(s, data) })
  rescue IO::WaitReadable
    puts 'failed to read'
  end

  def on_write(socket, message)
    resp = "Thanks for ordering #{message.strip} pizzas!"
    puts "Sending message to #{socket}"

    socket.write_nonblock(resp)

    register(socket, :read, ->(c) { on_read(c) })
  rescue IO::WaitWritable
    puts 'failed to write'
  end

  # def serve(conn)
  #   loop do
  #     data, = conn.recvfrom_nonblock(BUFFER_SIZE)
  #     break if data.nil?
  #
  #     conn.puts "Thanks for ordering #{data.strip} pizzas!"
  #     puts "Responded to #{conn.inspect}"
  #   end
  # rescue IO::WaitReadable
  #   sleep 1
  #   puts 'No data to read. Retrying...'
  # end
end

event_loop = EventLoop.new
Server.new(event_loop).start
event_loop.run
