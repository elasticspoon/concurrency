---
theme: dark
paginate: true
---

# Concurrency in Ruby: From `fork()` to Fiber

---

- What is Concurrency?
  - Concurrency is doing more than 1 thing at a time
  - cooking: boiling pasta which chopping tomatoes
  - running while listening to music
  - a http server dealing with 2 requests at the same time
- How does parallelism differ?
  - concurrency is how many tasks you can do that happen in overlapping time
  - parallelism is the amount of actions you can take at the same time
    - it is directly tied to hardware provided
  - When you are cooking pasta and chopping onions, you are performing
    two tasks at once, but you are never doing more than one action at a time
  - if you want to chop a tomato and onion at the same time you can't. You
    need a second person to do the chopping
  - That's the difference
  - "Concurrency is About dealing with lots of things at once.
    Parallelism is about doing lots of things at once." - Rob Pike
  - Parallelism is a kind of concurrency
  - The same way that a square is a kind of rectangle
- Who Cares?
  - knowing how to configure your server
  - knowing how to configure your background job processor

```
workers:
  - queues: [ critical, default, low ]
    threads: 12
    processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
  - queues: [ default, low, critical ]
    threads: 4
    processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
```

- talk more generally about servers
  - we use them but how much do we know
- moores law
- moores law is ending
- if we can't make stuff faster via faster cpus then we need to do more work at once
- Introduce Myself
  - software developer of 5 years
  - work at USCIS?
- Overview
- 3 Primary Primitives
  - Process (Process)
  - Thread (Thread)
  - Coroutine (Fiber)
- Introduce server
- Introduce the goal
- Lets get started

- What is a process?
  - shared memory
  - how do we create a new process in ruby
  - per process server
  - preforking server

- What is a thread?
  - per thread server
  - thread pool
  - prefork + threads

- What is a fiber?
