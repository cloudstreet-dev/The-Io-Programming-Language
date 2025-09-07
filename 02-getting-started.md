# Chapter 2: Getting Started with Io

The best way to understand Io is to use it. In this chapter, we'll install Io, explore its REPL (Read-Eval-Print Loop), and write our first programs. By the end, you'll have a feel for Io's syntax and flow.

## Installing Io

### macOS

If you're on macOS with Homebrew, installation is simple:

```bash
brew install io
```

### Linux

On most Linux distributions, you'll need to build from source:

```bash
git clone https://github.com/IoLanguage/io.git
cd io
mkdir build
cd build
cmake ..
make
sudo make install
```

### Windows

Windows users should use WSL (Windows Subsystem for Linux) and follow the Linux instructions, or use Docker:

```bash
docker run -it --rm stevedekorte/io
```

### Verifying Installation

Once installed, verify Io is working:

```bash
$ io --version
Io Programming Language, v. 20170906

$ io
Io> "Hello, World!" println
Hello, World!
==> Hello, World!
Io> ^C
```

## The REPL: Your Io Playground

Io's REPL is where you'll spend most of your learning time. Unlike compiled languages where you write, compile, and run, Io lets you experiment immediately.

Start the REPL by typing `io`:

```io
$ io
Io>
```

The prompt `Io>` indicates Io is ready for input. Let's explore:

```io
Io> 2 + 2
==> 4

Io> "Hello" .. " " .. "World"
==> Hello World

Io> 10 > 5
==> true
```

Notice the `==>` prefix? That shows the return value of your expression. Everything in Io returns a value.

### REPL Tips

1. **Multi-line input**: The REPL detects incomplete expressions:

```io
Io> if(true,
...     "yes" println,
...     "no" println
... )
yes
==> yes
```

2. **Previous result**: Use `_` to reference the last result:

```io
Io> 100 * 2
==> 200
Io> _ + 50
==> 250
```

3. **Getting help**: The REPL has built-in documentation:

```io
Io> Lobby slotNames
==> list(Protos, _, exit, forward, set_)

Io> Number slotNames sort
==> list(%, *, +, -, /, <, <=, ==, >, >=, abs, acos, asin, atan, between, ceil, cos, ...)
```

## Your First Io Program

Let's write the traditional "Hello, World!" program. Create a file called `hello.io`:

```io
"Hello, World!" println
```

Run it:

```bash
$ io hello.io
Hello, World!
```

That's it. No class definitions, no main function, no boilerplate. Compare with Java:

```java
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

Or even Python:

```python
if __name__ == "__main__":
    print("Hello, World!")
```

Io just runs your code.

## Understanding Basic Syntax

Io's syntax is minimal. Let's explore the basics:

### Messages and Receivers

In Io, everything is about sending messages to objects:

```io
"hello" size         // Send 'size' message to "hello"
==> 5

"hello" at(0)        // Send 'at' message with argument 0
==> h

"hello" upper        // Send 'upper' message
==> HELLO
```

Compare with method calls in Python:

```python
"hello".upper()      # Python
```

```io
"hello" upper        // Io - parentheses optional for no arguments
```

### Arguments

Messages can have arguments, passed in parentheses:

```io
"hello" at(1)                    // One argument
==> e

"hello" slice(1, 3)              // Two arguments
==> el

List append(1, 2, 3)            // Multiple arguments
==> list(1, 2, 3)
```

### Operators are Messages

This is crucial: operators in Io are just messages with special precedence:

```io
2 + 3          // Send message "+" to 2 with argument 3
2 +(3)         // Exactly the same thing
2 send("+", 3) // Still the same thing!
```

This uniformity means you can redefine operators:

```io
Number + := method(n, self - n)  // Redefine + to subtract!
5 + 3
==> 2
```

(Don't actually do this in real code!)

## Variables and Assignment

In Io, variables are just slots on objects. By default, you're working with the `Lobby` object:

```io
x := 10        // Create slot 'x' on Lobby with value 10
x println      // Print it
==> 10

x = 20         // Update existing slot
x println
==> 20

y = 30         // Error! Slot doesn't exist
// Exception: Slot y not found
```

Note the distinction:
- `:=` creates a new slot
- `=` updates an existing slot

This prevents accidental variable creation from typos:

```io
counter := 0
countr = 1     // Error - probably a typo!
```

Compare with JavaScript's similar issue:

```javascript
let counter = 0;
countr = 1;    // Creates global variable - probably a bug!
```

## Control Flow

Io's control structures are methods, not special syntax:

### If Statements

```io
if(10 > 5,
    "Yes" println,
    "No" println
)
// Prints: Yes
```

Compare with Python:

```python
if 10 > 5:
    print("Yes")
else:
    print("No")
```

Since `if` is a method, you can even look at its implementation:

```io
Io> if
==> method(...)
```

### Loops

```io
// While loop
i := 0
while(i < 5,
    i println
    i = i + 1
)

// For loop
for(i, 0, 4,
    i println
)

// Times loop
5 times(i,
    i println
)
```

## Creating Objects

Let's create our first custom object:

```io
Person := Object clone
Person name := "Unknown"
Person greet := method(
    ("Hello, I'm " .. name) println
)

alice := Person clone
alice name = "Alice"
alice greet
// Prints: Hello, I'm Alice
```

Compare with Python:

```python
class Person:
    def __init__(self):
        self.name = "Unknown"
    
    def greet(self):
        print(f"Hello, I'm {self.name}")

alice = Person()
alice.name = "Alice"
alice.greet()
```

The key difference: Io has no class definition. `Person` is just an object we're using as a prototype.

## Methods

Methods in Io are created with the `method` function:

```io
Calculator := Object clone
Calculator add := method(a, b, a + b)
Calculator multiply := method(a, b, a * b)

calc := Calculator clone
calc add(5, 3) println        // 8
calc multiply(4, 7) println    // 28
```

Methods have access to `self` (the receiver):

```io
Counter := Object clone
Counter count := 0
Counter increment := method(
    count = count + 1
    self            // Return self for chaining
)

c := Counter clone
c increment increment increment
c count println    // 3
```

## Lists and Iteration

Lists are fundamental in Io:

```io
numbers := list(1, 2, 3, 4, 5)

// Iteration
numbers foreach(n,
    n println
)

// Map
squared := numbers map(n, n * n)
squared println    // list(1, 4, 9, 16, 25)

// Select (filter)
evens := numbers select(n, n % 2 == 0)
evens println      // list(2, 4)

// Reduce
sum := numbers reduce(+)
sum println        // 15
```

Compare with Python:

```python
numbers = [1, 2, 3, 4, 5]

# Iteration
for n in numbers:
    print(n)

# Map
squared = [n * n for n in numbers]

# Filter
evens = [n for n in numbers if n % 2 == 0]

# Reduce
from functools import reduce
sum = reduce(lambda a, b: a + b, numbers)
```

## Working with Files

Reading and writing files is straightforward:

```io
// Write to file
file := File with("test.txt")
file openForWriting
file write("Hello, file!")
file close

// Read from file
file := File with("test.txt")
file openForReading
contents := file contents
contents println
file close

// Or more concisely
File with("test.txt") contents println
```

## A More Complete Example

Let's build something more substantial—a simple to-do list:

```io
// todo.io - A simple to-do list manager

TodoList := Object clone
TodoList items := list()

TodoList add := method(task,
    items append(task)
    self
)

TodoList show := method(
    if(items size == 0,
        "No tasks!" println,
        items foreach(i, task,
            ("  " .. (i + 1) .. ". " .. task) println
        )
    )
    self
)

TodoList complete := method(index,
    if(index > 0 and index <= items size,
        task := items at(index - 1)
        items removeAt(index - 1)
        ("Completed: " .. task) println,
        "Invalid task number" println
    )
    self
)

TodoList save := method(filename,
    File with(filename) openForWriting write(items asJson) close
    "Saved!" println
    self
)

TodoList load := method(filename,
    if(File with(filename) exists,
        items = Yajl parseJson(File with(filename) contents)
        "Loaded!" println,
        "File not found" println
    )
    self
)

// Usage
todo := TodoList clone
todo add("Learn Io") add("Build something cool") add("Share with friends")
todo show
//   1. Learn Io
//   2. Build something cool  
//   3. Share with friends

todo complete(1)
// Completed: Learn Io

todo show
//   1. Build something cool
//   2. Share with friends
```

## Key Takeaways

Having written your first Io programs, you've probably noticed:

1. **Minimal syntax**: No keywords for defining classes, functions, or variables. Everything uses the same message-passing syntax.

2. **Immediate feedback**: The REPL makes experimentation effortless.

3. **Uniform model**: Whether you're doing arithmetic, defining methods, or creating objects, it's all message passing.

4. **Flexibility**: You can modify anything, even built-in types and operators.

5. **Simplicity**: Programs are often shorter than their equivalents in other languages.

## Exercises

Try these exercises to solidify your understanding:

1. **Number methods**: Add a `squared` method to `Number` that returns the square of a number. Test it with `5 squared`.

2. **String reversal**: Create a method on `Sequence` (Io's string type) called `reverse` that returns the reversed string.

3. **Bank account**: Create a `BankAccount` object with `balance`, `deposit`, and `withdraw` methods. Include protection against negative balances.

4. **FizzBuzz**: Implement FizzBuzz in Io (print numbers 1-100, but "Fizz" for multiples of 3, "Buzz" for multiples of 5, "FizzBuzz" for both).

5. **Method chaining**: Create a `StringBuilder` object that allows chaining: `StringBuilder clone add("Hello") add(" ") add("World") toString`

## What's Different?

If you're coming from mainstream languages, here's what might feel strange:

- **No compile step**: Your code runs immediately
- **No type declarations**: Everything is dynamically typed
- **No class keyword**: Objects are created by cloning
- **Operators aren't special**: They're just messages
- **Everything returns a value**: Even assignments and control structures

These differences aren't arbitrary—they all flow from Io's core principle of uniform message passing.

## Moving Forward

You now have enough Io knowledge to explore the deeper concepts. You can:

- Create and manipulate objects
- Define methods
- Use control structures
- Work with collections
- Read and write files

In the next chapter, we'll dive deep into Io's object model and understand what "everything is an object" really means.

---

*Next: [Chapter 3 - Everything is an Object](03-everything-is-an-object.md)*