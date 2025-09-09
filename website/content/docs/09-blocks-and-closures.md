---
title: "Blocks and Closures"
weight: 100
---



# Chapter 9: Blocks and Closures

Blocks in Io are first-class objects representing unevaluated code. They capture their creation context, making them closures. This chapter explores blocks, methods, closures, and how they enable functional programming patterns in Io.

## Understanding Blocks and Methods

In Io, `block` and `method` are similar but have a crucial difference:

```io
// Block - creates its own scope
blk := block(x, x * 2)
blk call(5) println  // 10

// Method - shares scope with receiver
obj := Object clone
obj value := 10
obj meth := method(x, x * value)  // Can access 'value'
obj blk := block(x, x * value)    // Error when called - no 'value' in block scope

obj meth(5) println  // 50
// obj blk call(5)  // Exception: value not found
```

The key difference:
- **Methods** have access to `self` and the receiver's slots
- **Blocks** create their own scope and don't have automatic access to `self`

## Creating and Calling Blocks

```io
// Simple block
double := block(x, x * 2)
double call(5) println  // 10

// Multi-argument block
add := block(a, b, a + b)
add call(3, 4) println  // 7

// No-argument block
greet := block("Hello!" println)
greet call  // Hello!

// Blocks are objects
double type println  // Block
double proto println  // Block_0x...
```

## Blocks as Closures

Blocks capture variables from their creation context:

```io
makeCounter := method(
    count := 0
    block(
        count = count + 1
        count
    )
)

counter1 := makeCounter()
counter2 := makeCounter()

counter1 call println  // 1
counter1 call println  // 2
counter2 call println  // 1 (independent)
counter1 call println  // 3
```

This is different from many languages where you need special syntax for closures:

```javascript
// JavaScript
function makeCounter() {
    let count = 0;
    return function() {
        count++;
        return count;
    };
}
```

In Io, all blocks are closures automatically.

## The Scope Chain

Understanding scope is crucial for blocks:

```io
x := "global"

outer := method(
    x := "outer"
    
    inner := block(
        x println  // What prints?
    )
    
    inner
)

myBlock := outer()
myBlock call  // "outer" - captured from creation context

x = "changed global"
myBlock call  // Still "outer" - closure captures variables, not global
```

## Methods and self

Methods have access to `self` (the receiver):

```io
Calculator := Object clone
Calculator value := 0

Calculator add := method(n,
    self value = self value + n  // Explicit self
    value  // Implicit self
)

Calculator addBlock := block(n,
    // No automatic self here!
    // Would need to pass it explicitly
)

calc := Calculator clone
calc add(5) println  // 5
calc add(3) println  // 8
```

## Block Arguments and Defaults

```io
// Variable arguments
sumAll := block(
    args := call message arguments
    total := 0
    args foreach(arg,
        total = total + call sender doMessage(arg)
    )
    total
)

sumAll call(1, 2, 3, 4, 5) println  // 15

// Default arguments (manual)
greetWithDefault := block(name,
    if(name isNil, name = "World")
    ("Hello, " .. name .. "!") println
)

greetWithDefault call("Alice")  // Hello, Alice!
greetWithDefault call()        // Hello, World!
```

## Higher-Order Functions

Blocks enable functional programming patterns:

```io
// Functions returning functions
makeMultiplier := method(factor,
    block(x, x * factor)
)

double := makeMultiplier(2)
triple := makeMultiplier(3)

double call(5) println  // 10
triple call(5) println  // 15

// Functions taking functions
twice := method(f, x,
    f call(f call(x))
)

twice(block(n, n + 1), 5) println  // 7

// Composition
compose := method(f, g,
    block(x, f call(g call(x)))
)

addOne := block(x, x + 1)
double := block(x, x * 2)
doubleThenAddOne := compose(addOne, double)

doubleThenAddOne call(5) println  // 11
```

## Partial Application and Currying

```io
// Partial application
add := block(a, b, a + b)

addFive := block(x, add call(5, x))
addFive call(3) println  // 8

// Currying
curry := method(f,
    block(a,
        block(b,
            f call(a, b)
        )
    )
)

curriedAdd := curry(add)
add5 := curriedAdd call(5)
add5 call(3) println  // 8

// More practical example
formatString := block(template, value,
    template interpolate(value)
)

curriedFormat := curry(formatString)
errorFormatter := curriedFormat call("Error: #{value}")
successFormatter := curriedFormat call("Success: #{value}")

errorFormatter call("File not found") println  // Error: File not found
successFormatter call("Operation complete") println  // Success: Operation complete
```

## Lazy Evaluation with Blocks

Blocks don't evaluate until called, enabling lazy patterns:

```io
// Lazy if (already built-in, but here's how it works)
lazyIf := method(condition, trueBlock, falseBlock,
    if(condition,
        trueBlock call,
        falseBlock call
    )
)

x := 5
lazyIf(x > 3,
    block("Greater" println),
    block("Lesser" println)
)

// Lazy infinite sequences
naturals := method(start,
    block(
        n := start
        block(
            current := n
            n = n + 1
            current
        )
    ) call
)

seq := naturals(1)
5 repeat(seq call println)  // 1, 2, 3, 4, 5
```

## Memoization

Use closures to cache expensive computations:

```io
memoize := method(f,
    cache := Map clone
    
    block(
        args := call message arguments
        key := args asString
        
        if(cache hasKey(key),
            cache at(key),
            result := f call(args)
            cache atPut(key, result)
            result
        )
    )
)

// Expensive fibonacci
fib := block(n,
    if(n < 2, n, fib call(n - 1) + fib call(n - 2))
)

// Memoized version
fastFib := memoize(fib)

// Much faster on repeated calls
time(fib call(30)) println
time(fastFib call(30)) println
```

## Block Introspection

Blocks are objects you can inspect:

```io
myBlock := block(x, y, x + y * 2)

// Inspect structure
myBlock argumentNames println  // list(x, y)
myBlock code println           // x +(y *(2))

// Modify blocks
myBlock setArgumentNames(list("a", "b"))
myBlock argumentNames println  // list(a, b)

// Create blocks programmatically
code := "a + b"
args := list("a", "b")
dynamicBlock := Block clone setArgumentNames(args) setCode(code)
dynamicBlock call(3, 4) println  // 7
```

## Blocks in Data Structures

```io
// Table of operations
operations := Map with(
    "+", block(a, b, a + b),
    "-", block(a, b, a - b),
    "*", block(a, b, a * b),
    "/", block(a, b, a / b)
)

calculate := method(op, a, b,
    operations at(op) call(a, b)
)

calculate("+", 5, 3) println  // 8
calculate("*", 4, 7) println  // 28

// Event handlers
EventEmitter := Object clone
EventEmitter init := method(
    self events := Map clone
    self
)

EventEmitter on := method(event, handler,
    if(events hasKey(event) not,
        events atPut(event, list())
    )
    events at(event) append(handler)
    self
)

EventEmitter emit := method(event, data,
    if(events hasKey(event),
        events at(event) foreach(handler,
            handler call(data)
        )
    )
    self
)

// Usage
emitter := EventEmitter clone init
emitter on("click", block(data,
    ("Clicked at: " .. data) println
))
emitter on("click", block(data,
    ("Another handler: " .. data) println
))

emitter emit("click", "x=10, y=20")
// Clicked at: x=10, y=20
// Another handler: x=10, y=20
```

## Control Flow with Blocks

Create custom control structures:

```io
// Retry logic
retry := method(times, block,
    attempts := 0
    loop(
        attempts = attempts + 1
        e := try(result := block call)
        
        if(e isNil, return result)
        if(attempts >= times, Exception raise(e))
        
        ("Attempt " .. attempts .. " failed, retrying...") println
    )
)

// Usage
result := retry(3, block(
    if(Random value < 0.7,
        Exception raise("Random failure"),
        "Success!"
    )
))

// While with condition block
whileTrue := method(conditionBlock, bodyBlock,
    while(conditionBlock call, bodyBlock call)
)

i := 0
whileTrue(
    block(i < 5),
    block(
        i println
        i = i + 1
    )
)
```

## Performance Considerations

```io
// Method vs Block performance
obj := Object clone
obj value := 10

obj method1 := method(x, x + value)
obj block1 := block(x, x + 10)

// Methods are slightly faster for object operations
time(100000 repeat(obj method1(5)))
time(100000 repeat(obj block1 call(5)))

// But blocks are better for functional patterns
numbers := list(1, 2, 3, 4, 5)
time(numbers map(x, x * 2))  // Using block syntax
```

## Advanced Patterns

### Continuation-Style Programming

```io
// Continuation passing style
factorial := method(n, continuation,
    if(n <= 1,
        continuation call(1),
        factorial(n - 1, block(result,
            continuation call(n * result)
        ))
    )
)

factorial(5, block(result, result println))  // 120
```

### Monadic Patterns

```io
// Maybe monad
Maybe := Object clone
Maybe Nothing := Maybe clone
Maybe Just := method(value,
    m := Maybe clone
    m value := value
    m isNothing := false
    m
)
Maybe Nothing isNothing := true

Maybe bind := method(f,
    if(isNothing, Maybe Nothing, f call(value))
)

Maybe map := method(f,
    if(isNothing, 
        Maybe Nothing,
        Maybe Just(f call(value))
    )
)

// Usage
result := Maybe Just(5) \
    map(block(x, x * 2)) \
    bind(block(x, 
        if(x > 5, 
            Maybe Just(x), 
            Maybe Nothing)
    )) \
    map(block(x, x + 1))

if(result isNothing not,
    result value println  // 11
)
```

### Transducers

```io
// Composable transformations
mapping := method(f,
    method(reducer,
        block(acc, item,
            reducer call(acc, f call(item))
        )
    )
)

filtering := method(pred,
    method(reducer,
        block(acc, item,
            if(pred call(item),
                reducer call(acc, item),
                acc
            )
        )
    )
)

// Compose transducers
transduce := method(xform, reducer, init, coll,
    xreducer := xform call(reducer)
    coll foreach(item,
        init = xreducer call(init, item)
    )
    init
)

// Usage
xform := filtering(block(x, x % 2 == 0)) call(
    mapping(block(x, x * 2))
)

result := transduce(xform, 
    block(acc, x, acc + x),
    0,
    list(1, 2, 3, 4, 5, 6)
)
result println  // 24 (2*2 + 4*2 + 6*2)
```

## Common Pitfalls

### Variable Capture

```io
// PROBLEM: Loop variable capture
handlers := list()
for(i, 1, 3,
    handlers append(block(i println))
)

handlers foreach(h, h call)  // All print 3!

// SOLUTION: Create new scope
handlers := list()
for(i, 1, 3,
    handlers append(
        method(n, block(n println)) call(i)
    )
)

handlers foreach(h, h call)  // 1, 2, 3
```

### Memory Leaks with Closures

```io
// PROBLEM: Closure keeps large object alive
makeClosure := method(
    hugeData := List clone
    10000 repeat(hugeData append(Random value))
    
    block(x, x * 2)  // Doesn't use hugeData but keeps it alive!
)

// SOLUTION: Be explicit about captured variables
makeClosure := method(
    hugeData := List clone
    10000 repeat(hugeData append(Random value))
    processedValue := hugeData size  // Extract what you need
    hugeData = nil  // Release reference
    
    block(x, x * processedValue)
)
```

## Exercises

1. **Promise Implementation**: Create a Promise/Future system using blocks for async operations.

2. **Stream Processing**: Build a lazy stream processor with map, filter, and reduce.

3. **Function Decorator**: Implement decorators for logging, timing, and caching.

4. **Parser Combinators**: Create a simple parser combinator library using blocks.

5. **Reactive System**: Build a simple FRP (Functional Reactive Programming) system.

## Real-World Example: Pipeline Builder

```io
Pipeline := Object clone
Pipeline init := method(
    self steps := list()
    self
)

Pipeline add := method(step,
    steps append(step)
    self
)

Pipeline map := method(f,
    self add(block(data,
        data map(f)
    ))
)

Pipeline filter := method(pred,
    self add(block(data,
        data select(pred)
    ))
)

Pipeline tap := method(f,
    self add(block(data,
        f call(data)
        data
    ))
)

Pipeline run := method(input,
    result := input
    steps foreach(step,
        result = step call(result)
    )
    result
)

// Usage
pipeline := Pipeline clone init \
    filter(block(x, x % 2 == 0)) \
    map(block(x, x * x)) \
    tap(block(data, ("After squaring: " .. data) println)) \
    filter(block(x, x > 10)) \
    map(block(x, x asString))

result := pipeline run(list(1, 2, 3, 4, 5, 6))
// After squaring: list(4, 16, 36)
result println  // list("16", "36")
```

## Conclusion

Blocks and closures are fundamental to Io's expressiveness. They're not just anonymous functions—they're first-class objects that capture context, enable functional programming, and allow you to extend the language with new control structures.

The distinction between blocks (isolated scope) and methods (shared scope with receiver) provides flexibility in how you structure code. Closures emerge naturally from Io's scope rules, making complex patterns like memoization, continuations, and higher-order functions straightforward to implement.

Understanding blocks deeply unlocks Io's full potential, enabling you to write code that's both powerful and elegant.

---

*Next: [Chapter 10 - Exceptions](10-exceptions.md)*
