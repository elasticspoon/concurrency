---
theme: uncover
class: invert
paginate: false
size: 4k
---

# Concurrency in Ruby: From `fork()` to Fiber

---

```yaml
workers:
  - queues: [critical]
    threads: 20
    processes: 1
  - queues: ["default", "low"]
    threads: 3
    processes: 1
```

---

## Your Speaker

- Yuri Bocharov
- U.S. Citizenship and Immigration Services (USCIS)
- Software Developer (5 years)
- Platform / Infrastructure

---

## Talk Overview

- Why that config didn't work as expected.
- What is concurrency
- Three main concurrency primitives
- How concurrency primitives are used

---

## Web Server

---

## Main Loop

```rb
require 'socket'

class Server
  def initialize(port:)
    @server = TCPServer.new(port)
  end

  def start
    loop do
      connection = @server.accept
      handle(connection)
      connection.close
    end
  end

  # ....
end

server = Server.new(port: 3000)
server.start
```

---

## Handling a Connection

```rb
def handle(connection)
  data, = connection.recv_nonblock(BUFFER_SIZE)
  return if data.nil?

  sleep 0.05
  response_payload = fibonacci(4000)

  <<~RESP
    HTTP/1.1 200 OK
    Content-Type: text/plain

    Response: #{response_payload}
  RESP
rescue IO::WaitReadable
  retry
end
```

---

```rb
data, = connection.recv_nonblock(BUFFER_SIZE)
```

---

```rb
sleep 0.05
```

---

```rb
response_payload = fibonacci(4000)
```

---

```rb
<<~RESP
  HTTP/1.1 200 OK
  Content-Type: text/plain

  Response: #{response_payload}
RESP
```

---

chart current web server perf

---

## Concurrency

---

## What is Concurrency?

Concurrency is **dealing** with more than one task at a time.

---

## Cooking

---

![stove top with pasta]()

---

![stove top with pasta and pan with saute]()

---

![stove top with pasta and pan with saute and chopping onion]()

---

## What is Parallelism?

---

Parallelism is taking more than one **action** at a time.

---

![chopping onion and carrot]()

---

![chopping onion and carrot with friend]()

---

![chopping onion and carrot with 4 arms]()

---

## Parallelism Requires Hardware

---

### Recap: Concurrency vs Parallelism

> "Concurrency is about **dealing with** lots of things at once. Parallelism is about **doing** lots of things at once." - Rob Pike

---

![diagram of serial server]()

---

![diagram of parallel server]()

---

## 3 Concurrency Primitives

- **Process** (`Process`)
- **Thread** (`Thread`)
- **Coroutine** (`Fiber`)

---

## Process

OS Construct that runs a program.

---

```console
$ > ps aux
USER               PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
yuri              7984  15.4  4.9 422528096 816336   ??  S     5:09PM   0:16.76 /Applications/Firefox.app/Contents
yuri             95161  12.6  1.7 413454080 287968   ??  S    11:54AM   3:31.54 /Applications/Firefox.app/Contents
yuri             75448  11.1  1.3 1865978544 210464   ??  S    11:57PM  28:51.86 /Applications/Google Chrome.app/Co
yuri              1363   6.9  0.4 413137872  72832   ??  S    26Aug25  35:21.03 /Applications/Ghostty.app/Contents
```

---

```console
$ > ps aux | rg ruby
yuri             34952   0.0  0.0 412642304   2912   ??  Ss   Tue02PM   0:03.12 /Users/yuri/.local/share/mise/installs/ruby/3.4.5/bin/ruby-lsp
yuri              8516   0.0  0.0 410065616    224 s013  S+    5:36PM   0:00.00 rg ruby
```

---

## Ruby Process

```rb
fork do
  # do stuff
end
```

---

## Processes Can Parallelize Work

```rb
2.times do
  fork do
    generate_pdf
  end
end
```

---

```console
$ > ps aux | rg ruby
yuri             34952   0.0  0.0 412642304   2912   ??  Ss   Tue02PM   0:03.12 /Users/yuri/.local/share/mise/installs/ruby/3.4.5/bin/ruby-lsp
yuri              8599   0.0  0.0 410065616    224 s013  R+    5:37PM   0:00.00 rg ruby
yuri              8588   0.0  0.0 411326560   2368 s025  S+    5:37PM   0:00.00 ruby pdf_generation.rb
yuri              8587   0.0  0.0 411317344   2352 s025  S+    5:37PM   0:00.00 ruby pdf_generation.rb
yuri              8586   0.0  0.1 411317600  13088 s025  S+    5:37PM   0:00.05 ruby pdf_generation.rb
```

---

![three process no cpu](./triple-process-generation.svg)

---

## How do we use this?

---

![forking per request server diagram]()

---

```rb
fork do
  handle(connection)
  connection.close
end
```

---

```rb
def start
  loop do
    connection = @server.accept

    pid = fork do
      handle(connection)
    ensure
      connection.close
    end

    connection.close
    Process.detach(pid)
  end
end
```

---

## Is it good?

---

![process per connection](./process-per-connection.svg)

---

<style scoped>
img {
  width: 400px;
}
</style>

## Process Internals

![Process Internals](./process-internals.svg)

---

<style scoped>
img {
  width: 600px;
}
</style>

![process fork](./forked-process.svg)

---

![real single threaded app](./single-thread-real-app.svg)

---

## Don't Forget the Hardware Requirement

---

![two process two cpu](./two-pdf-gen-two-cpu.svg)

---

![two process one cpu](./two-pdf-gen-one-cpu.svg)

---

## Preforking Server

```rb
def start
  PROCESS_COUNT.times do
    fork do
      loop do
        connection = @server.accept
        handler.handle(connection)
        connection.close
      end
    end
  end
end
```

---

![prefork server diagram]()

---

## Impact

Optimal Preforking Server RPS vs Process Per Request

---

## Summary: Processes

- Allow True Parallelism
- One Process Per CPU Core

---

## Threads

---

<style scoped>
img {
  width: 1000px;
}
</style>

![single thread diagram](./single-thread-diagram.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![multi thread diagram](./multi-thread-diagram.svg)

---

```rb
Thread.new do
  # do_work
end
```

---

```rb
time = Benchmark.realtime do
  sleep 2
  sleep 2
  sleep 2
end
puts "Serial sleep took #{time} seconds"
# => Serial sleep took 6.012791999964975 seconds
```

---

```rb
time = Benchmark.realtime do
  threads = []
  threads << Thread.new { sleep 2 }
  threads << Thread.new { sleep 2 }
  threads << Thread.new { sleep 2 }
  threads.each(&:join)
end
puts "Parallel sleep took #{time} seconds"
# => Parallel sleep took 2.004996999981813 seconds
```

---

## So why even use `Process`?

---

```rb
time = Benchmark.realtime do
  fibonacci 300_000
  fibonacci 300_000
  fibonacci 300_000
end
puts "Serial fibonacci took #{time} seconds"
# => Serial fibonacci took 3.3579959999769926 seconds
```

---

```rb
time = Benchmark.realtime do
  threads = []
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads.each(&:join)
end
puts "Parallel fibonacci took #{time} seconds"
```

---

```rb
time = Benchmark.realtime do
  threads = []
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads << Thread.new { fibonacci 300_000 }
  threads.each(&:join)
end
puts "Parallel fibonacci took #{time} seconds"
#=> Parallel fibonacci took 3.330549000063911 seconds
```

---

## Global VM Lock (GVL)

---

<style scoped>
img {
  width: 400px;
}
</style>

![gvl scaring patrick](./gvl-spooky.jpg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl](./gvl-0.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl](./gvl-1.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl with lock moved to second thread](./gvl-2.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl with lock moved to third thread](./gvl-3.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl with 3 sleeps](./gvl-5.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![diagram of gvl with lock and non blocking work](./gvl-with-io.svg)

---

## What does this mean?

---

- More threads != more better
- Amount of threads you need depends

---

### Server Model: The Thread Pool

---

![thread pool diagram]()

---

```rb
def start
  THREAD_COUNT.times do
    Thread.new do
      loop do
        connection = @server.accept
        handler.handle(connection)
        connection.close
      end
    end
  end
end
```

---

pure threadpool impact

---

![preforking thread pool diagram]()

---

### Server Model: Prefork + Threads

---

```rb
def start
  PROCESS_COUNT.times do
    fork do
      THREAD_COUNT.times do
        Thread.new do
          loop do
            connection = @server.accept
            handler.handle(connection)
            connection.close
          end
        end
      end
    end
  end
end
```

---

## How many?

---

show graph

---

## Puma

---

![puma worker threadpool diagram overview](./puma-general-arch-official.png)

---

![puma worker details](./puma-worker-diagram.png)

---

## Threads Recap

- Threads are light weight and can share memory
- Ruby code (when using CRuby) runs concurrently with threads
- IO / Kernel level code runs in parallel

---

## Coroutine (`Fiber`)

---

![diagram of fibers within a thread]()

---

thread containing many fibers diagram

---

code to start a fiber

---

## Fibers are cooperative

---

<style scoped>
img {
  width: 1000px;
}
</style>

![gvl-scheduling-1 diagram](./gvl-scheduling-1.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![gvl-scheduling-2 diagram](./gvl-scheduling-2.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![gvl-scheduling-3 diagram](./gvl-scheduling-3.svg)

---

drawing of young kids all being given a turn on the ipad

---

## Fiber are cooperative

---

drawing of millennials sharing a game console

---

yielding from a fiber code

---

what does that mean?

---

delegating to thread pool diagram

---

fiber per connection diagram

---

## Drawbacks?

- Bad actors
- Incompatibility of some gems

---

## Final Stats?

---

## Recap: Fibers

- cooperative not preemptive
- cheap AF

---

## So, About That Config

```yaml
workers:
  - queues: [critical]
    threads: 20 # <- The problem child
    processes: 1
```

Why was this ineffective for CPU-bound work in Ruby? **The GVL.**

---

## Conclusion: Know Your Tools

- **Process:** Great for safety and CPU-bound parallelism.
- **Thread:** Great for I/O-bound work (database calls, APIs).
- **Fiber:** Best for massive I/O concurrency.

---

## Thank You

Questions?

---

# Outtakes?

## OS level versus Application level

---

<style scoped>
img {
  width: 600px;
}
</style>

![Diagram of user level vs kernel level](./user-vs-kernel-diagram.png)

---

![meme of user space hiding kernel space ugliness](./user-vs-kernel-meme.jpg)

---

![tracing a file.write call from user space to kernel](./user-vs-kernel-file-write.png)

---

---
