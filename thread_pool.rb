# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

SERVER_PORT = 3000
CONCURRENCY = 10

class Server
  def initialize
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    trap(:INT) { exit }
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    Thread.abort_on_exception = true
    threads = ThreadGroup.new

    CONCURRENCY.times do
      threads.add spawn_thread
    end

    sleep
  end

  def spawn_thread
    Thread.new do
      loop do
        connection = @server.accept
        $stdout.puts 'accepting...'
        $stdout.flush

        handler.handle(connection)
        connection.close
      end
    end
  end

  private attr_reader :handler
end

server = Server.new
server.start
