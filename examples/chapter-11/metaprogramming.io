#!/usr/bin/env io
# Metaprogramming examples from Chapter 11

"\n=== Dynamic Method Creation ===" println

# Create getters and setters dynamically
Object addProperty := method(name, defaultValue,
    # Create storage slot
    self setSlot("_" .. name, defaultValue)
    
    # Create getter
    self setSlot(name, 
        method(self getSlot("_" .. call message name))
    )
    
    # Create setter
    self setSlot("set" .. name asCapitalized,
        method(value,
            propName := call message name afterSeq("set") asLowercase
            self setSlot("_" .. propName, value)
            self
        )
    )
)

Person := Object clone
Person addProperty("name", "Unknown")
Person addProperty("age", 0)

john := Person clone
john setName("John") setAge(25)
("Name: " .. john name) println
("Age: " .. john age) println

"\n=== Method Missing Pattern ===" println

DynamicObject := Object clone
DynamicObject forward := method(
    messageName := call message name
    args := call message arguments
    
    ("Intercepted unknown method: " .. messageName) println
    
    if(messageName beginsWithSeq("get"),
        property := messageName afterSeq("get") asLowercase
        return self getSlot(property)
    )
    
    if(messageName beginsWithSeq("set"),
        property := messageName afterSeq("set") asLowercase
        value := call evalArgAt(0)
        return self setSlot(property, value)
    )
    
    "Method not handled" println
)

obj := DynamicObject clone
obj setColor("blue")
obj setSize(42)
("Color: " .. obj getColor) println
("Size: " .. obj getSize) println

"\n=== Message Inspection ===" println

# Build and inspect messages
msg := message(2 + 3 * 4)
("Message: " .. msg) println
("Message name: " .. msg name) println
("Message arguments: " .. msg arguments) println

# Evaluate message
result := msg doInContext(Lobby)
("Result: " .. result) println

# Modify message
msg setName("*")
newResult := msg doInContext(Lobby)
("Modified result (now multiplication): " .. newResult) println

"\n=== Self-Modifying Code ===" println

Counter := Object clone
Counter count := 0
Counter increment := method(
    count = count + 1
    ("Count: " .. count) println
    
    # Self-modify after 3 calls
    if(count >= 3,
        "Limit reached! Disabling increment..." println
        self increment = method(
            "Counter is disabled!" println
        )
    )
    count
)

c := Counter clone
5 repeat(c increment)