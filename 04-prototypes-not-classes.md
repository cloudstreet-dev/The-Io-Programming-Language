# Chapter 4: Prototypes, Not Classes

Most object-oriented languages use classes as templates or blueprints for creating objects. You define a class, then instantiate objects from it. There's a fundamental distinction between the template (class) and the things created from it (instances).

Io takes a different approach: prototype-based inheritance. There are no classes, only objects. New objects are created by cloning existing objects, and objects can serve as prototypes for other objects. This might seem like a small change, but it fundamentally alters how you think about and structure programs.

## The Class-Based World

Let's start with what you probably know. In a class-based language like Java:

```java
// Define a class (template)
class Animal {
    String name;
    
    void speak() {
        System.out.println("Some sound");
    }
}

// Define a subclass
class Dog extends Animal {
    void speak() {
        System.out.println("Woof!");
    }
}

// Create instances
Dog fido = new Dog();
Dog rover = new Dog();
```

The key points:
- `Animal` and `Dog` are classes (templates)
- `fido` and `rover` are instances (objects)
- Classes and instances are fundamentally different things
- Inheritance happens between classes

## The Prototype-Based World

In Io, there are no classes:

```io
// Create an object to serve as a prototype
Animal := Object clone
Animal speak := method("Some sound" println)

// Create another object using Animal as a prototype
Dog := Animal clone
Dog speak := method("Woof!" println)

// Create more objects using Dog as a prototype
fido := Dog clone
rover := Dog clone
```

The key differences:
- `Animal`, `Dog`, `fido`, and `rover` are all objects
- No fundamental distinction between "classes" and "instances"
- Objects are created by cloning other objects
- Any object can serve as a prototype for other objects

## Understanding Cloning

When you clone an object in Io, you don't copy all its slots. Instead, you create a new, empty object that maintains a reference to its prototype:

```io
Animal := Object clone
Animal name := "Generic Animal"
Animal speak := method(name println)

dog := Animal clone

// dog doesn't have its own 'name' slot
dog hasLocalSlot("name") println    // false

// But it can access 'name' through its prototype
dog name println                     // "Generic Animal"

// Now give dog its own name
dog name = "Fido"
dog hasLocalSlot("name") println    // true
dog name println                     // "Fido"

// Animal's name is unchanged
Animal name println                  // "Generic Animal"
```

This is called **differential inheritance**—objects only store their differences from their prototypes.

## The Prototype Chain

When you send a message to an object, Io looks for a matching slot:
1. First in the object itself
2. Then in its prototype
3. Then in the prototype's prototype
4. And so on until it reaches Object

```io
// Create a chain of prototypes
Organism := Object clone
Organism live := method("Living..." println)

Animal := Organism clone
Animal move := method("Moving..." println)

Dog := Animal clone
Dog bark := method("Woof!" println)

fido := Dog clone
fido name := "Fido"

// fido can access methods from anywhere in the chain
fido live    // "Living..." (from Organism)
fido move    // "Moving..." (from Animal)
fido bark    // "Woof!" (from Dog)

// You can inspect the chain
fido proto == Dog println           // true
fido proto proto == Animal println  // true
fido proto proto proto == Organism println  // true
```

## Dynamic Prototype Modification

Since prototypes are just objects, you can modify them at runtime, and all objects using that prototype see the changes:

```io
Dog := Object clone
fido := Dog clone
rover := Dog clone

// Add a method to Dog
Dog bark := method("Woof!" println)

// Both fido and rover can now bark
fido bark    // "Woof!"
rover bark   // "Woof!"

// Modify the method
Dog bark = method("WOOF! WOOF!" println)

// The change affects all dogs
fido bark    // "WOOF! WOOF!"
rover bark   // "WOOF! WOOF!"
```

Try doing that with classes in Java! You'd need complex reflection APIs, and even then, you couldn't modify existing instances.

## Multiple Prototypes

Io supports multiple inheritance through its `Protos` list:

```io
// Create two prototypes
Flyable := Object clone
Flyable fly := method("Flying..." println)

Swimmable := Object clone
Swimmable swim := method("Swimming..." println)

// Create an object with multiple prototypes
Duck := Object clone
Duck appendProto(Flyable)
Duck appendProto(Swimmable)

mallard := Duck clone
mallard fly     // "Flying..."
mallard swim    // "Swimming..."

// Inspect the prototype list
Duck protos println  // list(Object_0x..., Flyable_0x..., Swimmable_0x...)
```

The search order for slots is depth-first through the `Protos` list.

## Comparing Approaches: Class vs Prototype

Let's implement the same concept in both paradigms to see the differences.

### Class-Based (Python)

```python
class Shape:
    def __init__(self):
        self.x = 0
        self.y = 0
    
    def move(self, dx, dy):
        self.x += dx
        self.y += dy

class Circle(Shape):
    def __init__(self, radius):
        super().__init__()
        self.radius = radius
    
    def area(self):
        return 3.14159 * self.radius ** 2

# Usage
circle = Circle(5)
circle.move(10, 20)
print(circle.area())

# Can't easily create a one-off variation
# Would need to define a new class
```

### Prototype-Based (Io)

```io
Shape := Object clone
Shape x := 0
Shape y := 0
Shape move := method(dx, dy,
    x = x + dx
    y = y + dy
)

Circle := Shape clone
Circle radius := 0
Circle area := method(
    3.14159 * radius * radius
)

// Usage
circle := Circle clone
circle radius = 5
circle move(10, 20)
circle area println

// Easy to create one-off variations
specialCircle := Circle clone
specialCircle area = method(
    "Special area: " print
    resend  // Call the original method
)
specialCircle area  // "Special area: 78.53975"
```

## The Power of Prototypes

### 1. Objects as Classes

In Io, objects can act as classes when needed:

```io
// Person acts like a class
Person := Object clone
Person init := method(
    self name := "Unknown"
    self age := 0
    self
)

Person create := method(n, a,
    clone init name = n age = a
)

// Usage feels class-like
alice := Person create("Alice", 30)
bob := Person create("Bob", 25)
```

### 2. One-Off Objects

You can create unique objects without defining a "class":

```io
// Create a unique object with no "class"
singleton := Object clone
singleton data := Map clone
singleton store := method(key, value,
    data atPut(key, value)
)
singleton retrieve := method(key,
    data at(key)
)

// Use it directly
singleton store("user", "Alice")
singleton retrieve("user") println  // "Alice"
```

### 3. Runtime Class Modification

You can fundamentally change what a "class" does:

```io
Number := Object clone
Number value := 0
Number + := method(n,
    result := Number clone
    result value = self value + n value
    result
)

// Create numbers
five := Number clone value = 5
three := Number clone value = 3

// Now change how Number works
Number + = method(n,
    result := Number clone
    result value = self value * n value  // Multiply instead!
    result
)

// Existing numbers use the new behavior
eight := five + three
eight value println  // 15 (multiplication!)
```

## Delegation vs Inheritance

Prototype-based languages use delegation rather than inheritance. When an object doesn't have a slot, it delegates to its prototype:

```io
Account := Object clone
Account balance := 0
Account deposit := method(amount,
    balance = balance + amount
    self
)

savings := Account clone
savings deposit(100)

// Let's trace what happens:
// 1. savings receives 'deposit' message
// 2. savings doesn't have 'deposit' slot
// 3. savings delegates to Account
// 4. Account's deposit method runs
// 5. But 'self' is still savings
// 6. So savings's balance is updated

savings balance println    // 100
Account balance println    // 0 (unchanged)
```

This is subtly different from class-based inheritance where methods are copied or looked up in a class hierarchy.

## Practical Patterns

### The Constructor Pattern

While Io doesn't have constructors, you can create them:

```io
Person := Object clone
Person init := method(name, age,
    self name := name
    self age := age
    self
)

Person new := method(name, age,
    self clone init(name, age)
)

// Usage
alice := Person new("Alice", 30)
```

### The Mixin Pattern

Use prototypes as mixins for shared behavior:

```io
// Define mixins
Timestamped := Object clone
Timestamped createdAt := Date now
Timestamped age := method(
    Date now - createdAt
)

Serializable := Object clone
Serializable toJson := method(
    // Implementation
)

// Use mixins
Document := Object clone
Document appendProto(Timestamped)
Document appendProto(Serializable)

doc := Document clone
doc age println
doc toJson
```

### The Factory Pattern

Objects can create other objects with specific configurations:

```io
ShapeFactory := Object clone
ShapeFactory circle := method(radius,
    c := Object clone
    c radius := radius
    c area := method(3.14159 * radius * radius)
    c
)

ShapeFactory rectangle := method(width, height,
    r := Object clone
    r width := width
    r height := height
    r area := method(width * height)
    r
)

// Usage
myCircle := ShapeFactory circle(5)
myRect := ShapeFactory rectangle(10, 20)
```

## JavaScript: A Familiar Prototype System

If you know JavaScript, you've already used prototype-based programming:

```javascript
// JavaScript (before ES6 classes)
function Animal(name) {
    this.name = name;
}

Animal.prototype.speak = function() {
    console.log("Some sound");
};

function Dog(name) {
    Animal.call(this, name);
}

Dog.prototype = Object.create(Animal.prototype);
Dog.prototype.bark = function() {
    console.log("Woof!");
};
```

But JavaScript complicated things with constructor functions and later added class syntax as sugar. Io keeps prototypes pure and simple.

## Common Misconceptions

### "No Classes Means No Structure"

False. You can create well-structured programs with prototypes:

```io
// Define clear prototype hierarchies
Vehicle := Object clone
Vehicle speed := 0

Car := Vehicle clone
Car wheels := 4

ElectricCar := Car clone
ElectricCar batteryLevel := 100

// The structure is clear and maintainable
```

### "Prototypes Are Just Classes With Different Syntax"

False. Prototypes are more flexible:

```io
// Start with a prototype
Dog := Object clone
Dog bark := method("Woof!" println)

fido := Dog clone

// Later, change fido's prototype!
Cat := Object clone
Cat meow := method("Meow!" println)

fido protos = list(Cat)
fido meow  // "Meow!" - fido is now a cat!
```

You can't change an object's class at runtime in most class-based languages.

### "Multiple Inheritance Is Always Confusing"

Io's prototype lists make multiple inheritance explicit and controllable:

```io
A := Object clone
A foo := method("A's foo" println)

B := Object clone  
B foo := method("B's foo" println)

C := Object clone
C appendProto(A)
C appendProto(B)

C foo  // "A's foo" (A comes first in the list)

// Reorder to change priority
C protos = list(B, A)
C foo  // "B's foo" (B now comes first)
```

## Exercises

1. **Prototype Chain Explorer**: Write a method that prints an object's complete prototype chain with indentation showing the hierarchy.

2. **Class Emulator**: Create a `Class` object that provides `new`, `extends`, and other class-like conveniences while using prototypes underneath.

3. **Multiple Inheritance Diamond**: Create a diamond inheritance pattern (D inherits from B and C, which both inherit from A) and explore how Io resolves method conflicts.

4. **Dynamic Reclassing**: Write a `become` method that changes an object's prototype chain to make it "become" an instance of a different prototype.

5. **Prototype Versioning**: Implement a system where objects can "lock" to a specific version of their prototype, unaffected by later prototype modifications.

## Real-World Implications

Prototype-based programming shines in certain scenarios:

1. **Rapid Prototyping**: Create and modify objects on the fly without defining classes
2. **Dynamic Systems**: Systems where object behavior needs to change at runtime
3. **DSLs**: Domain-specific languages where objects morph based on context
4. **Learning**: Understanding prototypes deepens your understanding of JavaScript
5. **Simplicity**: No distinction between classes and objects means fewer concepts

## Conclusion

Prototype-based programming isn't just "classes with different syntax"—it's a fundamentally different way of thinking about objects and inheritance. Instead of rigid templates (classes) and instances, you have a fluid world where any object can serve as a template for others, where inheritance is delegation, and where the structure of your program can change at runtime.

This flexibility can be overwhelming at first, especially if you're used to the safety of static classes. But it can also be liberating. You're not constrained by decisions made at compile time. You can experiment, evolve, and adapt your objects as your understanding of the problem grows.

In the next chapter, we'll dive deeper into how objects communicate through Io's message passing system—the heartbeat of the language.

---

*Next: [Chapter 5 - Messages and Slots](05-messages-and-slots.md)*