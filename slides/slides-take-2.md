---
theme: uncover
class: invert
paginate: false
size: 4k
---

# Concurrency in Ruby: From `fork()` to Fiber

---

<style scoped>
img {
  width: 500px;
}
</style>

![generation of pdfs](./pds.svg)

---

![mailing of pdf](./outgoing-pds.svg)

---

<style scoped>
img {
  width: 1100px;
}
</style>

![pdf-queue](./pdf-queue.svg)

---

```diff
workers:
  - queues: [critical]
-    threads: 3
+    threads: 5
    processes: 1
  - queues: ["default", "low"]
    threads: 3
    processes: 1
```

---

```diff
workers:
  - queues: [critical]
-    threads: 5
+    threads: 10
    processes: 1
  - queues: ["default", "low"]
    threads: 3
    processes: 1
```

---

```diff
workers:
  - queues: [critical]
-    threads: 10
+    threads: 20
    processes: 1
  - queues: ["default", "low"]
    threads: 3
    processes: 1
```

---

<style scoped>
img {
  width: 500px;
}
</style>

![grokking concurrency](./groking-conc.jpg)

---

## Stay Tuned and Find Out

---

## About Me

- Yuri Bocharov
- U.S. Citizenship and Immigration Services (USCIS)
- Platform / Infrastructure

---

## Talk Overview

- What is concurrency
- Three main concurrency primitives
- How concurrency primitives are used
- Why that config didn't work as expected.

---

## Web Server

---

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

  def handle
    # ...
  end
end

server = Server.new(port: 3000)
server.start
```

---

```rb
@server = TCPServer.new(port)
```

---

```rb
loop do
  connection = @server.accept
  handle(connection)
  connection.close
end
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

```rb
server = Server.new(port: 3000)
server.start
```

---

<style scoped>
img {
  width: 1100px;
}
</style>

![serial server diagram](./serial-server.svg)

---

## Performance

|                     | Serial Server | Preforking | Threadpool | Prefork + Threadpool | Fiber | Prefork + Fiber |
| ------------------- | ------------- | ---------- | ---------- | -------------------- | ----- | --------------- |
| Requests per Second | 17.3          | ?          | ?          | ?                    | ?     | ?               |

---

## Concurrency

---

## What is Concurrency?

Concurrency is **dealing** with more than one task at a time.

---

## Cooking

---

![stove top with pasta](./cooking-1task.jpg)

---

![stove top with pasta and pan with saute](./cooking-2tasks.jpg)

---

![stove top with pasta and pan with saute and chopping onion](./cooking-3tasks.jpg)

---

## What is Parallelism?

---

Parallelism is taking more than one **action** at a time.

---

![stove top with pasta and pan with saute and chopping onion](./cooking-3tasks.jpg)

---

![chopping onion and carrot](./tripple-onion-chop.jpg)

---

![chopping onion and carrot with friend](./parellel-onion-chop.jpg)

---

## Parallelism Requires Hardware

---

### Recap: Concurrency vs Parallelism

> "Concurrency is about **dealing with** lots of things at once. Parallelism is about **doing** lots of things at once." - Rob Pike

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

<style scoped>
img {
  width: 1100px;
}
</style>

![diagram of serial server](./serial-server.svg)

---

<style scoped>
img {
  width: 1100px;
}
</style>

![process per connection server](./process-per-connection-1.svg)

---

<style scoped>
img {
  width: 1100px;
}
</style>

![process per connection server](./process-per-connection-2.svg)

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

![real single threaded app](./single-thread-real-app.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![prefork server diagram](./preforking-server-diagram.svg)

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

## Impact

|                     | Serial Server | Preforking | Threadpool | Prefork + Threadpool | Fiber | Prefork + Fiber |
| ------------------- | ------------- | ---------- | ---------- | -------------------- | ----- | --------------- |
| Requests per Second | 17.3          | 448.81     | ?          | ?                    | ?     | ?               |

---

## Real World

- Unicorn
- Pitchfork

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

<style scoped>
img {
  width: 1000px;
}
</style>

![serial server](./serial-server.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![single process multi thread server](./single-process-multithread-server.svg)

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

<style scoped>
img {
  width: 1000px;
}
</style>

![thread pool diagram](./thread-pool-diagram.svg)

---

```rb
def start
  loop do
    connection = @server.accept

    @thread_pool.add_task(connection) do |conn|
      @handler.handle(conn)
      connection.close
    end
  end
end
```

---

```rb
class ThreadPool
  def run
    # ...
    Thread.new do
      until @queue.closed? && @queue.empty?
        task, value = @queue.pop
        task&.call(value)
      end
    end
  end
end
```

---

## Impact

|                     | Serial Server | Preforking | Threadpool | Prefork + Threadpool | Fiber | Prefork + Fiber |
| ------------------- | ------------- | ---------- | ---------- | -------------------- | ----- | --------------- |
| Requests per Second | 17.3          | 448.21     | 173.88     | ?                    | ?     | ?               |

---

### Server Model: Prefork + Threads

---

<style scoped>
img {
  width: 1000px;
}
</style>

![thread pool diagram](./thread-pool-diagram.svg)

---

<style scoped>
img {
  width: 1100px;
}
</style>

![preforking thread pool diagram](./preforking-threadpool-diagram.svg)

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

## Impact

|                     | Serial Server | Preforking | Threadpool | Prefork + Threadpool | Fiber | Prefork + Fiber |
| ------------------- | ------------- | ---------- | ---------- | -------------------- | ----- | --------------- |
| Requests per Second | 17.3          | 448.81     | 173.88     | 880.5                | ?     | ?               |

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

<style scoped>
img {
  width: 500px;
}
</style>

![diagram of fibers within a thread](./thread-containing-fiber.svg)

---

<style scoped>
img {
  width: 500px;
}
</style>

![thread containing many fibers diagram](./thread-many-fibers.svg)

---

```rb
Fiber.new do
  # do_stuff
end
```

---

## Fibers are cooperative

---

## Threads are preemptive

---

![childern supervised play](./supervised-game.jpg)

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

## Fiber are cooperative

---

![sharing console](./sharing-couch.jpg)

---

```rb
Fiber.new do
  # do stuff
  Fiber.yield some_value
  # do more stuff
end
```

---

## So What?

---

<style scoped>
img {
  width: 1000px;
}
</style>

![delegating to thread pool diagram](./thread-pool-diagram.svg)

---

<style scoped>
img {
  width: 1000px;
}
</style>

![fiber per connection diagram](./fiber-server-diagram.svg)

---

## Drawbacks?

- Bad actors
- Incompatibility of some gems

---

## Final Stats?

|                     | Serial Server | Preforking | Threadpool | Prefork + Threadpool | Fiber  | Prefork + Fiber |
| ------------------- | ------------- | ---------- | ---------- | -------------------- | ------ | --------------- |
| Requests per Second | 17.3          | 448.21     | 173.88     | 880.5                | 526.27 | 2074.8          |

---

![falcon vs puma](./falcon-vs-puma.png)

---

## Recap: Fibers

- cooperative not preemptive
- cheap AF

---

## So, About That Config

---

```yaml
workers:
  - queues: [critical]
    threads: 20
    processes: 1
```

---

<style scoped>
img {
  width: 1000px;
}
</style>

![image of 20 threads with 1 glv working on pdfs](./20-thread-pdf-gen.svg)

---

## Conclusion: Know Your Tools

- **Process:** Great for safety and CPU-bound parallelism.
- **Thread:** Great for I/O-bound work (database calls, APIs).
- **Fiber:** Best for massive I/O concurrency.

---

## Meta Conclusion

Dig deeper.

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
