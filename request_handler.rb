# frozen_string_literal: true

class RequestHandler
  BUFFER_SIZE = 1024

  def handle(connection)
    data, = connection.recv_nonblock(BUFFER_SIZE)
    return if data.nil?

    path = parse_request_path(data)

    case path
    when '/cpu'
      connection.write(cpu_response)
    when '/sleep'
      connection.write(sleep_response)
    else
      connection.write(default_response)
    end
  rescue IO::WaitReadable
    retry
  end

  private

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
    # sleep 0.05
    <<~RESP
      HTTP/1.1 200 OK
      Content-Type: text/plain

      Default response: #{fibonacci(40000)}
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
