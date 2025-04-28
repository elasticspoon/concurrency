reader, writer = IO.pipe

def write_to_pipe(writer)
  puts 'Writing to pipe...'
  writer.write("Hello from the writer!\n")
ensure
  writer.close
end

def read_from_pipe(reader)
  puts 'Reading from pipe...'
  puts "Got #{reader.read}"
ensure
  reader.close
end

threads = [
  Thread.new do
    Thread.current.name = 'Producer'
    read_from_pipe(reader)
  end,
  Thread.new do
    Thread.current.name = 'Consumer'
    write_to_pipe(writer)
  end
]

threads.each(&:join)
