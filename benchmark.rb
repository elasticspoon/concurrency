#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'json'

class Benchmark
  SERVER_PORT = 3000
  BENCHMARK_URL = "http://localhost:#{SERVER_PORT}/"
  
  def initialize(server:, 
                 process_counts: [1],
                 thread_counts: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                 requests_per_test: 1000,
                 bench_concurrency: 8)
    @process_counts = process_counts
    @thread_counts = thread_counts
    @requests_per_test = requests_per_test
    @server = server
    @results = {}
  end

  def run
    puts "Starting server benchmarking..."
    puts "Testing process counts: #{@process_counts.join(', ')}"
    puts "Testing thread counts: #{@thread_counts.join(', ')}"
    puts "Fixed benchmark: #{@requests_per_test} requests with #{@bench_concurrency} concurrency"
    puts "-" * 60

    @process_counts.each do |process_count|
      @thread_counts.each do |thread_count|
        bench_concurrency = process_count * thread_count * 10
        benchmark_configuration(process_count, thread_count, bench_concurrency)
      end
    end

    save_results
    display_summary
  end

  private

  def benchmark_configuration(process_count, thread_count, bench_concurrency)
    config_key = "p#{process_count}_t#{thread_count}"
    puts "\nTesting with #{process_count} processes, #{thread_count} threads..."
    
    # Start server in background
    server_pid = start_server(process_count, thread_count)
    
    # Wait for server to start
    sleep 2
    
    # Run Apache bench
    result = run_apache_bench(bench_concurrency)
    
    # Stop server
    stop_server(server_pid)
    
    # Parse and store results
    @results[config_key] = {
      process_count: process_count,
      thread_count: thread_count,
      metrics: parse_ab_output(result)
    }
    
    puts "Completed: #{process_count}p/#{thread_count}t - #{@results[config_key][:metrics][:requests_per_second]} req/s"
  end

  def start_server(process_count, thread_count)
    spawn("docker", "run",
          "-p", "3000:3000", 
          "-e", "WEB_CONCURRENCY=#{process_count}",
          "-e", "RAILS_THREADS=#{thread_count}",
          "--ulimit", "nofile=5000:5000",
          "--rm", "ruby-server",
          "ruby", @server,
           out: "/dev/null", err: "/dev/null")
  end

  def stop_server(pid)
    Process.kill('TERM', pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    # Process already dead
  end

  def run_apache_bench(bench_concurrency)
    command = "ab -n #{@requests_per_test} -c #{bench_concurrency} #{BENCHMARK_URL}"
    
    stdout, stderr, status = Open3.capture3(command)
    
    unless status.success?
      puts "Apache bench failed: #{stderr}"
      return ""
    end
    
    stdout
  end

  def parse_ab_output(output)
    result = {}
    
    # Parse key metrics from ab output
    if output.match(/Requests per second:\s+(\d+\.?\d*)/)
      result[:requests_per_second] = $1.to_f
    end
    
    if output.match(/Time per request:\s+(\d+\.?\d*).*mean\)/)
      result[:time_per_request_ms] = $1.to_f
    end
    
    if output.match(/Transfer rate:\s+(\d+\.?\d*)/)
      result[:transfer_rate_kbps] = $1.to_f
    end
    
    if output.match(/50%\s+(\d+)/)
      result[:p50_latency_ms] = $1.to_i
    end
    
    if output.match(/90%\s+(\d+)/)
      result[:p90_latency_ms] = $1.to_i
    end
    
    if output.match(/99%\s+(\d+)/)
      result[:p99_latency_ms] = $1.to_i
    end
    
    result
  end

  def save_results
    # Also save CSV for easy graphing
    csv_data = "process_count,thread_count,requests_per_second,time_per_request_ms,transfer_rate_kbps,p50_latency_ms,p90_latency_ms,p99_latency_ms\n"
    @results.each do |config_key, result|
      metrics = result[:metrics]
      csv_data += "#{result[:process_count]},#{result[:thread_count]},#{metrics[:requests_per_second]},#{metrics[:time_per_request_ms]},#{metrics[:transfer_rate_kbps]},#{metrics[:p50_latency_ms]},#{metrics[:p90_latency_ms]},#{metrics[:p99_latency_ms]}\n"
    end
    
    File.write("#{@server}_benchmark_results.csv", csv_data)
  end

  def display_summary
    puts "\n" + "=" * 60
    puts "BENCHMARK SUMMARY"
    puts "=" * 60
    
    puts "\nTop performing configurations:"
    puts "Processes\tThreads\tReq/s\t\tLatency (p99 ms)"
    puts "-" * 60
    
    # Sort by requests per second descending
    sorted_results = @results.sort_by { |_, result| -result[:metrics][:requests_per_second] }
    
    sorted_results.first(10).each do |config_key, result|
      metrics = result[:metrics]
      puts "#{result[:process_count]}\t\t#{result[:thread_count]}\t\t#{metrics[:requests_per_second].round(1)}\t\t#{metrics[:p99_latency_ms]}"
    end
    
    puts "\nResults saved to #{@server}_benchmark_results.json and #{@server}_benchmark_results.csv"
    puts "Use the CSV file for easy graphing with tools like Excel, Google Sheets, or Python pandas"
  end
end

# Run benchmark if executed directly
if __FILE__ == $0
  # Allow customization via command line arguments
  server = ARGV[0]
  process_counts = ARGV[1] ? ARGV[1].split(',').map(&:to_i) : [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24]
  thread_counts = ARGV[2] ? ARGV[2].split(',').map(&:to_i) : [1, 2, 4, 8, 16, 32, 48, 64, 80, 96, 112]
  
  benchmark = Benchmark.new(
    server: server,
  )
  
  benchmark.run
end
