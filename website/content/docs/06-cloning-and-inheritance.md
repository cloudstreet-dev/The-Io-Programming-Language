---
title: "Cloning and Inheritance"
weight: 70
---



# Chapter 6: Cloning and Inheritance

In class-based languages, inheritance is a relationship between classes. In Io's prototype-based world, inheritance emerges from the simpler mechanism of cloning. When you clone an object, the new object maintains a link to its prototype, creating an inheritance chain. This chapter explores how cloning works, how inheritance emerges from it, and how to use these mechanisms effectively.

## The Mechanics of Cloning

When you clone an object in Io, you don't copy all its data. Instead, you create a new, empty object with a reference to the original:

```io
// Create a prototype
Animal := Object clone
Animal species := "Unknown"
Animal age := 0
Animal describe := method(
    ("A " .. age .. " year old " .. species) println
)

// Clone it
cat := Animal clone

// cat is empty but linked to Animal
cat slotNames println        // list() - no local slots!
cat species println          // "Unknown" - from Animal
cat age println             // 0 - from Animal

// The link is through 'proto'
cat proto == Animal println  // true
```

This is fundamentally different from copying:

```io
// If cloning was copying (it's not!), it would work like:
catCopy := Object clone
catCopy species := Animal species  // Copy each slot
catCopy age := Animal age
catCopy describe := Animal describe

// But cloning actually creates a link:
catClone := Animal clone  // Empty object linked to Animal
```

## Differential Inheritance in Action

Objects only store their differences from their prototypes:

```io
Vehicle := Object clone
Vehicle speed := 60
Vehicle color := "white"
Vehicle drive := method(
    ("Driving at " .. speed .. " mph") println
)

car := Vehicle clone
car color = "red"  // Override color
car model := "Sedan"  // Add new slot

// Inspect what's stored where
car slotNames println          // list(color, model) - only differences!
Vehicle slotNames println      // list(speed, color, drive)

// But car can access everything
car speed println              // 60 - from Vehicle
car color println              // "red" - from car (overrides Vehicle)
car model println              // "Sedan" - from car
car drive                      // "Driving at 60 mph"
```

Memory efficiency comparison:

```io
// Creating 1000 cars
cars := list()
1000 times(i,
    car := Vehicle clone
    car id := i
    cars append(car)
)

// Each car only stores its 'id' slot
// All share Vehicle's methods and default values
// In a copying system, each would duplicate everything
```

## The Prototype Chain

Objects can have chains of prototypes:

```io
Organism := Object clone
Organism alive := true
Organism metabolize := method("Converting energy..." println)

Animal := Organism clone
Animal mobile := true
Animal move := method("Moving..." println)

Mammal := Animal clone
Mammal warmBlooded := true
Mammal nurse := method("Nursing young..." println)

Dog := Mammal clone
Dog loyal := true
Dog bark := method("Woof!" println)

fido := Dog clone
fido name := "Fido"

// fido can access methods from the entire chain
fido metabolize  // From Organism
fido move        // From Animal
fido nurse       // From Mammal
fido bark        // From Dog

// Trace the chain
obj := fido
while(obj != Object,
    obj type println
    obj = obj proto
)
// Dog
// Mammal
// Animal
// Organism
// Object
```

## Method Resolution Order

When you send a message, Io searches up the prototype chain:

```io
A := Object clone
A foo := method("A's foo" println)
A bar := method("A's bar" println)

B := A clone
B foo := method("B's foo" println)  // Override

C := B clone
C bar := method("C's bar" println)  // Override different method

obj := C clone

obj foo  // "B's foo" - found in B (C doesn't have it)
obj bar  // "C's bar" - found in C
obj baz  // Exception - not found anywhere
```

You can visualize the search:

```io
Object findSlot := method(slotName,
    obj := self
    while(obj,
        if(obj hasLocalSlot(slotName),
            ("Found '" .. slotName .. "' in " .. obj type) println
            return obj getSlot(slotName)
        )
        obj = obj proto
    )
    "Not found" println
)

obj findSlot("foo")  // Found 'foo' in B
obj findSlot("bar")  // Found 'bar' in C
```

## Multiple Inheritance

Io supports multiple inheritance through the `protos` list:

```io
// Define capabilities
Flyable := Object clone
Flyable altitude := 0
Flyable fly := method(height,
    altitude = height
    ("Flying at " .. altitude .. " feet") println
)

Swimmable := Object clone
Swimmable depth := 0
Swimmable swim := method(d,
    depth = d
    ("Swimming at " .. depth .. " feet deep") println
)

// Single inheritance
Bird := Flyable clone
Bird chirp := method("Chirp!" println)

// Multiple inheritance
Duck := Object clone
Duck appendProto(Flyable)
Duck appendProto(Swimmable)
Duck quack := method("Quack!" println)

mallard := Duck clone
mallard fly(100)    // Flying at 100 feet
mallard swim(5)     // Swimming at 5 feet deep
mallard quack       // Quack!

// Check the prototype list
Duck protos println  // list(Object_0x..., Flyable_0x..., Swimmable_0x...)
```

## Diamond Problem Resolution

The diamond problem occurs when multiple inheritance paths lead to the same ancestor:

```io
// Diamond structure
Grandparent := Object clone
Grandparent value := "from grandparent"
Grandparent method1 := method("Grandparent method1" println)

Parent1 := Grandparent clone
Parent1 method1 := method("Parent1 method1" println)
Parent1 method2 := method("Parent1 method2" println)

Parent2 := Grandparent clone
Parent2 method1 := method("Parent2 method1" println)
Parent2 method3 := method("Parent2 method3" println)

Child := Object clone
Child appendProto(Parent1)
Child appendProto(Parent2)

// Resolution order matters
Child method1  // "Parent1 method1" - Parent1 comes first

// Reorder to change priority
Child protos := list(Parent2, Parent1)
Child method1  // "Parent2 method1" - Parent2 now comes first
```

## Shallow vs Deep Cloning

By default, cloning is shallow—slot values are shared:

```io
Original := Object clone
Original data := list(1, 2, 3)
Original info := Map clone atPut("key", "value")

Shallow := Original clone

// Modifying mutable objects affects both
Shallow data append(4)
Original data println  // list(1, 2, 3, 4) - changed!

// Need deep cloning for independence
Object deepClone := method(
    new := self clone
    self slotNames foreach(name,
        value := self getSlot(name)
        if(value hasSlot("clone"),
            new setSlot(name, value clone)
        )
    )
    new
)

Deep := Original deepClone
Deep data append(5)
Original data println  // list(1, 2, 3, 4) - unchanged
Deep data println      // list(1, 2, 3, 4, 5)
```

## init Methods and Constructors

While Io doesn't have constructors, you can create initialization patterns:

```io
Person := Object clone
Person init := method(
    self name := "Unknown"
    self age := 0
    self contacts := list()  // Important: new list for each instance
    self  // Return self for chaining
)

// Override clone to call init
Person clone := method(
    resend init
)

// Now each person gets their own contacts list
alice := Person clone
alice name = "Alice"
alice contacts append("Bob")

bob := Person clone
bob name = "Bob"
bob contacts append("Charlie")

alice contacts println  // list("Bob") - independent!
bob contacts println    // list("Charlie")
```

## Factory Methods

Create specialized cloning methods:

```io
Animal := Object clone
Animal species := "Unknown"
Animal sound := "..."

Animal withSpecies := method(s,
    new := self clone
    new species = s
    new
)

Animal dog := method(
    self clone species = "Dog" sound = "Woof"
)

Animal cat := method(
    self clone species = "Cat" sound = "Meow"
)

// Usage
myDog := Animal dog
myCat := Animal cat
genericAnimal := Animal withSpecies("Elephant")
```

## Prototype Switching

Unlike class-based languages, you can change an object's prototype at runtime:

```io
// Start with one prototype
Bird := Object clone
Bird fly := method("Flying..." println)

Fish := Object clone
Fish swim := method("Swimming..." println)

creature := Bird clone
creature fly  // "Flying..."

// Change its prototype!
creature protos = list(Fish)
creature swim  // "Swimming..."
creature fly   // Exception - no longer a Bird!

// Or add capabilities
creature appendProto(Bird)
creature fly   // "Flying..." - now it can do both
creature swim  // "Swimming..."
```

## Mixins and Traits

Use prototypes as mixins for composable behavior:

```io
// Define mixins
Comparable := Object clone
Comparable < := method(other, self compare(other) < 0)
Comparable > := method(other, self compare(other) > 0)
Comparable == := method(other, self compare(other) == 0)
Comparable <= := method(other, self compare(other) <= 0)
Comparable >= := method(other, self compare(other) >= 0)

Enumerable := Object clone
Enumerable select := method(block,
    result := list()
    self foreach(item,
        if(block call(item), result append(item))
    )
    result
)
Enumerable map := method(block,
    result := list()
    self foreach(item,
        result append(block call(item))
    )
    result
)

// Use mixins
SortedList := List clone
SortedList appendProto(Comparable)
SortedList appendProto(Enumerable)
SortedList compare := method(other,
    self size compare(other size)
)

list1 := SortedList clone append(1, 2, 3)
list2 := SortedList clone append(4, 5)
(list1 > list2) println  // true (3 > 2)
```

## Clone Hooks

Customize cloning behavior:

```io
Counted := Object clone
Counted instances := 0

Counted clone := method(
    Counted instances = Counted instances + 1
    new := resend
    new id := Counted instances
    new
)

// Each clone gets a unique ID
obj1 := Counted clone
obj2 := Counted clone
obj3 := Counted clone

obj1 id println  // 1
obj2 id println  // 2
obj3 id println  // 3
Counted instances println  // 3
```

## Inheritance Patterns

### Classical Inheritance Pattern

Emulate class-based inheritance:

```io
// Base "class"
Class := Object clone
Class new := method(
    instance := self clone
    instance init
    instance
)

// Define a "class"
Rectangle := Class clone
Rectangle init := method(
    self width := 0
    self height := 0
)
Rectangle area := method(width * height)

// Inheritance
Square := Rectangle clone
Square init := method(
    resend  // Call parent init
    self side := 0
)
Square setSide := method(s,
    side = s
    width = s
    height = s
)

// Usage
rect := Rectangle new
rect width = 10
rect height = 20
rect area println  // 200

square := Square new
square setSide(5)
square area println  // 25
```

### Delegation Pattern

```io
Delegator := Object clone
Delegator delegate := nil
Delegator forward := method(
    if(delegate,
        delegate doMessage(call message, call sender)
    ,
        Exception raise("No delegate set")
    )
)

Logger := Object clone
Logger log := method(msg, ("[LOG] " .. msg) println)

obj := Delegator clone
obj delegate = Logger
obj log("Hello")  // [LOG] Hello
```

## Testing Inheritance

Check inheritance relationships:

```io
Object isKindOf := method(proto,
    obj := self
    while(obj,
        if(obj == proto, return true)
        if(obj protos,
            obj protos foreach(p,
                if(p isKindOf(proto), return true)
            )
        )
        obj = obj proto
    )
    false
)

Animal := Object clone
Dog := Animal clone
fido := Dog clone

fido isKindOf(Dog) println     // true
fido isKindOf(Animal) println  // true
fido isKindOf(Object) println  // true
fido isKindOf(Number) println  // false
```

## Performance Considerations

Prototype chains affect performance:

```io
// Deep chain - slower lookup
A := Object clone
B := A clone
C := B clone
D := C clone
E := D clone
obj := E clone
obj method := method("Found!")

// Shallow chain - faster lookup
Flat := Object clone
Flat method := method("Found!")
obj2 := Flat clone

// Benchmark
time(100000 times(obj method))   // Slower
time(100000 times(obj2 method))  // Faster
```

## Common Pitfalls

### Shared Mutable State

```io
// WRONG - shares list between instances
BadTemplate := Object clone
BadTemplate items := list()

obj1 := BadTemplate clone
obj2 := BadTemplate clone
obj1 items append(1)
obj2 items println  // list(1) - Oops! Shared!

// RIGHT - create new list for each instance
GoodTemplate := Object clone
GoodTemplate init := method(
    self items := list()
    self
)
GoodTemplate clone := method(resend init)
```

### Circular Prototypes

```io
// Don't do this!
A := Object clone
B := Object clone
A appendProto(B)
B appendProto(A)  // Circular!

// A foo  // Infinite loop!
```

## Exercises

1. **Instance Counter**: Create a prototype that tracks how many objects have been cloned from it, directly or indirectly.

2. **Prototype Inspector**: Write a method that visualizes an object's complete prototype hierarchy as a tree.

3. **Deep Clone**: Implement a robust deep cloning method that handles circular references.

4. **Multiple Inheritance Resolver**: Create a system that detects and reports conflicts in multiple inheritance.

5. **Class Emulator**: Build a complete class-based OOP system on top of Io's prototypes, including abstract classes and interfaces.

## Real-World Example: Game Entity System

```io
// Base entity
Entity := Object clone
Entity init := method(
    self x := 0
    self y := 0
    self health := 100
    self
)
Entity clone := method(resend init)
Entity takeDamage := method(amount,
    health = health - amount
    if(health <= 0, self die)
)
Entity die := method("Entity died" println)

// Moveable capability
Moveable := Object clone
Moveable speed := 1
Moveable moveTo := method(newX, newY,
    x = newX
    y = newY
)

// Attacker capability
Attacker := Object clone
Attacker damage := 10
Attacker attack := method(target,
    target takeDamage(damage)
)

// Compose entities
Player := Entity clone
Player appendProto(Moveable)
Player appendProto(Attacker)
Player speed = 5
Player damage = 20

Enemy := Entity clone
Enemy appendProto(Moveable)
Enemy appendProto(Attacker)
Enemy speed = 3
Enemy damage = 15

// Static entity
Turret := Entity clone
Turret appendProto(Attacker)
Turret damage = 25

// Usage
player := Player clone
enemy := Enemy clone
turret := Turret clone

player moveTo(10, 10)
player attack(enemy)
turret attack(player)
```

## Conclusion

Cloning and inheritance in Io demonstrate how complex behavior can emerge from simple mechanisms. Instead of classes, instances, and inheritance hierarchies defined at compile time, you have objects cloning objects, maintaining prototype links, and delegating message handling up the chain.

This flexibility enables patterns impossible in class-based languages: changing inheritance at runtime, mixing in capabilities dynamically, and treating "classes" as first-class objects that can be modified like any other. The trade-off is that you must be more careful about shared state and initialization, but the power and expressiveness gained often make it worthwhile.

Understanding cloning and inheritance deeply is essential for effective Io programming. These mechanisms aren't just how you create objects—they're how you structure entire programs.

---

