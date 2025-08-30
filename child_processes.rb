# frozen_string_literal: true

def run_child
  puts "Child process started with PID: #{Process.pid}"
  puts "Child parent PID: #{Process.ppid}"
end

def start_parent(number_of_children)
  puts "Parent process started with PID: #{Process.pid}"
  number_of_children.times { Process.fork { run_child } }
end

start_parent 3
