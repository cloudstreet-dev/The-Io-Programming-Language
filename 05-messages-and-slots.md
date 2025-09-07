# Chapter 5: Messages and Slots

At the heart of Io lies a simple but powerful idea: all computation happens through message passing. Objects communicate by sending messages to each other, and objects respond to messages by looking up slots. This chapter explores this fundamental mechanism in depth.

## The Anatomy of a Message

When you write this in Io:

```io
person setName("Alice")
```

What actually happens? Let's break it down:

1. `person` is the **receiver** - the object receiving the message
2. `setName` is the **message name** (or selector)
3. `"Alice"` is the **argument** to the message
4. The entire expression is a **message send**

But here's where it gets interesting. Messages are objects too:

```io
// Create a message object
msg := message(person setName("Alice"))

// Inspect it
msg name println          // setName
msg arguments println     // list(Message_0x...)
msg arguments first code println  // "Alice"

// Execute it
msg doInContext(Lobby)    // Actually calls person setName("Alice")
```

## Slots: The Object's Memory

Slots are named storage locations in objects. They can hold any value:

```io
obj := Object clone

// Create slots with different values
obj number := 42                    // Number
obj text := "hello"                 // String
obj method := method(x, x * 2)      // Method
obj child := Object clone            // Another object
obj flag := true                     // Boolean

// List all slots
obj slotNames println
// list(number, text, method, child, flag)

// Check for slots
obj hasSlot("number") println       // true
obj hasSlot("missing") println      // false

// Get slot values
obj getSlot("number") println       // 42
obj getSlot("method") println       // method(x, ...)
```

## The Message Resolution Algorithm

When an object receives a message, Io follows a specific algorithm to find the corresponding slot:

```io
Animal := Object clone
Animal speak := method("generic sound" println)

Dog := Animal clone
Dog speak := method("woof" println)
Dog wagTail := method("wagging..." println)

rover := Dog clone
rover name := "Rover"

// When rover receives 'speak':
rover speak
// 1. Look for 'speak' in rover - not found
// 2. Look for 'speak' in rover's proto (Dog) - found!
// 3. Execute Dog's speak method with rover as self

// When rover receives 'name':
rover name
// 1. Look for 'name' in rover - found!
// 2. Return the value

// Visual representation:
/*
    Object
      ↑
    Animal (speak: "generic sound")
      ↑
     Dog (speak: "woof", wagTail)
      ↑
    rover (name: "Rover")
*/
```

## Creating and Modifying Slots

Io distinguishes between creating new slots and updating existing ones:

```io
obj := Object clone

// Create a new slot with :=
obj x := 10
obj hasSlot("x") println         // true

// Update existing slot with =
obj x = 20
obj x println                    // 20

// Trying to update non-existent slot fails
obj y = 30                       // Exception: Slot y not found

// But you can use setSlot to create or update
obj setSlot("y", 30)            // Creates if doesn't exist
obj y println                    // 30

// Remove slots
obj removeSlot("y")
obj hasSlot("y") println        // false
```

This distinction helps catch typos:

```io
counter := 0
countr = 1    // Error! Probably meant 'counter'
```

## Methods Are Just Slots

In Io, methods aren't special—they're just slots that hold executable blocks:

```io
Calculator := Object clone

// Method is just a slot containing a method object
Calculator add := method(a, b, a + b)

// You can manipulate methods like any other value
addMethod := Calculator getSlot("add")
addMethod type println           // Block

// You can copy methods between objects
ScientificCalc := Object clone
ScientificCalc addition := Calculator getSlot("add")
ScientificCalc addition(5, 3) println  // 8

// You can even store methods in variables
operation := method(x, x * 2)
Calculator double := operation
Calculator double(21) println    // 42
```

## The 'self' and 'sender' Context

Every method has access to special variables:

```io
Printer := Object clone
Printer name := "HP"
Printer print := method(doc,
    ("Printer: " .. self name) println    // self = receiver
    ("Sender: " .. sender type) println   // sender = who sent the message
    ("Document: " .. doc) println
)

Computer := Object clone
Computer sendJob := method(
    Printer print("report.pdf")
)

Computer sendJob
// Printer: HP
// Sender: Computer
// Document: report.pdf
```

## Message Forwarding

When an object doesn't have a slot for a received message, it calls `forward`:

```io
Proxy := Object clone
Proxy target := nil
Proxy forward := method(
    ("Forwarding " .. call message name .. " to target") println
    call evalArgAt(0) // This would forward to target
)

p := Proxy clone
p doSomething("arg")
// Forwarding doSomething to target
```

This enables powerful patterns like delegation and method missing:

```io
// Ruby-style method_missing
DynamicObject := Object clone
DynamicObject forward := method(
    methodName := call message name
    if(methodName beginsWithSeq("get"),
        # Handle getters
        property := methodName afterSeq("get") lowercase
        self getSlot(property),
        # Handle setters
        if(methodName beginsWithSeq("set"),
            property := methodName afterSeq("set") lowercase
            value := call evalArgAt(0)
            self setSlot(property, value)
        )
    )
)

obj := DynamicObject clone
obj setName("Alice")     // Creates 'name' slot
obj getName println       // "Alice"
```

## Lazy Evaluation with Messages

Messages don't evaluate immediately—they're data structures you can manipulate:

```io
// Messages as data
expr := message(2 + 3 * 4)
expr println             // 2 +(3 *(4))

// Evaluate when ready
result := expr doInContext(Lobby)
result println           // 14

// Modify messages before evaluation
expr := message(x + y)
context := Object clone
context x := 10
context y := 20
expr doInContext(context) println  // 30
```

This enables macro-like capabilities:

```io
// Create a timing macro
Object time := method(
    code := call argAt(0)  // Get the message, not its value
    start := Date now
    result := code doInContext(call sender)
    elapsed := Date now - start
    ("Elapsed: " .. elapsed) println
    result
)

// Use it
time(
    sum := 0
    for(i, 1, 1000000, sum = sum + i)
    sum
)
// Elapsed: 0.234
// Returns: 500000500000
```

## Call Introspection

The `call` object provides detailed information about the current method invocation:

```io
Object debug := method(
    "=== Call Debug ===" println
    ("Sender: " .. call sender type) println
    ("Target: " .. call target type) println
    ("Message: " .. call message name) println
    ("Args: " .. call message arguments) println
    ("Activated: " .. call activated type) println
    "================" println
)

TestObject := Object clone
TestObject test := method(
    debug
)

TestObject test
// === Call Debug ===
// Sender: Lobby
// Target: TestObject
// Message: debug
// Args: list()
// Activated: Block
// ================
```

## Operator Messages

Operators are messages with special precedence rules:

```io
// These are equivalent
2 + 3 * 4
2 +(3 *(4))

// You can see the precedence
OperatorTable println

// You can add custom operators
OperatorTable addOperator("@@", 5)
Number @@ := method(n,
    self pow(n) + n pow(self)
)

2 @@ 3 println  // 17 (2^3 + 3^2 = 8 + 9)

// Operators are just messages
5 send("+", 3) println  // 8
"hello" send("at", 1) println  // e
```

## Assignment Messages

Even assignment is message passing:

```io
// These are equivalent
x := 10
setSlot("x", 10)

// And these
x = 20
updateSlot("x", 20)

// You can override assignment behavior
Object setSlot := method(name, value,
    ("Setting " .. name .. " to " .. value) println
    resend  // Call original setSlot
)

y := 42
// Setting y to 42
```

## Method Activation vs. Value Access

Io distinguishes between activatable and non-activatable values:

```io
obj := Object clone

// Methods are activatable - they run when accessed
obj greet := method("Hello!" println)
obj greet  // Prints "Hello!"

// Other values are just returned
obj name := "Alice"
obj name  // Returns "Alice"

// You can get a method without activating it
m := obj getSlot("greet")
m println  // method(...)

// And activate it later
m call  // Prints "Hello!"

// Check if something is activatable
obj getSlot("greet") isActivatable println  // true
obj getSlot("name") isActivatable println   // false
```

## Building a Message-Based DSL

Let's build a simple HTML DSL using messages:

```io
HTML := Object clone
HTML forward := method(
    tagName := call message name
    args := call message arguments
    
    // Build opening tag
    result := "<" .. tagName
    
    // Handle attributes (first arg if it's a Map)
    if(args size > 0 and args at(0) name == "curlyBrackets",
        attrs := call evalArgAt(0)
        attrs foreach(key, value,
            result = result .. " " .. key .. "=\"" .. value .. "\""
        )
        args removeFirst
    )
    
    result = result .. ">"
    
    // Handle content
    args foreach(arg,
        content := call sender doMessage(arg)
        if(content, result = result .. content)
    )
    
    // Closing tag
    result = result .. "</" .. tagName .. ">"
    result
)

// Usage
html := HTML clone

page := html div({ "class": "container" },
    html h1("Welcome"),
    html p("This is a paragraph"),
    html ul(
        html li("Item 1"),
        html li("Item 2")
    )
)

page println
// <div class="container"><h1>Welcome</h1><p>This is a paragraph</p><ul><li>Item 1</li><li>Item 2</li></ul></div>
```

## Performance Considerations

Message passing has overhead compared to direct function calls:

```io
// Traditional method call
obj := Object clone
obj directMethod := method(x, x * 2)

// Message construction and sending
msg := Message clone setName("directMethod") setArguments(list(Message clone setName("5")))

// Benchmark
time(
    100000 times(obj directMethod(5))
)

time(
    100000 times(obj doMessage(msg))
)

// Direct calls are faster, but message objects enable metaprogramming
```

## Common Patterns

### Property Access Pattern

```io
Person := Object clone
Person init := method(
    self name := nil
    self age := nil
    self
)

// Generate getters/setters with messages
Person addAccessors := method(slotName,
    // Getter
    self setSlot(slotName, 
        method(self getSlot("_" .. slotName))
    )
    
    // Setter  
    self setSlot("set" .. slotName asCapitalized,
        method(value, self setSlot("_" .. slotName, value))
    )
)

Person addAccessors("name")
Person addAccessors("age")

p := Person clone
p setName("Alice")
p name println  // "Alice"
```

### Chain of Responsibility

```io
Handler := Object clone
Handler next := nil
Handler handle := method(request,
    if(self canHandle(request),
        self process(request),
        if(next, next handle(request))
    )
)

AuthHandler := Handler clone
AuthHandler canHandle := method(request,
    request hasSlot("needsAuth")
)
AuthHandler process := method(request,
    "Authenticating..." println
)

LogHandler := Handler clone  
LogHandler canHandle := method(request, true)
LogHandler process := method(request,
    ("Logging: " .. request type) println
)

// Build chain
auth := AuthHandler clone
log := LogHandler clone
auth next := log

// Process requests
request := Object clone
request type := "GET"
request needsAuth := true

auth handle(request)
// Authenticating...
// Logging: GET
```

## Debugging Messages

Understanding message flow is crucial for debugging:

```io
Object trace := method(
    self setSlot("forward",
        method(
            ("Missing: " .. call message name) println
            ("Arguments: " .. call message arguments) println
            ("Sender: " .. sender type) println
        )
    )
    self
)

buggy := Object clone trace
buggy doSomethingWrong(1, 2, 3)
// Missing: doSomethingWrong
// Arguments: list(1, 2, 3)
// Sender: Lobby
```

## Exercises

1. **Message Logger**: Create a wrapper that logs all messages sent to an object, including arguments and return values.

2. **Lazy Properties**: Implement properties that are only computed when first accessed, then cached.

3. **Message Queue**: Build an object that queues messages and executes them later in order.

4. **Method Decorators**: Create a system for wrapping methods with before/after behavior using messages.

5. **Message Router**: Build a router that directs messages to different handlers based on patterns.

## Advanced Message Techniques

### Message Rewriting

```io
Rewriter := Object clone
Rewriter forward := method(
    msg := call message
    
    // Rewrite add to multiply
    if(msg name == "add",
        msg setName("multiply")
    )
    
    // Continue with modified message
    resend
)

calc := Rewriter clone
calc multiply := method(a, b, a * b)
calc add(3, 4) println  // 12 (rewritten to multiply!)
```

### Conditional Message Sending

```io
Object sendIf := method(condition, messageName,
    if(condition,
        self doMessage(Message clone setName(messageName))
    )
)

Object sendUnless := method(condition, messageName,
    if(condition not,
        self doMessage(Message clone setName(messageName))
    )
)

obj := Object clone
obj greet := method("Hello!" println)

obj sendIf(true, "greet")      // Hello!
obj sendUnless(false, "greet")  // Hello!
```

## Conclusion

Messages and slots form the foundation of Io's object model. Every computation—from simple arithmetic to complex method calls—is accomplished through message passing. Objects store their state and behavior in slots, and respond to messages by looking up the corresponding slots.

This uniform model provides incredible flexibility. You can intercept messages, forward them, rewrite them, or queue them. You can introspect the entire message-passing process. You can build DSLs that feel native to the language. And you can debug by tracing the flow of messages through your system.

Understanding messages and slots deeply is essential to mastering Io. They're not just an implementation detail—they're the conceptual core that makes Io's radical simplicity possible.

---

*Next: [Chapter 6 - Cloning and Inheritance](06-cloning-and-inheritance.md)*