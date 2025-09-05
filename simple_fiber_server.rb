# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

SERVER_PORT = 3000

class SimpleFiberServer
  def initialize
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    @fibers = []
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    trap(:INT) do
      puts "Shutting down fiber server..."
      @fibers.each(&:kill)
      exit
    end

    # Main server loop
    loop do
      connection = @server.accept
      
      # Create a fiber for each connection
      fiber = Fiber.new do
        handle_connection(connection)
      end
      
      # Start the fiber and track it
      fiber.resume
      @fibers << fiber
      
      # Clean up completed fibers
      @fibers.reject!(&:alive?)
    end
  end

  def handle_connection(connection)
    begin
      @handler.handle(connection)
    rescue => e
      puts "Error handling connection: #{e.message}"
    ensure
      connection.close
    end
  end
end

if __FILE__ == $0
  server = SimpleFiberServer.new
  server.start
end