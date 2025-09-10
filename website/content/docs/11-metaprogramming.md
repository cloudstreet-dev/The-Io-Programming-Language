---
title: "Metaprogramming"
weight: 120
---



# Chapter 11: Metaprogramming

Metaprogramming—writing code that manipulates code—is where Io truly shines. Since everything in Io is an object, including messages and methods, you can inspect, modify, and generate code at runtime. This chapter explores Io's powerful metaprogramming capabilities.

## Messages as Data

In Io, code is data. Messages are objects you can create, inspect, and manipulate:

```io
// Create a message from code
msg := message(2 + 3 * 4)

// Inspect its structure
msg println              // 2 +(3 *(4))
msg name println         // +
msg arguments println    // list(Message_0x...)
msg arguments at(0) println  // 3 *(4)

// Evaluate it
result := msg doInContext(Lobby)
result println           // 14

// Modify it
msg setName("*")
msg doInContext(Lobby) println  // 6 (now it's 2 * 3 * 4)
```

Compare this to Lisp's code-as-data philosophy:

```lisp
; Lisp
(defparameter code '(+ 2 (* 3 4)))
(eval code)  ; 14
```

But Io uses messages instead of lists, which feels more natural for object-oriented code.

## Building Messages Programmatically

```io
// Build a message from scratch
msg := Message clone
msg setName("println")
msg setArguments(list(Message clone setName("\"Hello, World!\"")))

// Execute it
Lobby doMessage(msg)  // Hello, World!

// Build more complex messages
createAdder := method(n,
    msg := Message clone setName("+")
    msg setArguments(list(Message clone setName(n asString)))
    msg
)

adder5 := createAdder(5)
7 doMessage(adder5) println  // 12
```

## Method Introspection

Methods are objects you can examine and modify:

```io
obj := Object clone
obj greet := method(name, "Hello, " .. name .. "!")

// Get the method object
m := obj getSlot("greet")
m type println                    // Block
m argumentNames println           // list(name)
m code println                   // "Hello, " ..(name) ..("!")

// Modify method implementation
obj greet = method(name, "Goodbye, " .. name .. "!")
obj greet("World") println       // Goodbye, World!

// Copy methods between objects
other := Object clone
other sayHi := obj getSlot("greet")
other sayHi("Io") println        // Goodbye, Io!
```

## The call Object

The `call` object provides runtime context information:

```io
Object introspect := method(
    "=== Call Introspection ===" println
    ("Sender: " .. call sender type) println
    ("Target: " .. call target type) println
    ("Message: " .. call message) println
    ("Arguments: " .. call message arguments) println
    ("Activated: " .. call activated) println
    "========================" println
)

TestObj := Object clone
TestObj test := method(a, b,
    introspect
    a + b
)

TestObj test(5, 3)
// === Call Introspection ===
// Sender: Lobby
// Target: TestObj
// Message: introspect
// Arguments: list()
// Activated: method(...)
// ========================
```

## Dynamic Method Creation

Create methods at runtime:

```io
// Create getters and setters dynamically
Object addProperty := method(name, defaultValue,
    // Create storage slot
    self setSlot("_" .. name, defaultValue)
    
    // Create getter
    self setSlot(name, 
        method(self getSlot("_" .. call message name))
    )
    
    // Create setter
    self setSlot("set" .. name asCapitalized,
        method(value,
            self setSlot("_" .. call message name beforeSeq("set") asLowercase, value)
            self  // For chaining
        )
    )
)

Person := Object clone
Person addProperty("name", "Unknown")
Person addProperty("age", 0)

p := Person clone
p setName("Alice") setAge(30)
p name println   // Alice
p age println    // 30
```

## Method Missing Pattern

Intercept undefined method calls:

```io
DynamicObject := Object clone
DynamicObject forward := method(
    messageName := call message name
    args := call message arguments
    
    ("Intercepted: " .. messageName) println
    ("Arguments: " .. args) println
    
    // Handle dynamically
    if(messageName beginsWithSeq("get"),
        property := messageName afterSeq("get") asLowercase
        return self getSlot(property)
    )
    
    if(messageName beginsWithSeq("set"),
        property := messageName afterSeq("set") asLowercase
        value := call evalArgAt(0)
        return self setSlot(property, value)
    )
    
    Exception raise("Unknown method: " .. messageName)
)

obj := DynamicObject clone
obj setName("Bob")      // Intercepted: setName
obj getName println      // Bob
```

## Code Generation

Generate code as strings and evaluate:

```io
// Generate a class-like structure
generateClass := method(className, properties,
    code := className .. " := Object clone\n"
    
    // Generate init method
    code = code .. className .. " init := method(\n"
    properties foreach(prop,
        code = code .. "    self " .. prop .. " := nil\n"
    )
    code = code .. "    self\n)\n"
    
    // Generate property accessors
    properties foreach(prop,
        // Getter
        code = code .. className .. " " .. prop .. " := method(_" .. prop .. ")\n"
        // Setter
        code = code .. className .. " set" .. prop asCapitalized .. " := method(v, _" .. prop .. " = v; self)\n"
    )
    
    code doString  // Evaluate the generated code
    Lobby getSlot(className)  // Return the created object
)

// Use the generator
Car := generateClass("Car", list("make", "model", "year"))
myCar := Car clone init
myCar setMake("Toyota") setModel("Camry") setYear(2020)
myCar make println  // Toyota
```

## Aspect-Oriented Programming

Implement cross-cutting concerns:

```io
// Method wrapping for logging
Object addLogging := method(methodName,
    original := self getSlot(methodName)
    
    self setSlot(methodName, method(
        ("Calling " .. methodName .. " with args: " .. call message arguments) println
        result := nil
        e := try(result = original doMessage(call message, call sender))
        if(e,
            ("Error in " .. methodName .. ": " .. e message) println
            e raise,
            ("Returned: " .. result) println
            result
        )
    ))
)

Calculator := Object clone
Calculator add := method(a, b, a + b)
Calculator divide := method(a, b, a / b)

Calculator addLogging("add")
Calculator addLogging("divide")

Calculator add(5, 3)
// Calling add with args: list(5, 3)
// Returned: 8

Calculator divide(10, 0)
// Calling divide with args: list(10, 0)
// Error in divide: divide by zero
```

## Macro System

Io's macros transform code before evaluation:

```io
// Define a macro
Object unless := macro(condition, action,
    // Macros receive unevaluated arguments as messages
    // Transform to if(condition not, action)
    message(if) setArguments(
        list(
            message(not) setTarget(condition),
            action
        )
    )
)

// Use the macro
x := 5
unless(x > 10, "x is not greater than 10" println)
// x is not greater than 10

// Timing macro
Object time := macro(code,
    // Generate timing code
    message(do) setArguments(list(
        message(start := Date now),
        code,
        message(elapsed := Date now - start),
        message(("Elapsed: " .. elapsed) println),
        message(result)
    ))
)

// Use it
time(
    sum := 0
    for(i, 1, 1000000, sum = sum + i)
    sum
)
// Elapsed: 0.234
```

## Self-Modifying Code

Objects can modify their own methods:

```io
Counter := Object clone
Counter count := 0
Counter increment := method(
    count = count + 1
    
    // Self-modify after 5 calls
    if(count >= 5,
        self increment = method(
            Exception raise("Counter limit reached")
        )
    )
    
    count
)

c := Counter clone
5 repeat(i, c increment println)  // 1, 2, 3, 4, 5
c increment  // Exception: Counter limit reached
```

## Reflection API

Io provides comprehensive reflection capabilities:

```io
// Object introspection utilities
Object describe := method(
    ("Type: " .. self type) println
    
    "Local Slots:" println
    self slotNames sort foreach(name,
        value := self getSlot(name)
        ("  " .. name .. " = " .. value type) println
    )
    
    "Proto chain:" println
    proto := self proto
    while(proto and proto != Object,
        ("  -> " .. proto type) println
        proto = proto proto
    )
)

// Usage
person := Object clone
person name := "Alice"
person age := 30
person greet := method("Hello!")

person describe
// Type: Object
// Local Slots:
//   age = Number
//   greet = Block
//   name = Sequence
// Proto chain:
//   -> Object
```

## DSL Creation with Metaprogramming

Build domain-specific languages:

```io
// SQL-like DSL
Table := Object clone
Table columns := list()
Table rows := list()

Table select := method(
    query := SelectQuery clone
    query table := self
    query
)

SelectQuery := Object clone
SelectQuery conditions := list()

SelectQuery where := method(
    // Parse conditions from arguments
    args := call message arguments
    args foreach(arg,
        conditions append(arg)
    )
    self
)

SelectQuery execute := method(
    table rows select(row,
        result := true
        conditions foreach(cond,
            result = result and cond doInContext(row)
        )
        result
    )
)

// Usage
users := Table clone
users columns = list("name", "age", "city")
users rows = list(
    Object clone do(name := "Alice"; age := 30; city := "NYC"),
    Object clone do(name := "Bob"; age := 25; city := "LA"),
    Object clone do(name := "Charlie"; age := 35; city := "NYC")
)

results := users select where(age > 25, city == "NYC") execute
results foreach(r, (r name .. ": " .. r age) println)
// Alice: 30
// Charlie: 35
```

## Performance Profiling

Use metaprogramming for profiling:

```io
Profiler := Object clone
Profiler stats := Map clone

Object profile := method(methodName,
    original := self getSlot(methodName)
    
    self setSlot(methodName, method(
        start := Date now
        result := original doMessage(call message, call sender)
        elapsed := Date now - start
        
        key := self type .. "::" .. methodName
        if(Profiler stats hasKey(key) not,
            Profiler stats atPut(key, list(0, 0))
        )
        
        stats := Profiler stats at(key)
        stats atPut(0, stats at(0) + 1)      // Count
        stats atPut(1, stats at(1) + elapsed) // Total time
        
        result
    ))
)

Profiler report := method(
    "=== Profiling Report ===" println
    stats foreach(key, data,
        avg := data at(1) / data at(0)
        (key .. ": " .. data at(0) .. " calls, " .. 
         data at(1) .. "s total, " .. avg .. "s avg") println
    )
)

// Usage
Math := Object clone
Math factorial := method(n,
    if(n <= 1, 1, n * factorial(n - 1))
)
Math profile("factorial")

10 repeat(Math factorial(20))
Profiler report
```

## Compile-Time Computation

Use macros for compile-time optimization:

```io
// Macro that pre-computes constant expressions
Object precompute := macro(expr,
    // If expression contains only literals, evaluate now
    result := nil
    e := try(result = expr doInContext(Object clone))
    
    if(e isNil,
        // Successfully evaluated - return literal
        Message clone setName(result asString),
        // Contains variables - return original
        expr
    )
)

// Usage
x := 10
y := precompute(5 * 6 + 7)  // Computed at parse time
z := precompute(x * 2)      // Can't precompute, has variable

y println  // 37 (was precomputed)
```

## Method Combination

Implement method combination patterns:

```io
// Before/After/Around methods
Object addBefore := method(methodName, beforeBlock,
    original := self getSlot(methodName)
    self setSlot(methodName, method(
        beforeBlock doMessage(call message, call sender)
        original doMessage(call message, call sender)
    ))
)

Object addAfter := method(methodName, afterBlock,
    original := self getSlot(methodName)
    self setSlot(methodName, method(
        result := original doMessage(call message, call sender)
        afterBlock call(result)
        result
    ))
)

Object addAround := method(methodName, aroundBlock,
    original := self getSlot(methodName)
    self setSlot(methodName, method(
        aroundBlock call(original, call message, call sender)
    ))
)

// Usage
BankAccount := Object clone
BankAccount balance := 100
BankAccount withdraw := method(amount, balance = balance - amount)

BankAccount addBefore("withdraw", method(amount,
    ("Withdrawing " .. amount) println
))

BankAccount addAfter("withdraw", method(result,
    ("New balance: " .. balance) println
))

BankAccount addAround("withdraw", method(original, msg, sender,
    amount := msg argAt(0) doInContext(sender)
    if(amount > balance,
        Exception raise("Insufficient funds"),
        original doMessage(msg, sender)
    )
))

account := BankAccount clone
account withdraw(50)
// Withdrawing 50
// New balance: 50
```

## Common Pitfalls

### Evaluation Context

```io
// PROBLEM: Wrong context
makeMethod := method(code,
    method doString(code)  // code evaluates in method's context
)

obj := Object clone
obj value := 10
obj badMethod := makeMethod("value * 2")
// obj badMethod  // Error: value not found

// SOLUTION: Use message objects
makeMethod := method(code,
    method(code doInContext(self))
)
```

### Performance Impact

```io
// Metaprogramming has runtime cost
directCall := method(x, x * 2)
dynamicCall := method(x,
    msg := Message clone setName("*") setArguments(list(Message clone setName("2")))
    x doMessage(msg)
)

// directCall is much faster than dynamicCall
```

## Exercises

1. **Memoization Decorator**: Create a decorator that automatically memoizes any method.

2. **Contract System**: Implement Design by Contract with pre/post conditions.

3. **Mock Object Generator**: Build a system that generates mock objects for testing.

4. **Dependency Injection**: Create a DI container using metaprogramming.

5. **ORM**: Build a simple object-relational mapper that generates methods from table schemas.

## Real-World Example: ActiveRecord Pattern

```io
// Simple ActiveRecord implementation
ActiveRecord := Object clone
ActiveRecord tableName := nil
ActiveRecord connection := nil  // Database connection

ActiveRecord findById := method(id,
    sql := "SELECT * FROM " .. tableName .. " WHERE id = " .. id
    row := connection execute(sql) first
    if(row,
        obj := self clone
        row foreach(column, value,
            obj setSlot(column, value)
        )
        obj
    )
)

ActiveRecord save := method(
    if(hasSlot("id"),
        // Update
        sql := "UPDATE " .. tableName .. " SET "
        updates := list()
        slotNames foreach(name,
            if(name != "id",
                updates append(name .. " = '" .. getSlot(name) .. "'")
            )
        )
        sql = sql .. updates join(", ") .. " WHERE id = " .. id
    ,
        // Insert
        sql := "INSERT INTO " .. tableName
        columns := list()
        values := list()
        slotNames foreach(name,
            columns append(name)
            values append("'" .. getSlot(name) .. "'")
        )
        sql = sql .. " (" .. columns join(", ") .. ") VALUES (" .. values join(", ") .. ")"
    )
    
    connection execute(sql)
    self
)

// Generate model from table
generateModel := method(name, table, columns,
    model := ActiveRecord clone
    model type := name
    model tableName = table
    
    // Add properties
    columns foreach(column,
        model setSlot(column, nil)
    )
    
    // Add validations
    model validate := method(
        // Generated validation code
        true
    )
    
    // Store in Lobby
    Lobby setSlot(name, model)
    model
)

// Usage
User := generateModel("User", "users", list("id", "name", "email", "age"))

user := User clone
user name = "Alice"
user email = "alice@example.com"
user age = 30
// user save

foundUser := User findById(1)
```

## Conclusion

Metaprogramming in Io isn't a special feature—it's a natural consequence of the language's design. When everything is an object, including code itself, manipulation becomes straightforward. Messages as first-class objects, comprehensive reflection, and runtime modification enable powerful patterns that would require complex machinery in other languages.

The key to effective metaprogramming in Io is understanding that you're not working with special metaprogramming constructs, but simply manipulating objects that happen to represent code. This uniformity makes metaprogramming accessible and powerful, though it requires careful consideration of evaluation contexts and performance implications.

---

