# frozen_string_literal: true

require 'socket'

ADDRESS = ['127.0.0.1', 3000].freeze
BUFFER_SIZE = 1024

class Server
  def initialize
    puts 'Starting server...'
    @server = Socket.new(Socket::PF_INET, Socket::SOCK_STREAM)
    @server.bind(Addrinfo.tcp(*ADDRESS))
    @server.listen(5)
    @connections = Set.new
    puts "server is a #{@server.class} #{@server.object_id}"
  end

  def accept
    conn, = @server.accept_nonblock
    puts "conn is a #{conn.class}, #{conn.object_id}"
    puts 'Connected to client...'
    @connections << conn
  rescue IO::WaitReadable
    sleep 1
    puts 'No connection to accept. Retrying...'
  end

  def serve(conn)
    loop do
      data, = conn.recvfrom_nonblock(BUFFER_SIZE)
      break if data.nil?

      respond(conn, data)
      puts "Responded to #{conn.inspect}"
    end
  rescue IO::WaitReadable
    sleep 1
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

  def response(conn, data)
    body = "Thanks for ordering #{data.strip} pizzas!"
    http_response = <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      #{body}
    RESP

    conn.write(http_response)
  end
end

server = Server.new
server.start
