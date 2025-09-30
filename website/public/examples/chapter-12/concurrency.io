#!/usr/bin/env io
# Concurrency examples from Chapter 12

"\n=== Coroutine Example ===" println

# Simple coroutine
coro := coroutine(
    3 repeat(i,
        ("Coroutine says: " .. i) println
        yield  # Give control back
    )
    "Coroutine done!"
)

3 repeat(i,
    ("Main says: " .. i) println
    result := coro resume
    if(result, result println)
)

"\n=== Producer-Consumer Pattern ===" println

# Channel implementation
Channel := Object clone
Channel init := method(
    self queue := list()
    self
)

Channel send := method(value,
    queue append(value)
)

Channel receive := method(
    while(queue size == 0, yield)
    queue removeFirst
)

ch := Channel clone init

# Producer coroutine
producer := coroutine(
    5 repeat(i,
        value := i * i
        ("Producer: sending " .. value) println
        ch send(value)
        yield
    )
)

# Consumer coroutine
consumer := coroutine(
    5 repeat(
        value := ch receive
        ("Consumer: received " .. value) println
        yield
    )
)

# Run them
10 repeat(
    producer resume
    consumer resume
)

"\n=== Futures Example ===" println

# Simulate async operation
slowOperation := method(n,
    "Starting slow operation..." println
    wait(0.5)  # Simulate work
    n * 2
)

# Run async with @
"Launching async operation..." println
future := self @slowOperation(21)

"Doing other work while waiting..." println
3 repeat(i,
    ("Working... " .. i) println
    wait(0.1)
)

"Getting result..." println
result := future resolve
("Result: " .. result) println

"\n=== Parallel Map ===" println

# Add parallel map to List
List parallelMap := method(block,
    futures := self map(item,
        self @(block call(item))
    )
    futures map(resolve)
)

# Compare sequential vs parallel
numbers := list(1, 2, 3, 4, 5)

"Sequential map:" println
start := Date now
sequential := numbers map(n,
    wait(0.1)  # Simulate work
    n * n
)
("Time: " .. (Date now - start) .. " seconds") println
("Result: " .. sequential) println

"Parallel map:" println
start := Date now
parallel := numbers parallelMap(n,
    wait(0.1)  # Simulate work
    n * n
)
("Time: " .. (Date now - start) .. " seconds") println
("Result: " .. parallel) println