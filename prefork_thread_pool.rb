require 'socket'
require 'thread'
require_relative 'request_handler'

SERVER_PORT = 3000
WORKERS = 10
THREADS = 10

class Server
  def initialize
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    @handler = RequestHandler.new
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    child_pids = []

    WORKERS.times do
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

    THREADS.times do
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
