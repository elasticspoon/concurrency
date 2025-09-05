
# frozen_string_literal: true

require 'socket'
require 'async'
require_relative 'request_handler'

SERVER_PORT = 3000

class AsyncFiberServer
  def initialize(processes:)
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    @processes = processes
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    child_pids = []

    @processes.times do
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
      Async do |task|
        loop do
          connection = @server.accept

          # Spawn a new async task for each connection
          task.async do
            @handler.handle(connection)
          ensure
            connection.close
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  processes = ENV.fetch('WEB_CONCURRENCY', 10).to_i
  server = AsyncFiberServer.new(processes:)
  server.start
end
