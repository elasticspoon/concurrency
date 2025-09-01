# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

SERVER_PORT = 3000

class Server
  def initialize(threads:)
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @concurrency = threads
    @handler = RequestHandler.new
    trap(:INT) { exit }
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    Thread.abort_on_exception = true
    threads = ThreadGroup.new

    @concurrency.times do
      threads.add spawn_thread
    end

    sleep
  end

  def spawn_thread
    Thread.new do
      loop do
        connection = @server.accept
        handler.handle(connection)
        connection.close
      end
    end
  end

  private attr_reader :handler
end

if __FILE__ == $0
  _processes = ARGV[0] ? ARGV[0].to_i : 1
  threads = ARGV[1] ? ARGV[1].to_i : 3
  server = Server.new(threads:)
  server.start
end
