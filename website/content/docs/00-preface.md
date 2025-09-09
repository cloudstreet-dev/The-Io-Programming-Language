---
title: "Why Io?"
weight: 10
---



# Preface: Why Io?

In a world dominated by class-based object-oriented languages, why should you spend time learning Io, a prototype-based language with a relatively small community? This is a fair question, and one that deserves an honest answer.

## The Value of Alternative Paradigms

Most programmers today work in languages that share remarkably similar conceptual foundations. Whether you're writing Java, C#, Python, or Ruby, you're likely thinking in terms of classes, instances, inheritance hierarchies, and static method definitions. These concepts have served us well, but they represent just one way of organizing computational thought.

Io offers something different: a pure prototype-based object system where these familiar distinctions dissolve. There are no classes, only objects. There is no separation between data and behavior. Everything—including control structures and operators—is accomplished through message passing between objects.

Consider this simple comparison. In Python, you might write:

```python
class Dog:
    def __init__(self, name):
        self.name = name
    
    def bark(self):
        return f"{self.name} says woof!"

fido = Dog("Fido")
print(fido.bark())
```

In Io, the same concept looks like this:

```io
Dog := Object clone
Dog bark := method(name .. " says woof!")

fido := Dog clone
fido name := "Fido"
fido bark println
```

At first glance, this might seem like a minor syntactic difference. But look closer: there's no class definition, no constructor, no special initialization syntax. `Dog` is just an object that we've cloned from the base `Object`. `fido` is just a clone of `Dog`. The simplicity is profound.

## What You'll Gain

### 1. **A Deeper Understanding of JavaScript**

If you've ever been puzzled by JavaScript's prototype chain, or wondered why `typeof null === "object"`, studying Io will illuminate these mysteries. JavaScript's object model is essentially prototype-based (though complicated by the later addition of class syntax), and Io presents these same concepts in a much purer form.

### 2. **Freedom from Artificial Boundaries**

In most languages, there's a rigid distinction between what the language provides and what you can build. You can't change how `if` statements work. You can't modify how method calls are resolved. You can't alter fundamental objects.

In Io, these boundaries don't exist. The `if` statement is just a message sent to an object. Method resolution is customizable. Even basic types like `Number` and `String` can be modified at runtime. This isn't just academically interesting—it enables patterns of expression impossible in more rigid languages.

### 3. **Appreciation for Message Passing**

While many languages claim to support "message passing," few take it as seriously as Io. When everything is truly a message—including operators, control flow, and assignment—you begin to see the elegant simplicity possible in language design. This perspective will change how you think about method calls and object interaction in any language.

### 4. **Metaprogramming Without Magic**

Languages like Ruby pride themselves on metaprogramming capabilities, but often these features feel like special cases—magic methods, decorators, metaclasses. In Io, metaprogramming isn't a special feature; it's the natural consequence of a simple, consistent object model. When you can inspect and modify any object at runtime, including the objects that define the language itself, metaprogramming becomes straightforward rather than mystical.

## Who Should Read This Book

This book assumes you're already a programmer. You should be comfortable with:

- Basic programming concepts (variables, functions, loops, conditions)
- Object-oriented programming in at least one language
- Using a command line and text editor
- The idea that different languages encourage different ways of thinking

You don't need to be an expert. In fact, if you've only worked in one or two mainstream languages, you might find Io's different perspective especially valuable. Sometimes, those deeply entrenched in certain paradigms have the most difficulty seeing alternatives.

## What Makes Io Special

Steve Dekorte created Io in 2002 with several goals:

1. **Simplicity** - A minimal syntax with maximum expressiveness
2. **Flexibility** - Everything modifiable at runtime
3. **Uniformity** - One consistent model for everything
4. **Power** - Advanced features like coroutines and actors built-in

The result is a language that fits in roughly 10,000 lines of C code, yet provides capabilities that mainstream languages achieve only through complex implementations or external libraries.

## A Language for Learning

I won't pretend that Io is likely to become your primary development language. Its community is small, its libraries limited, and its performance, while respectable, isn't competitive with systems languages or JIT-compiled platforms.

But Io excels as a language for *learning*. Its simple, consistent design makes it easy to understand completely. You can hold the entire language in your head. There are no special cases to remember, no historical baggage to work around. When you understand Io's seven basic concepts, you understand the entire language.

## How to Approach This Book

As you read, I encourage you to:

1. **Run every example**. Io's REPL starts instantly and makes experimentation effortless.

2. **Modify the examples**. What happens if you change this? What if you clone from a different object? What if you override this method?

3. **Compare with languages you know**. When you see an Io pattern, think about how you'd accomplish the same thing in Python, JavaScript, or Java. What's easier? What's harder? What's impossible?

4. **Embrace the discomfort**. Some Io concepts will feel alien at first. That's good—it means you're learning something genuinely new.

## A Personal Note

I've been programming for [X] years and have worked in dozens of languages. Most taught me new syntax or libraries. Io taught me new ways to think. It challenged assumptions I didn't know I had. It showed me that many "fundamental" concepts in programming are actually just design choices, and different choices lead to different possibilities.

Whether you spend a weekend or a month with Io, I believe you'll emerge a better programmer. Not because you'll use Io in production (though you might), but because you'll have a broader perspective on what programming languages can be.

Let's begin.

---

*Next: [Chapter 1 - Introduction: The Philosophy of Io](01-introduction.md)*
