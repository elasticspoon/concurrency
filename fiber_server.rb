# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

SERVER_PORT = 3000

class FiberServer
  def initialize
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    @fibers = []
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    # Enable fiber scheduler for non-blocking IO
    Fiber.set_scheduler(IO::Scheduler.new)

    trap(:INT) do
      puts "Shutting down fiber server..."
      @fibers.each(&:kill)
      exit
    end

    # Main server loop running in a fiber
    Fiber.schedule do
      loop do
        connection = @server.accept
        
        # Spawn a new fiber for each connection
        fiber = Fiber.schedule do
          handle_connection(connection)
        end
        
        @fibers << fiber
      end
    end

    # Keep the main thread alive
    sleep
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
  server = FiberServer.new
  server.start
end