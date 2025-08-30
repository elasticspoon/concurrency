# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

SERVER_PORT = 3000

class Server
  def initialize
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    loop do
      connection = @server.accept
      handler.handle(connection)
      connection.close
    end
  end
  private attr_reader :handler
end

server = Server.new
server.start
