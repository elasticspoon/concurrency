require 'socket'

SERVER_PORT = 3000
BUFFER_SIZE = 1024

class Server
  def initialize
    # Create the underlying server socket.
    @server = TCPServer.new(SERVER_PORT)
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    Socket.accept_loop(@server) do |connection|
      handle(connection)
      connection.close
    end
  end

  def handle(conn)
    data, = conn.recv_nonblock(BUFFER_SIZE)
    return if data.nil?

    conn.write(response)
    conn.close
  rescue IO::WaitReadable
    retry
  end

  def response
    <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      #{fibonacci(10_000)}
    RESP
  end

  def blocking_io(_time)
    sleep 2
  end

  def fibonacci(count)
    return count if count <= 1

    a = 0
    b = 1
    (2..count).each do
      a, b = b, a + b
    end
    b
  end
end

server = Server.new
server.start
