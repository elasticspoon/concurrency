# frozen_string_literal: true

require 'socket'
require 'async'
require_relative 'request_handler'

SERVER_PORT = 3000

class AsyncFiberServer
  def initialize
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    Async do |task|
      trap(:INT) do
        puts "Shutting down async fiber server..."
        task.stop
        exit
      end

      loop do
        connection = @server.accept
        
        task.async do
          @handler.handle(connection)
        ensure
          connection.close
        end
      end
    end
  end
end

if __FILE__ == $0
  server = AsyncFiberServer.new
  server.start
end
