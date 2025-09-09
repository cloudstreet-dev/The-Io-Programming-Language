#!/usr/bin/env io
# Prototype-based inheritance examples from Chapter 4

# Create a prototype chain
Animal := Object clone
Animal species := "Unknown"
Animal speak := method("Some sound" println)

Dog := Animal clone
Dog species = "Canis familiaris"
Dog speak := method("Woof!" println)
Dog wagTail := method("*wagging tail*" println)

fido := Dog clone
fido name := "Fido"

# Demonstrate inheritance
"=== Prototype Chain Demo ===" println
("fido's name: " .. fido name) println
("fido's species: " .. fido species) println
"fido speaks: " print
fido speak
"fido wags: " print
fido wagTail

# Show the prototype chain
"\n=== Prototype Chain ===" println
obj := fido
while(obj != Object,
    ("  " .. obj type) println
    obj = obj proto
)

# Dynamic prototype modification
"\n=== Dynamic Modification ===" println
"Adding 'fetch' method to Dog prototype..." println
Dog fetch := method("*fetching ball*" println)

"Now fido can fetch:" print
fido fetch  # Works even though fido was created before we added fetch!