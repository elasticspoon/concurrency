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
      sleep 1 if ENV['SLOW']
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

      #{body}
    RESP

    conn.write(http_response)
    puts "Responded to #{conn.inspect}"
  end
end

server = Server.new
server.start
