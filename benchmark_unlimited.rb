#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'json'

class PreforkBenchmark
  SERVER_PORT = 3000
  BENCHMARK_URL = "http://localhost:#{SERVER_PORT}/"
  
  def initialize(server:, 
                 server_concurrency: 10,
                 requests_per_test: 1000,
                 bench_concurrency_levels: [1, 2, 4])
    @server_concurrency = server_concurrency
    @requests_per_test = requests_per_test
    @bench_concurrency_levels = bench_concurrency_levels
    @server = server
    @results = {}
  end

  def run
    puts "Starting prefork server benchmarking..."
    puts "Server concurrency: #{@server_concurrency} processes"
    puts "Requests per test: #{@requests_per_test}"
    puts "Benchmark concurrency levels: #{@bench_concurrency_levels.join(', ')}"
    puts "-" * 60

    @bench_concurrency_levels.each do |bench_concurrency|
      benchmark_concurrency(bench_concurrency)
    end

    save_results
    display_summary
  end

  private

  def benchmark_concurrency(bench_concurrency)
    puts "\nTesting with #{bench_concurrency} concurrent requests..."
    
    # Start server in background
    server_pid = start_server
    
    # Wait for server to start
    sleep 2
    
    # Run Apache bench
    result = run_apache_bench(bench_concurrency)
    
    # Parse and store results
    @results[bench_concurrency] = parse_ab_output(result)
    
    puts "Completed: #{bench_concurrency} concurrent requests - #{@results[bench_concurrency][:requests_per_second]} req/s"
  ensure
    stop_server(server_pid)
  end

  def start_server
    spawn("docker", "run", "-p", "3000:3000", "--memory=1g", "--cpus=4", "--oom-kill-disable", "--rm", "ruby-server", "ruby", @server, @server_concurrency.to_s, out: "/dev/null", err: "/dev/null")
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
    File.write("#{@server}_benchmark_results.json", JSON.pretty_generate({
      timestamp: Time.now.iso8601,
      parameters: {
        server_concurrency: @server_concurrency,
        requests_per_test: @requests_per_test,
        bench_concurrency_levels: @bench_concurrency_levels
      },
      results: @results
    }))
    
    # Also save CSV for easy graphing
    csv_data = "bench_concurrency,requests_per_second,time_per_request_ms,transfer_rate_kbps,p50_latency_ms,p90_latency_ms,p99_latency_ms\n"
    @results.each do |bench_concurrency, metrics|
      csv_data += "#{bench_concurrency},#{metrics[:requests_per_second]},#{metrics[:time_per_request_ms]},#{metrics[:transfer_rate_kbps]},#{metrics[:p50_latency_ms]},#{metrics[:p90_latency_ms]},#{metrics[:p99_latency_ms]}\n"
    end
    
    File.write("#{@server}_benchmark_results.csv", csv_data)
  end

  def display_summary
    puts "\n" + "=" * 60
    puts "BENCHMARK SUMMARY"
    puts "=" * 60
    
    puts "\nBenchmark Concurrency vs Requests per Second:"
    puts "Concurrency\tReq/s\t\tLatency (p99 ms)"
    puts "-" * 50
    
    @results.each do |bench_concurrency, metrics|
      puts "#{bench_concurrency}\t\t#{metrics[:requests_per_second].round(1)}\t\t#{metrics[:p99_latency_ms]}"
    end
    
    puts "\nResults saved to #{@server}_benchmark_results.json and #{@server}_benchmark_results.csv"
    puts "Use the CSV file for easy graphing with tools like Excel, Google Sheets, or Python pandas"
  end
end

# Run benchmark if executed directly
if __FILE__ == $0
  # Allow customization via command line arguments
  server = ARGV[0]
  requests = ARGV[1] ? ARGV[1].to_i : 1000
  bench_concurrency_levels = ARGV[2] ? ARGV[2].split(',').map(&:to_i) : [50]
  
  benchmark = PreforkBenchmark.new(
    server: server,
    requests_per_test: requests,
    bench_concurrency_levels: bench_concurrency_levels
  )
  
  benchmark.run
end
