# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'
require_relative 'async_pizza/thread_pool'

SERVER_PORT = 3000

class Server
  def initialize(threads:)
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @thread_pool = ThreadPool.new(threads)
    @handler = RequestHandler.new
    trap(:INT) { exit }
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    loop do
      connection = @server.accept

      @thread_pool.add_task(connection) do |conn|
        @handler.handle(conn)
        connection.close
      end
    end
  end
end

if __FILE__ == $0
  threads = ENV.fetch('RAILS_THREADS', 3).to_i
  server = Server.new(threads:)
  server.start
end
