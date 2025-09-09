#!/usr/bin/env io
# Closure examples from Chapter 9

# Counter using closures
makeCounter := method(start,
    count := start
    block(
        count = count + 1
        count
    )
)

"\n=== Counter Example ===" println
counter1 := makeCounter(0)
counter2 := makeCounter(100)

"Counter1: " print
3 repeat(counter1 call print; " " print)
"" println

"Counter2: " print
3 repeat(counter2 call print; " " print)
"" println

# Function composition
"\n=== Function Composition ===" println
compose := method(f, g,
    block(x, f call(g call(x)))
)

double := block(x, x * 2)
addFive := block(x, x + 5)
doubleThenAddFive := compose(addFive, double)

("10 doubled then plus 5 = " .. doubleThenAddFive call(10)) println

# Partial application
"\n=== Partial Application ===" println
add := block(a, b, a + b)
addTen := block(x, add call(10, x))

("15 + 10 = " .. addTen call(15)) println

# Memoization
"\n=== Memoization ===" println
memoize := method(f,
    cache := Map clone
    block(n,
        if(cache hasKey(n asString),
            "Cache hit!" println
            cache at(n asString),
            "Computing..." println
            result := f call(n)
            cache atPut(n asString, result)
            result
        )
    )
)

slowSquare := block(n,
    wait(0.1)  # Simulate expensive computation
    n * n
)

fastSquare := memoize(slowSquare)

"First call to fastSquare(5):" println
fastSquare call(5) println

"Second call to fastSquare(5):" println
fastSquare call(5) println