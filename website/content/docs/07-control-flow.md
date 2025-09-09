---
title: "Control Flow"
weight: 80
---



# Chapter 7: Control Flow

In most programming languages, control flow structures like `if`, `while`, and `for` are built-in syntax with special rules. In Io, they're just methods that receive messages. This chapter explores how Io's message-passing philosophy extends to control flow, and how you can create your own control structures.

## Everything Is a Message

Let's start with a simple comparison. In C or Java:

```c
if (x > 5) {
    printf("Big\n");
} else {
    printf("Small\n");
}
```

This is special syntax that the compiler understands. But in Io:

```io
if(x > 5,
    "Big" println,
    "Small" println
)
```

The `if` is just a method call! You can even see its implementation:

```io
if println
// method(...)

// You could redefine it (don't actually do this!)
Object if := method(condition, trueBlock, falseBlock,
    "Making a decision!" println
    resend  // Call original if
)
```

## The if Method

The `if` method takes two or three arguments:

```io
// Two arguments: if-then
if(temperature > 30,
    "It's hot!" println
)

// Three arguments: if-then-else
if(temperature > 30,
    "It's hot!" println,
    "It's nice!" println
)

// if returns the value of the executed block
result := if(5 > 3, "yes", "no")
result println  // "yes"

// Nested if
category := if(score > 90, "A",
    if(score > 80, "B",
        if(score > 70, "C", "F")
    )
)
```

## Understanding Blocks

The key to Io's control flow is that code blocks are objects that aren't evaluated immediately:

```io
// This prints immediately
"Hello" println

// This creates a block object but doesn't execute it
block := method("Hello" println)

// Execute it later
block call  // Now it prints "Hello"

// Blocks in if
if(true,
    "This is a block" println  // Not executed until if decides to
)
```

This lazy evaluation is crucial. If both branches of an `if` were evaluated immediately, both would execute!

```io
// In a hypothetical eager language:
eagerIf := method(condition, trueValue, falseValue,
    if(condition, trueValue, falseValue)
)

x := 5
eagerIf(x > 3,
    "Greater" println,  // This executes immediately
    "Lesser" println    // This also executes immediately!
)
// Would print both!

// But Io's if receives unevaluated blocks
if(x > 3,
    "Greater" println,  // Only this executes
    "Lesser" println    // This never executes
)
```

## The while Loop

The `while` method repeatedly evaluates its condition and body:

```io
i := 0
while(i < 5,
    i println
    i = i + 1
)
// Prints 0, 1, 2, 3, 4

// while returns nil by default
result := while(false, "Never runs")
result println  // nil

// Infinite loops
while(true,
    input := File standardInput readLine
    if(input == "quit", break)
    ("You said: " .. input) println
)
```

## The for Loop

The `for` method provides a counting loop:

```io
// Basic for loop
for(i, 1, 5,
    i println
)
// Prints 1, 2, 3, 4, 5

// With step
for(i, 0, 10, 2,
    i println
)
// Prints 0, 2, 4, 6, 8, 10

// Backward
for(i, 5, 1,
    i println
)
// Prints 5, 4, 3, 2, 1

// for can return values
sum := 0
for(i, 1, 100,
    sum = sum + i
)
sum println  // 5050
```

## The loop Method

Io provides a `loop` method for infinite loops:

```io
count := 0
loop(
    count = count + 1
    if(count > 10, break)
    count println
)

// Equivalent to while(true, ...)
```

## break and continue

These work like in other languages, but they're methods too:

```io
// break exits the loop
for(i, 1, 10,
    if(i == 5, break)
    i println
)
// Prints 1, 2, 3, 4

// continue skips to next iteration
for(i, 1, 10,
    if(i % 2 == 0, continue)
    i println
)
// Prints 1, 3, 5, 7, 9

// break can return a value
result := for(i, 1, 100,
    if(i * i > 50, break(i))
)
result println  // 8 (first i where i*i > 50)
```

## The repeat Method

A simpler counting mechanism:

```io
5 repeat("Hello" println)
// Prints "Hello" 5 times

// repeat with index
5 repeat(i, 
    ("Count: " .. i) println
)
// Count: 0
// Count: 1
// Count: 2
// Count: 3
// Count: 4
```

## Creating Custom Control Structures

Since control structures are just methods, you can create your own:

```io
// unless: opposite of if
Object unless := method(condition, falseBlock,
    if(condition not, falseBlock call)
)

unless(5 > 10,
    "5 is not greater than 10" println
)

// until: opposite of while
Object until := method(condition, body,
    while(condition not, body)
)

x := 0
until(x > 5,
    x println
    x = x + 1
)

// times: repeat n times with cleaner syntax
Number times := method(body,
    for(i, 1, self, body)
)

3 times("Hello" println)
```

## The elseif Pattern

Io uses `elseif` for chained conditionals:

```io
score := 85

if(score >= 90) then(
    "A" println
) elseif(score >= 80) then(
    "B" println
) elseif(score >= 70) then(
    "C" println
) else(
    "F" println
)
// Prints "B"

// This is actually a chain of methods
// if returns a special object when false
// that object has elseif and else methods
```

## Switch-like Behavior

Io doesn't have a switch statement, but you can build one:

```io
Object switch := method(value,
    self switchValue := value
    self
)

Object case := method(testValue, action,
    if(switchValue == testValue,
        action call
        self switchMatched := true
    )
    self
)

Object default := method(action,
    if(hasSlot("switchMatched") not,
        action call
    )
    self
)

// Usage
day := "Tuesday"

switch(day) case("Monday", 
    "Start of the week" println
) case("Tuesday",
    "Second day" println
) case("Friday",
    "TGIF!" println
) default(
    "Regular day" println
)
// Prints "Second day"
```

## Pattern Matching

Build more sophisticated matching:

```io
Object match := method(
    self matchValue := call evalArgAt(0)
    self matchContext := call sender
    self
)

Object when := method(pattern, action,
    if(hasSlot("matchFound") not,
        matched := false
        
        // Check different pattern types
        if(pattern type == "Block",
            matched = pattern call(matchValue),
            matched = (pattern == matchValue)
        )
        
        if(matched,
            self matchResult := action call(matchValue)
            self matchFound := true
        )
    )
    self
)

Object otherwise := method(action,
    if(hasSlot("matchFound") not,
        self matchResult := action call(matchValue)
    )
    matchResult
)

// Usage
result := match(x) when(
    block(v, v < 0), 
    method(v, "negative")
) when(
    0,
    method(v, "zero")
) when(
    block(v, v > 0),
    method(v, "positive")
) otherwise(
    method(v, "unknown")
)
```

## Iterating Over Collections

Collections have their own iteration methods:

```io
// List iteration
list(1, 2, 3) foreach(item,
    item println
)

// With index
list("a", "b", "c") foreach(i, item,
    (i .. ": " .. item) println
)
// 0: a
// 1: b
// 2: c

// Map iteration
map := Map clone
map atPut("name", "Alice")
map atPut("age", 30)

map foreach(key, value,
    (key .. " = " .. value) println
)
// name = Alice
// age = 30
```

## Functional Control Flow

Io supports functional programming patterns:

```io
// map: transform each element
squares := list(1, 2, 3, 4) map(x, x * x)
squares println  // list(1, 4, 9, 16)

// select: filter elements
evens := list(1, 2, 3, 4, 5, 6) select(x, x % 2 == 0)
evens println  // list(2, 4, 6)

// detect: find first matching element
first_big := list(1, 3, 5, 7, 9) detect(x, x > 5)
first_big println  // 7

// reduce: aggregate elements
sum := list(1, 2, 3, 4, 5) reduce(+)
sum println  // 15

product := list(1, 2, 3, 4) reduce(a, b, a * b)
product println  // 24
```

## Lazy Evaluation Control

Create control structures with lazy evaluation:

```io
Object lazyIf := method(
    condition := call argAt(0)
    trueBlock := call argAt(1)
    falseBlock := call argAt(2)
    
    if(condition doInContext(call sender),
        trueBlock doInContext(call sender),
        if(falseBlock,
            falseBlock doInContext(call sender)
        )
    )
)

// Both condition and blocks are lazy
x := 5
lazyIf(x > 3 and computeExpensive(),
    "True branch" println,
    "False branch" println
)
```

## Exception Handling as Control Flow

Io's `try` is also a control flow method:

```io
try(
    // Code that might fail
    riskyOperation()
) catch(Exception,
    "An error occurred" println
)

// try-catch-finally pattern
result := try(
    file := File with("data.txt") openForReading
    file contents
) catch(Exception, e,
    ("Error: " .. e message) println
    nil
) finally(
    if(file, file close)
)
```

## Performance Considerations

Since control structures are methods, they have overhead:

```io
// Method-based loop (slower)
i := 0
while(i < 1000000,
    i = i + 1
)

// But you can't really avoid it in Io
// The language is optimized for expressiveness over speed
```

## Advanced: Coroutine-based Control

Io's coroutines enable advanced control flow:

```io
// Generator pattern
Generator := Object clone
Generator init := method(
    self coro := Coroutine currentCoroutine
    self
)

Generator yield := method(value,
    coro pause(value)
)

Generator fibonacci := method(
    a := 0
    b := 1
    loop(
        yield(a)
        temp := a + b
        a = b
        b = temp
    )
)

// Usage
gen := Generator clone
fib := gen @fibonacci  // @ runs in new coroutine

10 repeat(
    fib resume println
)
// 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
```

## Common Patterns

### Early Return Pattern

```io
Object findFirst := method(list, condition,
    list foreach(item,
        if(condition call(item),
            return item
        )
    )
    nil
)

result := findFirst(list(1, 2, 3, 4, 5), 
    block(x, x > 3)
)
result println  // 4
```

### Guard Clause Pattern

```io
processData := method(data,
    if(data isNil, return "No data")
    if(data size == 0, return "Empty data")
    if(data size > 1000, return "Too much data")
    
    // Process data
    "Processed" return
)
```

### Loop with State

```io
Object loopWithState := method(initial, condition, update, body,
    state := initial
    while(condition call(state),
        body call(state)
        state = update call(state)
    )
    state
)

// Sum squares until sum > 100
result := loopWithState(
    list(0, 1),  // [sum, n]
    block(state, state at(0) <= 100),
    block(state, list(state at(0) + state at(1) squared, state at(1) + 1)),
    block(state, ("n=" .. state at(1) .. " sum=" .. state at(0)) println)
)
```

## Debugging Control Flow

```io
Object trace := method(label,
    (label .. " - evaluating") println
    self
)

Object debugIf := method(condition, trueBlock, falseBlock,
    "Evaluating condition..." println
    result := condition
    ("Condition is: " .. result) println
    
    if(result,
        "Taking true branch" println
        trueBlock,
        "Taking false branch" println
        falseBlock
    )
)

x := 5
debugIf(x trace("x") > trace("3") 3,
    "Greater" println,
    "Lesser" println
)
```

## Exercises

1. **do-while Loop**: Implement a `doWhile` method that executes the body at least once.

2. **for-each with Break**: Create a `forEachBreakable` that allows breaking with a return value.

3. **Retry Logic**: Build a `retry` control structure that retries an operation n times on failure.

4. **Parallel If**: Create a `parallelIf` that evaluates both branches concurrently and returns the first to complete.

5. **State Machine**: Implement a state machine DSL using custom control structures.

## Real-World Example: Retry with Backoff

```io
Object retryWithBackoff := method(maxAttempts, baseDelay, operation,
    attempt := 1
    lastError := nil
    
    while(attempt <= maxAttempts,
        try(
            return operation call(attempt)
        ) catch(Exception, e,
            lastError = e
            if(attempt < maxAttempts,
                delay := baseDelay * (2 pow(attempt - 1))
                ("Attempt " .. attempt .. " failed, waiting " .. delay .. "ms") println
                System sleep(delay / 1000)
            )
        )
        attempt = attempt + 1
    )
    
    Exception raise("Failed after " .. maxAttempts .. " attempts: " .. lastError message)
)

// Usage
result := retryWithBackoff(3, 100,
    block(attempt,
        ("Trying attempt " .. attempt) println
        if(Random value < 0.7,
            Exception raise("Random failure"),
            "Success!"
        )
    )
)
```

## Conclusion

Io's approach to control flow—implementing everything as methods rather than special syntax—is both radical and elegant. It demonstrates the power of Io's uniform message-passing model: when everything is a message, even fundamental programming constructs become malleable and extensible.

This flexibility allows you to:
- Create domain-specific control structures
- Implement new programming paradigms
- Debug and trace control flow
- Understand exactly how your program executes

The cost is performance and perhaps initial unfamiliarity. But the benefit is a deep understanding of control flow and the ability to shape the language to your needs rather than being constrained by built-in constructs.

---

*Next: [Chapter 8 - Collections](08-collections.md)*
