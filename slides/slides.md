---
theme: dark
paginate: true
---

# Concurrency in Ruby: From `fork()` to Fiber

---

- What is Concurrency?
- Who Cares?
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

- knowing how to configure your server
- moores law
- moores law is ending
- if we can't make stuff faster via faster cpus then we need to do more work at once
- Introduce Myself
  - software developer of 5 years
  -
- Overview
- 3 Primary Primitives
  - Process
  - Thread
  - Fiber
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
