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

    path = parse_request_path(data)

    case path
    when '/cpu'
      conn.write(cpu_response)
    when '/sleep'
      conn.write(sleep_response)
    else
      conn.write(default_response)
    end

    conn.close
  rescue IO::WaitReadable
    retry
  end

  def parse_request_path(request_data)
    request_line = request_data.lines.first
    return '/' unless request_line

    parts = request_line.split
    parts[1] if parts.size >= 2
  rescue StandardError
    '/'
  end

  def cpu_response
    <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      CPU-intensive work completed: #{fibonacci(10_000)}
    RESP
  end

  def sleep_response
    sleep 2
    <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      Slept for 2 seconds
    RESP
  end

  def default_response
    <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      Default response: #{fibonacci(1000)}
    RESP
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
