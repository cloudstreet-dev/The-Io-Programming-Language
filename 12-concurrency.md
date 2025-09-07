# Chapter 12: Concurrency

Io provides powerful concurrency primitives: coroutines for cooperative multitasking, actors for message-passing concurrency, and futures for asynchronous computation. This chapter explores these mechanisms and how they enable concurrent and parallel programming in Io.

## Coroutines: Cooperative Multitasking

Coroutines are the foundation of Io's concurrency model. They're lightweight threads that yield control cooperatively:

```io
// Create a coroutine
coro := coroutine(
    5 repeat(i,
        ("Coroutine: " .. i) println
        yield  // Give control back
    )
)

// Run it
5 repeat(
    "Main" println
    coro resume  // Resume the coroutine
)
// Output interleaves Main and Coroutine messages
```

Compare with threads in other languages:

```python
# Python with threads (preemptive)
import threading
def worker():
    for i in range(5):
        print(f"Thread: {i}")
        # No explicit yield needed

# Python with async (cooperative)
async def worker():
    for i in range(5):
        print(f"Coroutine: {i}")
        await asyncio.sleep(0)  # Explicit yield
```

## Creating and Managing Coroutines

```io
// Basic coroutine creation
coro := Coroutine clone
coro setRunMessage(message(
    "Running in coroutine" println
    self  // Return value
))
coro resume println  // "Running in coroutine", then returns self

// Using @ for async execution
future := obj @method(arg)  // Runs method in new coroutine
result := future resolve     // Wait for result

// Coroutine with arguments
producer := coroutine(
    10 repeat(i,
        yield(i * i)  // Yield a value
    )
)

5 repeat(
    producer resume println  // 0, 1, 4, 9, 16
)
```

## Actors: Message-Passing Concurrency

Actors are objects that process messages asynchronously in their own coroutine:

```io
// Create an actor
Counter := Object clone
Counter count := 0
Counter increment := method(
    count = count + 1
    count
)

// Make it an actor
counter := Counter clone
counterActor := counter @  // @ makes it an actor

// Send messages asynchronously
future1 := counterActor increment
future2 := counterActor increment
future3 := counterActor increment

// Get results
future1 resolve println  // 1
future2 resolve println  // 2
future3 resolve println  // 3
```

This is similar to Erlang's actor model:

```erlang
% Erlang
counter(Count) ->
    receive
        {increment, From} ->
            From ! Count + 1,
            counter(Count + 1)
    end.
```

## Futures and Promises

Futures represent values that will be available later:

```io
// Create a future manually
future := Future clone

// In another coroutine, fulfill it
@(
    wait(1)  // Simulate work
    future setResult(42)
)

// Wait for result
"Waiting..." println
result := future resolve
("Got result: " .. result) println  // Got result: 42

// Futures from async calls
slowOperation := method(n,
    wait(n)
    n * 2
)

f := self @slowOperation(2)
"Doing other work..." println
result := f resolve
result println  // 4
```

## Channels for Communication

Implement Go-style channels:

```io
Channel := Object clone
Channel init := method(
    self queue := list()
    self waiters := list()
    self
)

Channel send := method(value,
    if(waiters size > 0,
        waiter := waiters removeFirst
        waiter resume(value),
        queue append(value)
    )
)

Channel receive := method(
    if(queue size > 0,
        queue removeFirst,
        waiters append(Coroutine currentCoroutine)
        Coroutine currentCoroutine pause
    )
)

// Usage
ch := Channel clone init

// Producer
@(
    5 repeat(i,
        ch send(i * i)
        wait(0.1)
    )
)

// Consumer
@(
    5 repeat(
        value := ch receive
        ("Received: " .. value) println
    )
)

wait(1)  // Let them run
```

## Synchronization Primitives

### Mutex (Mutual Exclusion)

```io
Mutex := Object clone
Mutex locked := false
Mutex waitQueue := list()

Mutex lock := method(
    while(locked,
        waitQueue append(Coroutine currentCoroutine)
        Coroutine currentCoroutine pause
    )
    locked = true
)

Mutex unlock := method(
    locked = false
    if(waitQueue size > 0,
        waiter := waitQueue removeFirst
        waiter resume
    )
)

Mutex synchronize := method(block,
    lock
    e := try(result := block call)
    unlock
    if(e, e raise, result)
)

// Usage
sharedCounter := 0
mutex := Mutex clone

10 repeat(
    @(
        mutex synchronize(
            temp := sharedCounter
            yield  // Simulate race condition
            sharedCounter = temp + 1
        )
    )
)

wait(0.5)
sharedCounter println  // 10 (without mutex would be unpredictable)
```

### Semaphore

```io
Semaphore := Object clone
Semaphore init := method(permits,
    self permits := permits
    self waitQueue := list()
    self
)

Semaphore acquire := method(
    while(permits <= 0,
        waitQueue append(Coroutine currentCoroutine)
        Coroutine currentCoroutine pause
    )
    permits = permits - 1
)

Semaphore release := method(
    permits = permits + 1
    if(waitQueue size > 0,
        waiter := waitQueue removeFirst
        waiter resume
    )
)

// Usage: Limit concurrent connections
connectionPool := Semaphore clone init(3)

10 repeat(i,
    @(
        connectionPool acquire
        ("Connection " .. i .. " started") println
        wait(Random value)
        ("Connection " .. i .. " finished") println
        connectionPool release
    )
)

wait(3)
```

## Concurrent Collections

```io
// Thread-safe list
ConcurrentList := List clone
ConcurrentList mutex := Mutex clone

ConcurrentList append := method(item,
    mutex synchronize(resend(item))
)

ConcurrentList at := method(index,
    mutex synchronize(resend(index))
)

ConcurrentList size := method(
    mutex synchronize(resend)
)

// Usage
list := ConcurrentList clone

10 repeat(i,
    @(list append(i))
)

wait(0.1)
list size println  // 10
```

## Worker Pool Pattern

```io
WorkerPool := Object clone
WorkerPool init := method(workerCount,
    self workers := list()
    self taskQueue := Channel clone init
    self results := Channel clone init
    
    workerCount repeat(
        worker := @(
            loop(
                task := taskQueue receive
                if(task isNil, break)  // Poison pill
                
                result := task call
                results send(result)
            )
        )
        workers append(worker)
    )
    
    self
)

WorkerPool submit := method(task,
    taskQueue send(task)
)

WorkerPool shutdown := method(
    workers size repeat(taskQueue send(nil))
)

WorkerPool getResult := method(
    results receive
)

// Usage
pool := WorkerPool clone init(4)

// Submit tasks
10 repeat(i,
    pool submit(block(
        wait(Random value * 0.1)
        i * i
    ))
)

// Collect results
results := list()
10 repeat(
    results append(pool getResult)
)

pool shutdown
results println
```

## Async/Await Pattern

```io
// Implement async/await style
Object async := method(
    future := Future clone
    
    @(
        e := try(result := call activated doMessage(call message, call sender))
        if(e,
            future setException(e),
            future setResult(result)
        )
    )
    
    future
)

Object await := method(future,
    future resolve
)

// Usage
fetchData := async method(url,
    wait(1)  // Simulate network delay
    "Data from " .. url
)

processData := async method(
    data1 := await(fetchData("api/users"))
    data2 := await(fetchData("api/posts"))
    data1 .. " + " .. data2
)

result := await(processData)
result println  // Data from api/users + Data from api/posts
```

## Parallel Map

```io
List parallelMap := method(block,
    futures := self map(item,
        self @(block call(item))
    )
    
    futures map(resolve)
)

// Usage
numbers := list(1, 2, 3, 4, 5)

// Sequential map
time(
    sequential := numbers map(n,
        wait(0.1)
        n * n
    )
)

// Parallel map
time(
    parallel := numbers parallelMap(n,
        wait(0.1)
        n * n
    )
)

sequential println  // list(1, 4, 9, 16, 25)
parallel println    // list(1, 4, 9, 16, 25) but faster
```

## Deadlock Detection

```io
DeadlockDetector := Object clone
DeadlockDetector init := method(
    self resources := Map clone
    self waitGraph := Map clone
    self
)

DeadlockDetector requestResource := method(coroutine, resource,
    // Add to wait graph
    if(resources hasKey(resource),
        owner := resources at(resource)
        if(owner != coroutine,
            waitGraph atPut(coroutine, resource)
            
            // Check for cycle
            if(hasCycle(coroutine),
                Exception raise("Deadlock detected!")
            )
        )
    )
)

DeadlockDetector hasCycle := method(start,
    // Simplified cycle detection
    visited := list()
    current := start
    
    while(waitGraph hasKey(current),
        if(visited contains(current), return true)
        visited append(current)
        
        resource := waitGraph at(current)
        if(resources hasKey(resource),
            current = resources at(resource)
        ,
            break
        )
    )
    
    false
)
```

## Event Loop

```io
EventLoop := Object clone
EventLoop init := method(
    self events := list()
    self running := true
    self
)

EventLoop schedule := method(delay, block,
    events append(list(Date now + delay, block))
    events sortInPlaceBy(block(e, e at(0)))
)

EventLoop run := method(
    while(running and events size > 0,
        now := Date now
        
        while(events size > 0 and events first at(0) <= now,
            event := events removeFirst
            event at(1) @call
        )
        
        if(events size > 0,
            wait((events first at(0) - now) max(0))
        )
    )
)

EventLoop stop := method(running = false)

// Usage
loop := EventLoop clone init

loop schedule(0.1, block("First" println))
loop schedule(0.2, block("Second" println))
loop schedule(0.15, block("Between" println))

loop run
```

## Common Patterns

### Producer-Consumer

```io
Buffer := Object clone
Buffer init := method(capacity,
    self items := list()
    self capacity := capacity
    self notFull := Semaphore clone init(capacity)
    self notEmpty := Semaphore clone init(0)
    self mutex := Mutex clone
    self
)

Buffer put := method(item,
    notFull acquire
    mutex synchronize(items append(item))
    notEmpty release
)

Buffer get := method(
    notEmpty acquire
    item := mutex synchronize(items removeFirst)
    notFull release
    item
)

// Usage
buffer := Buffer clone init(5)

// Producer
@(
    10 repeat(i,
        ("Producing " .. i) println
        buffer put(i)
        wait(Random value * 0.1)
    )
)

// Consumer
@(
    10 repeat(
        item := buffer get
        ("Consumed " .. item) println
        wait(Random value * 0.2)
    )
)

wait(3)
```

### Fork-Join

```io
Object forkJoin := method(tasks,
    futures := tasks map(task,
        @(task call)
    )
    
    futures map(resolve)
)

// Parallel quicksort
quicksort := method(list,
    if(list size <= 1, return list)
    
    pivot := list at(list size / 2)
    
    results := forkJoin(list(
        block(list select(x, x < pivot) quicksort),
        block(list select(x, x == pivot)),
        block(list select(x, x > pivot) quicksort)
    ))
    
    results at(0) appendSeq(results at(1)) appendSeq(results at(2))
)

sorted := quicksort(list(3, 1, 4, 1, 5, 9, 2, 6))
sorted println  // list(1, 1, 2, 3, 4, 5, 6, 9)
```

## Performance Considerations

```io
// Coroutines are lightweight
time(
    coroutines := list()
    1000 repeat(i,
        coroutines append(@(i * i))
    )
    coroutines map(resolve)
)

// But context switching has overhead
benchmarkConcurrency := method(taskCount, taskWork,
    // Sequential
    seqTime := time(
        taskCount repeat(i, taskWork call(i))
    )
    
    // Concurrent
    concTime := time(
        futures := list()
        taskCount repeat(i,
            futures append(@(taskWork call(i)))
        )
        futures map(resolve)
    )
    
    ("Sequential: " .. seqTime) println
    ("Concurrent: " .. concTime) println
    ("Speedup: " .. (seqTime / concTime)) println
)

// Light work - concurrency overhead dominates
benchmarkConcurrency(100, block(i, i * i))

// Heavy work - concurrency helps
benchmarkConcurrency(10, block(i,
    sum := 0
    10000 repeat(j, sum = sum + j)
    sum
))
```

## Exercises

1. **Rate Limiter**: Implement a rate limiter that allows N operations per second.

2. **Parallel Reduce**: Create a parallel version of reduce that divides work among workers.

3. **Actor Supervisor**: Build a supervisor that restarts failed actors.

4. **CSP Channels**: Implement Communicating Sequential Processes with select statement.

5. **STM**: Implement Software Transactional Memory for conflict-free concurrent updates.

## Real-World Example: Web Scraper

```io
WebScraper := Object clone
WebScraper init := method(maxConcurrent,
    self semaphore := Semaphore clone init(maxConcurrent)
    self visited := ConcurrentSet clone init
    self results := ConcurrentList clone
    self
)

WebScraper scrape := method(urls,
    futures := list()
    
    urls foreach(url,
        if(visited contains(url) not,
            visited add(url)
            
            future := @(
                semaphore acquire
                e := try(
                    ("Scraping " .. url) println
                    // Simulate HTTP request
                    wait(Random value)
                    
                    content := "Content from " .. url
                    results append(Map with("url", url, "content", content))
                    
                    // Find more URLs (simplified)
                    if(Random value < 0.3,
                        newUrl := url .. "/" .. Random value round
                        self scrape(list(newUrl))
                    )
                )
                
                semaphore release
                if(e, ("Error scraping " .. url .. ": " .. e message) println)
            )
            
            futures append(future)
        )
    )
    
    futures map(resolve)
    self
)

// Usage
scraper := WebScraper clone init(3)
scraper scrape(list(
    "https://example.com",
    "https://example.org",
    "https://example.net"
))

wait(2)
("Scraped " .. scraper results size .. " pages") println
```

## Conclusion

Io's concurrency model, built on coroutines, actors, and futures, provides powerful abstractions for concurrent programming. The cooperative nature of coroutines gives you fine control over scheduling, while actors provide isolation and message-passing safety. Futures enable asynchronous programming patterns familiar from other languages.

The beauty of Io's approach is that these concurrency primitives are implemented using the same object model as everything else. Coroutines are objects, messages can be sent asynchronously with `@`, and synchronization primitives can be built from basic objects and messages. This consistency makes concurrent programming in Io both powerful and comprehensible.

---

*Next: [Chapter 13 - Domain-Specific Languages](13-domain-specific-languages.md)*