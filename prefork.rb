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
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    child_pids = []

    CONCURRENCY.times do
      child_pids << spawn_child
    end

    trap(:INT) do
      child_pids.each do |cpid|
        Process.kill(:INT, cpid)
      rescue Errno::ESRCH
      end

      exit
    end

    loop do
      pid = Process.wait
      warn "Process #{pid} quit unexpectedly"

      child_pids.delete(pid)
      child_pids << spawn_child
    end
  end

  def spawn_child
    fork do
      loop do
        connection = @server.accept

        handler.handle(connection)
        connection.close
      end
    end
  end
  private attr_reader :handler
end

server = Server.new
server.start
