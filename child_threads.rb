def cpu_waster
  Thread.current.name = "Cpu-waster #{Thread.current.object_id}"
  sleep 3
  puts "Thread #{Thread.current.name} done"
end

def display_threads
  puts '=' * 20
  puts "Current Process ID: #{Process.pid}"
  puts "Thread count: #{Thread.list.size}"
  puts "Threads: #{Thread.list.map { |t| "#{t.object_id} #{t.name}" }}"
end

display_threads
num_threads = 5
puts "Starting #{num_threads} threads"
thds = (1..num_threads).to_a.map { Thread.new { cpu_waster } }
display_threads
thds.each(&:join)
