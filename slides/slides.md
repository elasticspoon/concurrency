---
theme: dark
paginate: true
---

# Concurrency in Ruby: From `fork()` to Fiber

---

- What is Concurrency?
- Who Cares?
  - usage servers
  - usage in background job processors
  - thinking about race conditions
- Introduce Myself
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
