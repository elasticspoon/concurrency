# frozen_string_literal: true

require_relative './future'

class AsyncSocket
  attr_accessor :socket

  def initialize(socket)
    @socket = socket
  end

  def recv(buffsize)
    future = Future.new

    handle_yield = lambda do |loop, task|
      data = socket.recv_nonblock(buffsize)
      loop.add_ready(task, msg: data)
    rescue IO::WaitReadable
      loop.register_reader(socket, task, future)
    end

    future.callback = handle_yield
    future
  end

  def send(data)
    future = Future.new

    handle_yield = lambda do |loop, task|
      data = socket.write_nonblock(data)
      loop.add_ready(task, msg: data)
    rescue IO::WaitWritable
      loop.register_writer(socket, task, future)
    end

    future.callback = handle_yield
    future
  end

  def accept
    future = Future.new

    handle_yield = lambda do |loop, task|
      reader = socket.accept_nonblock
      loop.add_ready(task, msg: reader)
    rescue IO::WaitReadable
      loop.register_reader(socket, task, future)
    end

    future.callback = handle_yield
    future
  end

  def close
    future = Future.new

    handle_yield = proc do
      socket.close
    end

    future.callback = handle_yield
    future
  end

  def name
    @socket.fileno
  end
end
