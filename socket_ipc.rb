# frozen_string_literal: true

require 'socket'
require 'fileutils'
SOCKET_PATH = '/tmp/ruby_socket'
BUFFER_SIZE = 1024

def reciever
  Thread.current.name = 'Reciever'
  server = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM)
  server.bind(Socket.pack_sockaddr_un(SOCKET_PATH))
  # here we are lsitening for connections not just messages
  # need to listen and accept a connection first before we
  # can get messages
  server.listen(1)

  puts "#{Thread.current.name} is waiting for a connection..."
  conn, = server.accept

  loop do
    # recvfrom is a bit unclear to me, all the messages
    # are quued up at once by why does it rec them oe by one?
    data, = conn.recvfrom(BUFFER_SIZE)
    break if data.nil?

    puts "#{Thread.current.name} received: '#{data.chomp}'"
  end
ensure
  server.close
end

def sender
  Thread.current.name = 'Sender'
  client = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM)
  client.connect(Socket.pack_sockaddr_un(SOCKET_PATH))
  msg = "Hello from #{Thread.current.name}!"
  msg.split(' ').each { client.puts(it) }
ensure
  client.close
end

FileUtils.rm_rf(SOCKET_PATH) if File.exist?(SOCKET_PATH)

t1 = Thread.new { reciever }
sleep 1
t2 = Thread.new { sender }

t1.join
t2.join
FileUtils.rm_rf(SOCKET_PATH) if File.exist?(SOCKET_PATH)
