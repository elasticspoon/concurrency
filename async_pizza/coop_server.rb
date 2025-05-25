require_relative './event_loop'
require_relative './async_socket'
require 'socket'

ADDRESS = ['127.0.0.1', 3000].freeze
BUFFER_SIZE = 1024

class Server
  attr_reader :event_loop, :server_socket

  def initialize(event_loop)
    @event_loop = event_loop
    puts 'Starting server...'
    socket = Socket.new(Socket::PF_INET, Socket::SOCK_STREAM)
    socket.bind(Addrinfo.tcp(*ADDRESS))
    socket.listen(5)
    @server_socket = socket

    @socket = AsyncSocket.new(socket)
  end

  def start
    puts 'Listening for connections'
    Fiber.new do
      loop do
        socket, = Fiber.yield(@socket.accept)
        event_loop.add_task(serve(AsyncSocket.new(socket)))
      end
    end
  end

  def serve(socket)
    Fiber.new do
      loop do
        data = Fiber.yield socket.recv(BUFFER_SIZE)

        break if data.nil?

        Fiber.yield socket.send(data)
      end
    end
  end
end

event_loop = EventLoop.new
server = Server.new(event_loop)

Signal.trap('INT') do
  puts server.server_socket.close
end

begin
  event_loop.add_task(server.start)
  event_loop.loop
ensure
  puts server&.server_socket&.close
end
