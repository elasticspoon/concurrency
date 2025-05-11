require 'socket'

ADDRESS = ['127.0.0.1', 3000].freeze
BUFFER_SIZE = 1024

class Server
  def initialize
    puts "Starting server..."
    @server = Socket.new(Socket::PF_INET, Socket::SOCK_STREAM)
    @server.bind(Addrinfo.tcp(*ADDRESS))
    @server.listen(5)
    puts "server is a #{@server.class} #{@server.object_id}"
  end

  def accept
    conn, addr = @server.accept
    puts "conn is a #{conn.class}, #{conn.object_id}"
    puts "Connected to client..."
    conn
  end

  def serve(conn)
    loop do
      data, _ = conn.recvfrom(BUFFER_SIZE)
      break if data.nil?

      conn.puts "Thanks for ordering #{data.strip} pizzas!"
    end
  ensure
    conn.close
  end

  def start
    loop do
      conn = accept
      serve(conn)
    end
  ensure
    @server.close
  end
end

server = Server.new
server.start
