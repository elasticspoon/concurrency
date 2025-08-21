require 'socket'

SERVER_PORT = 3000
BUFFER_SIZE = 1024

class Server
  def initialize
    puts 'Starting server...'
    @server = TCPServer.new(SERVER_PORT)
    @connections = Set.new
  end

  def accept
    conn, = @server.accept_nonblock
    puts "conn is a #{conn.class}, #{conn.object_id}"
    puts 'Connected to client...'
    @connections << conn
  rescue IO::WaitReadable
    puts 'No connection to accept. Retrying...'
  end

  def serve(conn)
    data, = conn.recv_nonblock(BUFFER_SIZE)
    return if data.nil?

    respond(conn, data)
    conn.close
    @connections.delete(conn)
  rescue IO::WaitReadable
    puts 'No data to read. Retrying...'
  end

  def start
    loop do
      accept
      @connections.each { serve(it) }
    end
  ensure
    @server.close
  end

  def respond(conn, data)
    body = "Thanks for ordering #{data.strip} pizzas!"
    http_response = <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      #{fibonacci(10_000)}
    RESP

    conn.write(http_response)
    puts "Responded to #{conn.inspect}"
  end

  def fibonacci(n)
    return n if n <= 1

    a = 0
    b = 1
    (2..n).each do |i|
      a, b = b, a + b
    end
    b
  end
end

server = Server.new
server.start
