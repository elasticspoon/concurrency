# A Tale of Three Rubies: Concurrency Explained

---

## A Puzzling Configuration

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

- Software Developer (5 years)
- U.S. Citizenship and Immigration Services (USCIS)

---

## Talk Overview

By the end, you'll understand...

- Why that config didn't work as expected.
- The fundamentals of concurrency.
- Ruby's three main concurrency models.

---

## What is Concurrency?

Concurrency is **dealing** with more than one task at a time.

---

## Analogy: Cooking

add a drawing of cooking pasta while chopping food and browning veggies

---

## What is Parallelism?

Parallelism is **doing** more than one thing at a time.

---

## Difference from Concurrency?

Concurrency is how many tasks you can do that happen in overlapping time.

Parallelism is the amount of actions you can take at the same time. It is directly tied to hardware.

---

> "Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once." - Rob Pike

---

## Analogy: You Need a Friend

To chop a tomato _and_ an onion at the exact same time, you need a second person.

That's parallelism. It requires more hardware (or hands).

---

## Parallelism is a specific _type_ of concurrency

(The way a square is a specific type of rectangle).

---

## Web Server

---

## Routing

```rb
case path
when '/cpu'
  connection.write(cpu_response)
when '/sleep'
  connection.write(sleep_response)
else
  connection.write(default_response)
end
```

---

## CPU Bound Response

```rb
def cpu_response
  <<~RESP
    HTTP/1.1 200 OK
    Content-Type: text/plain

    CPU-intensive work completed: #{fibonacci(10_000)}
  RESP
end
```

---

## IO Bound Response

```rb
def sleep_response
  sleep 2
  <<~RESP
    HTTP/1.1 200 OK
    Content-Type: text/plain

    Slept for 2 seconds
  RESP
end
```

---

## The Server

```
# frozen_string_literal: true

require 'socket'
require_relative 'request_handler'

class Server
  def initialize(port:)
    @server = TCPServer.new(port)
    @handler = RequestHandler.new
    puts "Listening on port #{@server.local_address.ip_port}"
  end

  def start
    loop do
      connection = @server.accept
      @handler.handle(connection)
      connection.close
    end
  end
end

server = Server.new(port: 3000)
server.start
```

---

## 3 Concurrency Primitives

- **Process** (`Process`)
- **Thread** (`Thread`)
- **Coroutine** (`Fiber`)

---

## Process

A self-contained program with its own memory. Heavy, but isolated and safe.

---

### Server Model: One Process Per Request

Simple, but slow. Each new connection creates a whole new process.

---

### Server Model: The Preforking Server

Create a pool of processes upfront. This is much faster\!

(e.g., Unicorn 🦄)

---

## 2\. The Thread

A lighter-weight path of execution _within_ a process. Threads share memory.

---

### Server Model: One Thread Per Request

Lighter than a process, but creating threads still has overhead.

---

### Server Model: The Thread Pool

Create a pool of threads to handle a queue of incoming requests.

(e.g., Puma 🐆)

---

### Server Model: Prefork + Threads

The hybrid model\! Multiple processes, each with its own pool of threads.

(This is Puma's default cluster mode).

---

## 3\. The Fiber (Coroutine)

Extremely lightweight. You control when it pauses and resumes. It's cooperative.

---

### Server Model: The Event Loop

One thread can manage thousands of Fibers, switching between them when one is waiting.

(e.g., Falcon)

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

## Why This Matters Now

Moore's Law is ending. We can't rely on faster single cores.

Concurrency is the future of performance.

---

# Thank You\

Questions?
