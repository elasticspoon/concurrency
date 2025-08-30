# frozen_string_literal: true

require_relative 'multiprocessing/mutex'

class ThreadSafetyTest
  def initialize(thread_count: 10, iterations: 1000)
    @thread_count = thread_count
    @iterations = iterations
  end

  def test_with_mutex
    counter = 0
    MutexDeadlockTogether.new
    mutex = MutexDeadlockTogether.new
    threads = []

    puts "\nTesting WITH mutex (#{@thread_count} threads, #{@iterations} iterations each)"

    @thread_count.times do |i|
      threads << Thread.new do
        Thread.current.name = i.to_s
        @iterations.times do
          mutex.synchronize do
            # Simulate some work within the protected section
            value = counter
            sleep(0.000001) # Tiny sleep
            counter = value + 1
          end
        end
        print "T#{i} "
      end
    end

    threads.each(&:join)
    puts "\nFinal counter with mutex: #{counter}"
    puts "Expected value: #{@thread_count * @iterations}"
    puts "Difference: #{@thread_count * @iterations - counter}"
    counter
  end

  def run
    puts '=' * 60
    puts 'Thread Safety Test with Mutex'
    puts '=' * 60

    test_with_mutex
  end
end

# Run the test with default parameters
if __FILE__ == $PROGRAM_NAME
  test = ThreadSafetyTest.new(thread_count: 2, iterations: 10_000)
  test.run
end
