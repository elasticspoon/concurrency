# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

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
      start_threads
    end
  end

  def start_threads
    Thread.abort_on_exception = true
    threads = ThreadGroup.new

    @threads.times do
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
  processes = ENV.fetch('WEB_CONCURRENCY', 3).to_i
  threads = ENV.fetch('RAILS_THREADS', 3).to_i
  server = Server.new(threads:, processes:)
  server.start
end
