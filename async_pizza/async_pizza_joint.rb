# frozen_string_literal: true

require_relative './event_loop'
require_relative './async_socket'
require 'socket'

ADDRESS = ['127.0.0.1', 3000].freeze
BUFFER_SIZE = 1024

class Kitchen
  def self.cook_pizza(count)
    puts "Started cooking #{count} pizzas..."
    sleep count
    puts "Fresh #{count} pizzas are ready!"
  end
end

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
        event_loop.add_unready(serve(AsyncSocket.new(socket)))
      end
    end
  end

  def serve(socket)
    Fiber.new do
      loop do
        Fiber.yield socket.send('How many pizzas would you like to order?')

        data = Fiber.yield socket.recv(BUFFER_SIZE)

        break if data.nil?

        Fiber.yield socket.send("Thank you for ordering #{data.strip} pizzas!")
        Fiber.yield(event_loop.run_async(Integer(data.strip)) do |count|
          Kitchen.cook_pizza(count)
        end)
        Fibr.yield socket.send("Your #{data.strip} pizzas are ready!")
      end
      puts "Closing #{socket.name}."
      socket.close
    end
  end
end

event_loop = EventLoop.new
server = Server.new(event_loop)

Signal.trap('INT') do
  puts server.server_socket.close
end

begin
  event_loop.add_unready(server.start)
  event_loop.loop
ensure
  puts server&.server_socket&.close
end
