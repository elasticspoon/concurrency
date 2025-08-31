---
theme: dark
paginate: true
---

# Concurrency in Ruby: From `fork()` to Fiber

---

- I had someone come to me with the following config for a background job processor

```yaml
workers:
  - queues: [critical]
    threads: 20
    processes: 1
  - queues: ["default", "low"]
    threads: 3
    processes: 1
```

- Concurrency is a black box in Ruby
- Introduce Myself
  - software developer of 5 years
  - work at USCIS?
- Talk overview
  - hopefully by end of talk you will understand why that config did not makes sense
  - you will have a decent grasp of what is concurrency and why it matters
  - you will have a grasp of the 3 main concurrency Primitives in ruby
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
- Overview
- 3 Primary Primitives
  - Process (Process)
  - Thread (Thread)
  - Coroutine (Fiber)
- Introduce server
- Introduce the goal
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
- Conclusion
  - back to example of the yaml config
  - know you tools
  - moores law
  - moores law is ending
