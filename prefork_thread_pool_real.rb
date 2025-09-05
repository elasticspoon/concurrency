# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'
require_relative 'async_pizza/thread_pool'

SERVER_PORT = 3000

class Server
  def initialize(processes:, threads:)
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    @processes = processes
    @threads = threads
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    child_pids = []

    @processes.times do
      child_pids << spawn_child(@threads)
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
      child_pids << spawn_child(@threads)
    end
  end

  def spawn_child(thread_count)
    fork do
      thread_pool = ThreadPool.new(thread_count)

      loop do
        connection = @server.accept

        thread_pool.add_task(connection) do |conn|
          @handler.handle(conn)
          connection.close
        end
      end
    end
  end
end

if __FILE__ == $0
  processes = ENV.fetch('WEB_CONCURRENCY', 3).to_i
  threads = ENV.fetch('RAILS_THREADS', 3).to_i
  server = Server.new(threads:, processes:)
  server.start
end
