# Chapter 3: Everything is an Object

"Everything is an object" is a claim made by many languages. Ruby says it. Smalltalk says it. Even Java claims it (though primitives like `int` and `boolean` break the rule). But what does it really mean? And how thoroughly does Io embrace this principle?

In this chapter, we'll explore how Io takes "everything is an object" to its logical extreme, and what this means for how you write and think about programs.

## What Is an Object?

Before we dive into Io's object model, let's establish what we mean by "object." In most object-oriented languages, an object is:

1. A bundle of state (data/attributes/fields)
2. A set of behaviors (methods/functions)
3. An identity (distinct from other objects)

In Java, you might have:

```java
class Dog {
    String name;        // state
    int age;           // state
    
    void bark() {      // behavior
        System.out.println("Woof!");
    }
}

Dog fido = new Dog();  // identity (fido is distinct from other Dogs)
```

But Java immediately breaks its own rules:

```java
int x = 5;          // Not an object!
x.toString();       // Error: int cannot be dereferenced
Integer y = 5;      // Now it's an object (boxed)
y.toString();       // "5"
```

Let's see how Io handles this.

## Numbers are Objects

In Io, numbers aren't primitives—they're full objects:

```io
5 type println           // Number
5 slotNames println      // list(%, *, +, -, /, <, ...)

// Numbers have methods
5 abs println            // 5
-5 abs println           // 5
5 sqrt println           // 2.236...
5 sin println            // -0.958...

// You can add methods to numbers!
Number double := method(self * 2)
5 double println         // 10

// You can even inspect a number's prototype chain
5 proto println          // Number_0x...
5 proto proto println    // Object_0x...
```

Compare this to Python, which claims everything is an object:

```python
x = 5
print(type(x))           # <class 'int'>
print(dir(x))            # ['__abs__', '__add__', ...]

# But you can't add methods to numbers
x.double = lambda: x * 2  # AttributeError!
```

Python's numbers are objects, but they're *immutable* objects with a *fixed* set of methods. Io's numbers are fully modifiable objects.

## Strings are Objects (and Mutable!)

```io
text := "hello"
text type println        // Sequence

// Strings have methods
text size println        // 5
text upper println       // HELLO
text reverse println     // olleh

// But here's where it gets interesting - strings are MUTABLE
text atPut(0, 72)       // ASCII for 'H'
text println            // Hello

// You can add methods to strings
Sequence shout := method(self upper .. "!!!")
"hello" shout println   // HELLO!!!
```

This mutability might shock programmers from languages where strings are immutable:

```python
# Python - strings are immutable
text = "hello"
text[0] = 'H'  # TypeError: 'str' object does not support item assignment

# Java - strings are immutable
String text = "hello";
text.charAt(0) = 'H';  // Error: cannot assign a value
```

## Booleans are Objects

Even `true` and `false` are objects:

```io
true type println        // true
false type println       // false

// They have methods
true and(false) println  // false
true or(false) println   // true
true not println         // false

// The actual objects
true println             // true
true proto println       // Object_0x...

// You can even add methods to booleans!
true celebrate := method("Yay!" println)
(5 > 3) celebrate       // Yay!
```

This is different from most languages where booleans are either primitives or special immutable objects.

## nil is an Object

Even nothingness is an object in Io:

```io
nil type println         // Object
nil slotNames println    // list(type, ...)

// nil has methods!
nil isNil println        // true
nil not println          // true

// You can add methods to nil
nil greet := method("Hello from nothing!" println)
x := nil
x greet                  // Hello from nothing!
```

Compare with JavaScript's confusing null:

```javascript
typeof null          // "object" (but it's not really)
null.toString()      // TypeError: Cannot read property 'toString' of null
```

## Methods are Objects

This is where things get really interesting. Methods themselves are objects:

```io
add := method(a, b, a + b)
add type println         // Block

// Methods have methods!
add argumentNames println // list(a, b)
add code println         // a +(b)

// You can modify methods
add code println                    // a +(b)
add setCode(block(a, b, a * b))   // Change implementation!
add(3, 4) println                  // 12 (now multiplies!)

// You can create methods from strings
code := "a + b + 100"
newMethod := block(a, b) setCode(code)
newMethod call(5, 10) println      // 115
```

This is far more powerful than most languages' function objects:

```python
# Python
def add(a, b):
    return a + b

print(type(add))         # <class 'function'>
print(add.__code__)      # <code object...>
# But you can't easily modify the function's code at runtime
```

## Control Structures are Objects (Messages)

This might be the most mind-bending: `if`, `while`, and `for` aren't syntax—they're methods:

```io
// 'if' is a method on Object
if type println          // nil (it's a method)

// You can see its implementation
Object getSlot("if") println  // method(...)

// You can even redefine it!
Object if := method(condition, trueBlock, falseBlock,
    "Making a decision..." println
    if(condition, trueBlock call, falseBlock call)
)

if(true, "yes" println, "no" println)
// Prints: Making a decision...
// Prints: yes
```

Let's create our own control structure:

```io
Object unless := method(condition, block,
    if(condition not, block call)
)

unless(5 > 10,
    "Math still works!" println
)
// Prints: Math still works!
```

Try doing that in Java or C++!

## Operators are Objects (Messages)

Operators aren't special syntax—they're messages:

```io
// These are equivalent
2 + 3
2 +(3)
2 send("+", 3)

// You can redefine operators
Number + := method(n,
    "Adding #{self} and #{n}" interpolate println
    self + n  // Would cause infinite recursion!
)

// Let's be more careful
Number plusWithLogging := Number getSlot("+")
Number + := method(n,
    "Adding #{self} and #{n}" interpolate println
    self plusWithLogging(n)
)

2 + 3
// Prints: Adding 2 and 3
// Returns: 5
```

You can even create new operators:

```io
OperatorTable addOperator("**", 3)  // Right-associative, precedence 3
Number ** := method(n, self pow(n))

2 ** 3 println  // 8
2 ** 3 ** 2 println  // 512 (right-associative: 2 ** (3 ** 2))
```

## Lists are Objects

```io
nums := list(1, 2, 3)
nums type println        // List

// Lists have many methods
nums size println        // 3
nums first println       // 1
nums last println        // 3
nums reverse println     // list(3, 2, 1)

// Lists are mutable
nums append(4)
nums println            // list(1, 2, 3, 4)

// You can add custom methods to lists
List sum := method(
    self reduce(+)
)

list(1, 2, 3, 4, 5) sum println  // 15
```

## Even the Lobby is an Object

The global namespace in Io is an object called `Lobby`:

```io
Lobby type println       // Object
Lobby slotNames println  // list(all your global variables)

// When you create a "global" variable, you're adding a slot to Lobby
x := 10
Lobby hasSlot("x") println  // true
Lobby x println             // 10

// You can manipulate the global namespace as an object
Lobby removeSlot("x")
x println                   // Exception: Slot x not found
```

This is radically different from languages with special global scope rules.

## Messages Themselves are Objects

When you send a message, that message is an object:

```io
msg := message(2 + 3)
msg type println         // Message
msg name println         // +
msg arguments println    // list(Message_0x...)
msg arguments first code println  // 3

// You can evaluate messages
msg doInContext(Lobby) println   // 5

// You can build messages programmatically
msg := Message clone setName("+") setArguments(list(Message clone setName("3")))
2 doMessage(msg) println          // 5
```

This is the foundation of Io's metaprogramming capabilities.

## The Object Hierarchy

Let's explore how all these objects relate:

```io
// Everything ultimately inherits from Object
5 proto proto == Object println      // true
"hi" proto proto == Object println   // true
true proto == Object println         // true
list() proto proto == Object println // true

// You can walk the prototype chain
obj := 5
while(obj,
    obj type println
    obj = obj proto
)
// Prints:
// Number
// Object
```

## Practical Implications

What does it mean that everything is truly an object?

### 1. Uniform Interface

You can treat everything uniformly:

```io
things := list(5, "hello", true, nil, method(x, x * 2), list(1, 2))

things foreach(thing,
    ("Type: " .. thing type) println
)
// Type: Number
// Type: Sequence  
// Type: true
// Type: Object
// Type: Block
// Type: List
```

### 2. No Special Cases

You don't need to remember different rules for different types:

```io
// Everything can receive messages
5 println
"hello" println
true println
nil println
list(1,2,3) println

// Everything can be inspected
5 slotNames
"hello" slotNames
true slotNames
nil slotNames
```

### 3. Extensibility

You can extend anything:

```io
// Add methods to numbers for DSL
Number days := method(
    Duration clone setDays(self)
)

Number hours := method(
    Duration clone setHours(self)
)

// Now you can write
deadline := Date now + 3 days + 4 hours
```

### 4. Debugging Power

Since everything is an object, you can inspect everything:

```io
Object debugMethod := method(name,
    m := self getSlot(name)
    ("Method " .. name .. ":") println
    ("  Arguments: " .. m argumentNames) println
    ("  Code: " .. m code) println
)

List debugMethod("append")
// Method append:
//   Arguments: list(...)
//   Code: ...
```

## Comparison with Other Languages

### Ruby: "Everything is an object" (mostly)

```ruby
5.class          # Integer
"hello".class    # String
true.class       # TrueClass
nil.class        # NilClass

# But...
if.class         # SyntaxError! 'if' isn't an object
```

### Python: "Everything is an object" (sort of)

```python
type(5)          # <class 'int'>
type("hello")    # <class 'str'>
type(True)       # <class 'bool'>
type(None)       # <class 'NoneType'>

# But...
type(if)         # SyntaxError! 'if' isn't an object
type(+)          # SyntaxError! '+' isn't an object
```

### JavaScript: "Everything is an object" (except when it's not)

```javascript
typeof 5         // "number" (primitive)
typeof "hello"   // "string" (primitive)
typeof true      // "boolean" (primitive)
typeof {}        // "object"

// Autoboxing happens sometimes
(5).toString()   // "5" (temporarily boxed)
5.x = 10         // Silently fails!
```

### Io: Everything IS an object (no exceptions)

```io
5 type           // Number (object)
"hello" type     // Sequence (object)
true type        // true (object)
if type          // nil (it's a method, which is an object)
+ type           // nil (it's a method, which is an object)
```

## Exercises

1. **Object Inspector**: Write a method `inspect` that can be called on any object and prints:
   - Its type
   - Its slot names
   - Its prototype chain

2. **Custom Boolean**: Create your own boolean system with objects `Yes` and `No` that have methods `and`, `or`, and `not`.

3. **Operator Overloading**: Define a `Vector` object with `x` and `y` slots, then overload the `+` operator to add vectors.

4. **Control Structure**: Create a `repeat(n, block)` control structure that executes a block n times.

5. **Message Logger**: Modify the `Object` prototype to log every message sent to any object (hint: override `forward`).

## Philosophical Implications

Io's radical "everything is an object" approach has profound implications:

1. **Simplicity through uniformity**: One concept (objects) explains everything
2. **Power through openness**: Nothing is sealed or special
3. **Learning through exploration**: You can inspect and understand everything
4. **Danger through freedom**: You can break everything

This last point is important. With great power comes great responsibility. Io trusts you completely. You can redefine addition, break the `if` statement, or delete critical system objects. This isn't a bug—it's a philosophy.

## Conclusion

In Io, "everything is an object" isn't marketing—it's a fundamental truth that shapes every aspect of the language. Numbers, strings, booleans, nil, methods, operators, control structures, and even messages themselves are all objects with slots that can be inspected, modified, and extended.

This uniformity eliminates special cases, enables powerful metaprogramming, and provides a conceptually simple (if initially mind-bending) programming model. Once you internalize that *everything* is just objects sending messages to other objects, Io's entire design clicks into place.

Next, we'll explore how objects relate to each other through Io's prototype-based inheritance system—a world without classes.

---

*Next: [Chapter 4 - Prototypes, Not Classes](04-prototypes-not-classes.md)*