# frozen_string_literal: true

queue = Thread::Queue.new

def read_from_queue(queue)
  until queue.empty?
    puts 'Reading from queue...'
    item = queue.pop
    puts "Got #{item}"
    sleep 2
  end
ensure
  puts 'Reader finished'
  queue.close
end

10.times { |i| queue << i }
threads = (1..4).map { Thread.new { read_from_queue(queue) } }

threads.each(&:join)
