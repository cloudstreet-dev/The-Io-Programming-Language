---
title: "Collections"
weight: 90
---



# Chapter 8: Collections

Collections are fundamental to any programming language. Io provides three main collection types: List (ordered, indexed), Map (key-value pairs), and Sequence (strings). This chapter explores these collections, their methods, and how to create custom collection types.

## Lists: Ordered Collections

Lists in Io are dynamic arrays that can hold any type of object:

```io
// Creating lists
empty := list()
numbers := list(1, 2, 3, 4, 5)
mixed := list("hello", 42, true, Object clone)

// Lists are objects
numbers type println  // List

// Basic operations
numbers size println      // 5
numbers isEmpty println   // false
numbers first println     // 1
numbers last println      // 5
numbers at(2) println     // 3 (zero-indexed)
```

### List Manipulation

```io
fruits := list("apple", "banana")

// Adding elements
fruits append("orange")
fruits prepend("grape")
fruits println  // list(grape, apple, banana, orange)

// Insert at position
fruits atInsert(2, "mango")
fruits println  // list(grape, apple, mango, banana, orange)

// Removing elements
fruits remove("mango")
fruits removeAt(0)
fruits pop  // Removes and returns last element
fruits println  // list(apple, banana)

// Multiple operations
fruits appendSeq(list("kiwi", "peach"))
fruits println  // list(apple, banana, kiwi, peach)
```

### List Iteration

```io
numbers := list(1, 2, 3, 4, 5)

// Basic iteration
numbers foreach(n,
    n println
)

// With index
numbers foreach(i, n,
    (i .. ": " .. n) println
)

// Reverse iteration
numbers reverseForEach(n,
    n println
)
```

### Functional Operations

```io
numbers := list(1, 2, 3, 4, 5)

// Map: transform each element
squared := numbers map(x, x * x)
squared println  // list(1, 4, 9, 16, 25)

// Select: filter elements
evens := numbers select(x, x % 2 == 0)
evens println  // list(2, 4)

// Reject: inverse of select
odds := numbers reject(x, x % 2 == 0)
odds println  // list(1, 3, 5)

// Detect: find first match
firstEven := numbers detect(x, x % 2 == 0)
firstEven println  // 2

// Reduce: aggregate
sum := numbers reduce(+)
sum println  // 15

// Custom reduce
product := numbers reduce(a, b, a * b)
product println  // 120

// Any/all predicates
numbers contains(3) println  // true
numbers containsAll(list(2, 4)) println  // true
numbers containsAny(list(10, 3)) println  // true
```

### List Slicing and Manipulation

```io
letters := list("a", "b", "c", "d", "e")

// Slicing
letters slice(1, 3) println  // list(b, c, d)
letters slice(2) println     // list(c, d, e)

// Copying
copy := letters copy
copy atPut(0, "z")
letters println  // list(a, b, c, d, e) - unchanged
copy println     // list(z, b, c, d, e)

// Sorting
numbers := list(3, 1, 4, 1, 5, 9)
numbers sort println  // list(1, 1, 3, 4, 5, 9)

// Custom sort
people := list(
    Object clone do(name := "Alice"; age := 30),
    Object clone do(name := "Bob"; age := 25),
    Object clone do(name := "Charlie"; age := 35)
)

people sortBy(block(p, p age)) foreach(p,
    (p name .. ": " .. p age) println
)
// Bob: 25
// Alice: 30
// Charlie: 35
```

## Maps: Key-Value Stores

Maps (also called dictionaries or hash tables) store key-value pairs:

```io
// Creating maps
empty := Map clone
person := Map clone atPut("name", "Alice") atPut("age", 30)

// Alternative creation
person := Map with(
    "name", "Alice",
    "age", 30,
    "city", "New York"
)

// Accessing values
person at("name") println     // Alice
person at("missing") println  // nil
person at("missing", "default") println  // default

// Setting values
person atPut("age", 31)
person atPut("email", "alice@example.com")

// Checking keys
person hasKey("name") println  // true
person hasKey("phone") println  // false
```

### Map Operations

```io
map := Map with("a", 1, "b", 2, "c", 3)

// Get all keys and values
map keys println    // list(a, b, c)
map values println  // list(1, 2, 3)

// Size and emptiness
map size println      // 3
map isEmpty println   // false

// Removing entries
map removeAt("b")
map println  // Map_0x...: a=1, c=3

// Iteration
map foreach(key, value,
    (key .. " => " .. value) println
)

// Merging maps
other := Map with("c", 30, "d", 4)
map merge(other)
map println  // a=1, c=30, d=4 (note c was overwritten)
```

### Maps as Objects

Maps can act like objects with dynamic properties:

```io
// Create object-like map
obj := Map clone
obj atPut("greet", method(name,
    ("Hello, " .. name .. "!") println
))
obj atPut("x", 10)
obj atPut("y", 20)

// Use like object (sort of)
obj at("greet") call("World")  // Hello, World!
obj at("x") println  // 10
```

## Sequences: String Handling

Sequences are Io's strings, but they're mutable and act like byte arrays:

```io
text := "Hello, World!"

// Basic operations
text size println          // 13
text at(0) println        // 72 (ASCII 'H')
text at(0) asCharacter println  // H

// Slicing
text slice(0, 5) println   // Hello
text slice(7) println      // World!

// Searching
text findSeq("World") println  // 7 (index)
text containsSeq("Hello") println  // true
text beginsWithSeq("Hello") println  // true
text endsWithSeq("!") println  // true
```

### String Manipulation

```io
text := "  Hello, World!  "

// Trimming
text strip println         // "Hello, World!"
text lstrip println        // "Hello, World!  "
text rstrip println        // "  Hello, World!"

// Case conversion
"hello" upper println      // HELLO
"WORLD" lower println      // world
"hello world" asCapitalized println  // Hello world

// Replacement
"hello world" replaceSeq("world", "Io") println  // hello Io
"abcabc" replaceFirstSeq("a", "X") println  // Xbcabc

// Splitting and joining
words := "apple,banana,orange" split(",")
words println  // list(apple, banana, orange)

words join("-") println  // apple-banana-orange
```

### String Building

```io
// Inefficient string concatenation
result := ""
for(i, 1, 1000,
    result = result .. i .. ", "
)

// Better: use a list
parts := list()
for(i, 1, 1000,
    parts append(i)
)
result := parts join(", ")

// Or use Sequence's mutable nature
seq := Sequence clone
for(i, 1, 100,
    seq appendSeq(i asString) appendSeq(", ")
)
```

### Regular Expressions

Io has built-in regex support:

```io
text := "The year 2024 has 365 days"

// Find matches
text findRegex("\\d+") println  // MatchResult...
text allMatchesOfRegex("\\d+") foreach(match,
    match println  // 2024, 365
)

// Replace with regex
text replaceAllRegex("\\d+", "N") println  // The year N has N days

// Capture groups
email := "user@example.com"
match := email matchesOfRegex("(\\w+)@(\\w+\\.\\w+)") 
if(match,
    match at(1) println  // user
    match at(2) println  // example.com
)
```

## Creating Custom Collections

### Stack Implementation

```io
Stack := List clone
Stack push := method(item,
    self append(item)
)

Stack pop := method(
    if(size > 0,
        removeAt(size - 1),
        nil
    )
)

Stack peek := method(
    if(size > 0,
        at(size - 1),
        nil
    )
)

// Usage
stack := Stack clone
stack push(1) push(2) push(3)
stack pop println   // 3
stack peek println  // 2
stack pop println   // 2
stack pop println   // 1
```

### Queue Implementation

```io
Queue := Object clone
Queue init := method(
    self items := list()
    self
)

Queue enqueue := method(item,
    items append(item)
    self
)

Queue dequeue := method(
    if(items size > 0,
        items removeAt(0),
        nil
    )
)

Queue isEmpty := method(items isEmpty)
Queue size := method(items size)

// Usage
queue := Queue clone init
queue enqueue("a") enqueue("b") enqueue("c")
queue dequeue println  // a
queue dequeue println  // b
queue size println     // 1
```

### Set Implementation

```io
Set := Object clone
Set init := method(
    self items := Map clone
    self
)

Set add := method(item,
    items atPut(item asString, item)
    self
)

Set remove := method(item,
    items removeAt(item asString)
    self
)

Set contains := method(item,
    items hasKey(item asString)
)

Set union := method(other,
    result := Set clone init
    items foreach(k, v, result add(v))
    other items foreach(k, v, result add(v))
    result
)

Set intersection := method(other,
    result := Set clone init
    items foreach(k, v,
        if(other contains(v), result add(v))
    )
    result
)

// Usage
set1 := Set clone init add(1) add(2) add(3)
set2 := Set clone init add(2) add(3) add(4)

set1 contains(2) println  // true
union := set1 union(set2)
intersection := set1 intersection(set2)
```

## Advanced Collection Patterns

### Lazy Evaluation

```io
LazyList := Object clone
LazyList init := method(generator,
    self generator := generator
    self cache := list()
    self
)

LazyList at := method(index,
    while(cache size <= index,
        cache append(generator call(cache size))
    )
    cache at(index)
)

LazyList take := method(n,
    result := list()
    for(i, 0, n - 1,
        result append(self at(i))
    )
    result
)

// Infinite fibonacci sequence
fibGen := LazyList clone init(block(n,
    if(n < 2, n, self at(n - 1) + self at(n - 2))
))

fibGen take(10) println  // list(0, 1, 1, 2, 3, 5, 8, 13, 21, 34)
```

### Collection Pipeline

```io
// Method chaining for data processing
data := list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

result := data select(x, x % 2 == 0) \
    map(x, x * x) \
    select(x, x > 10) \
    reduce(+)

result println  // 120 (16 + 36 + 64)

// Custom pipeline
List pipeline := method(
    Pipeline clone setList(self)
)

Pipeline := Object clone
Pipeline setList := method(list,
    self list := list
    self
)

Pipeline where := method(predicate,
    self list = list select(predicate)
    self
)

Pipeline transform := method(mapper,
    self list = list map(mapper)
    self
)

Pipeline aggregate := method(reducer,
    list reduce(reducer)
)

// Usage
numbers := list(1, 2, 3, 4, 5)
total := numbers pipeline \
    where(x, x % 2 == 0) \
    transform(x, x * x) \
    aggregate(+)

total println  // 20 (4 + 16)
```

### Nested Collections

```io
// Matrix as list of lists
matrix := list(
    list(1, 2, 3),
    list(4, 5, 6),
    list(7, 8, 9)
)

// Access element
matrix at(1) at(2) println  // 6

// Transpose
transpose := method(matrix,
    rows := matrix size
    cols := matrix at(0) size
    result := list()
    
    for(c, 0, cols - 1,
        col := list()
        for(r, 0, rows - 1,
            col append(matrix at(r) at(c))
        )
        result append(col)
    )
    result
)

transpose(matrix) println
// list(list(1, 4, 7), list(2, 5, 8), list(3, 6, 9))
```

## Performance Considerations

```io
// List operations performance
list := List clone

// O(1) operations
list append(item)      // Constant time
list at(index)         // Constant time
list size              // Constant time

// O(n) operations
list indexOf(item)     // Linear search
list contains(item)    // Linear search
list remove(item)      // Linear search + shift

// Map operations are generally O(1)
map := Map clone
map atPut(key, value)  // Constant average
map at(key)            // Constant average
map removeAt(key)      // Constant average

// Choose the right collection for your needs
```

## Collection Serialization

```io
// JSON serialization
list := list(1, 2, 3, Map with("name", "Alice"))
json := list asJson
json println  // [1,2,3,{"name":"Alice"}]

// Deserialize
restored := json parseJson
restored println

// Custom serialization
Collection := Object clone
Collection serialize := method(
    result := list()
    self foreach(item,
        if(item hasSlot("serialize"),
            result append(item serialize),
            result append(item asString)
        )
    )
    result join("|")
)
```

## Common Pitfalls

### Shared References

```io
// PROBLEM: Shared reference
original := list(1, 2, 3)
copy := original  // Not a copy!
copy append(4)
original println  // list(1, 2, 3, 4) - modified!

// SOLUTION: Use copy
original := list(1, 2, 3)
copy := original copy
copy append(4)
original println  // list(1, 2, 3) - unchanged
```

### Iterator Invalidation

```io
// PROBLEM: Modifying while iterating
list := list(1, 2, 3, 4, 5)
list foreach(item,
    if(item % 2 == 0,
        list remove(item)  // Dangerous!
    )
)

// SOLUTION: Use select/reject or iterate on copy
list := list(1, 2, 3, 4, 5)
list = list reject(item, item % 2 == 0)
```

## Exercises

1. **Circular Buffer**: Implement a fixed-size circular buffer that overwrites old elements.

2. **MultiMap**: Create a map that can store multiple values per key.

3. **Sorted List**: Implement a list that maintains sorted order on insertion.

4. **Tree Structure**: Build a tree collection with parent-child relationships.

5. **Graph**: Implement a graph data structure with nodes and edges.

## Real-World Example: Todo List with Tags

```io
TodoItem := Object clone
TodoItem init := method(description,
    self description := description
    self tags := Set clone init
    self completed := false
    self
)

TodoList := Object clone
TodoList init := method(
    self items := list()
    self
)

TodoList add := method(description,
    item := TodoItem clone init(description)
    items append(item)
    item
)

TodoList taggedWith := method(tag,
    items select(item, item tags contains(tag))
)

TodoList pending := method(
    items select(item, item completed not)
)

TodoList complete := method(description,
    item := items detect(i, i description == description)
    if(item, item completed = true)
    self
)

// Usage
todos := TodoList clone init

todos add("Write documentation") tags add("work") add("writing")
todos add("Fix bugs") tags add("work") add("urgent")
todos add("Buy groceries") tags add("personal")

todos taggedWith("urgent") foreach(item,
    item description println
)
// Fix bugs

todos complete("Buy groceries")
todos pending foreach(item,
    item description println
)
// Write documentation
// Fix bugs
```

## Conclusion

Io's collections—List, Map, and Sequence—provide a solid foundation for data manipulation. They're all objects, following Io's uniform object model, and support functional programming patterns like map, select, and reduce.

The real power comes from Io's flexibility: you can add methods to existing collection types, create custom collections that integrate seamlessly, and build sophisticated data structures using simple object composition. Understanding collections deeply is essential for effective Io programming, as they form the backbone of most data processing tasks.

---

