# frozen_string_literal: true

SIZE = 5
$shared_mem = Array.new(SIZE) { -1 }

def await_shared_mem
  (0...SIZE).each do |i|
    until $shared_mem[i].positive?
      puts "Thread #{Thread.current.name} waiting for shared memory to be filled"
      sleep 1
    end
    puts "Thread #{Thread.current.name} found shared memory at index #{i} with value #{$shared_mem[i]}"
  end
  puts "Shared mem full. Thread #{Thread.current.name} exiting"
end

def set_shared_mem
  $shared_mem.each_with_index do |_, i|
    $shared_mem[i] = i + 1
    puts "Thread #{Thread.current.name} set shared memory at index #{i} to #{$shared_mem[i]}"
  end
end

threads = [
  Thread.new do
    Thread.current.name = 'Consumer'
    await_shared_mem
  end,
  Thread.new do
    Thread.current.name = 'Producer'
    set_shared_mem
  end
]

threads.each(&:join)
