---
title: "Exceptions"
weight: 110
---



# Chapter 10: Exceptions

Error handling is crucial for robust programs. Io provides an exception system that, like everything else in the language, is built on objects and messages. This chapter explores how exceptions work, how to handle errors gracefully, and how to create custom exception types.

## Basic Exception Handling

Io uses `try`, `catch`, and `raise` for exception handling:

```io
// Basic try-catch
try(
    10 / 0  // Division by zero
) catch(Exception, e,
    ("Error: " .. e message) println
)
// Error: divide by zero

// Multiple catch blocks
try(
    someRiskyOperation()
) catch(TypeError, e,
    "Type error occurred" println
) catch(IOException, e,
    "IO error occurred" println
) catch(Exception, e,
    "Some other error occurred" println
)
```

Compare with other languages:

```python
# Python
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print(f"Error: {e}")
```

```java
// Java
try {
    int result = 10 / 0;
} catch (ArithmeticException e) {
    System.out.println("Error: " + e.getMessage());
}
```

## Raising Exceptions

```io
// Raise a simple exception
Exception raise("Something went wrong")

// Raise with more information
e := Exception clone
e setMessage("File not found")
e raise

// Conditional raising
validateAge := method(age,
    if(age < 0, Exception raise("Age cannot be negative"))
    if(age > 150, Exception raise("Age seems unrealistic"))
    age
)

try(
    validateAge(-5)
) catch(Exception, e,
    e message println  // Age cannot be negative
)
```

## Exception Objects

Exceptions are just objects:

```io
// Examine exception structure
e := Exception clone
e type println           // Exception
e proto println          // Object_0x...

// Exception slots
e setMessage("Test error")
e message println        // Test error

// Stack trace
try(
    Exception raise("Test")
) catch(Exception, e,
    e showStack  // Prints full stack trace
    e coroutine println  // The coroutine where error occurred
)
```

## Creating Custom Exceptions

```io
// Define custom exception types
ValidationError := Exception clone
ValidationError type := "ValidationError"

NetworkError := Exception clone
NetworkError type := "NetworkError"
NetworkError code := nil
NetworkError setCode := method(c, self code = c; self)

// Use custom exceptions
validateEmail := method(email,
    if(email containsSeq("@") not,
        ValidationError clone setMessage("Invalid email format") raise
    )
    email
)

fetchData := method(url,
    // Simulate network error
    if(Random value < 0.3,
        NetworkError clone setMessage("Connection timeout") setCode(408) raise
    )
    "data"
)

// Handle specific exception types
try(
    validateEmail("badEmail")
) catch(ValidationError, e,
    ("Validation failed: " .. e message) println
) catch(Exception, e,
    ("Unexpected error: " .. e message) println
)
```

## The finally Block

```io
// Ensure cleanup with finally
file := nil
try(
    file = File with("data.txt") openForReading
    contents := file contents
    processData(contents)
) catch(Exception, e,
    ("Error reading file: " .. e message) println
) finally(
    if(file, file close)
    "Cleanup complete" println
)

// finally always executes
result := try(
    "Success" println
    42
) catch(Exception, e,
    "Error" println
    0
) finally(
    "Always runs" println
)
// Prints: Success, Always runs
result println  // 42
```

## Return Values and Exceptions

```io
// try returns a value
result := try(
    10 / 2
) catch(Exception, e,
    0  // Default value on error
)
result println  // 5

// With error
result := try(
    10 / 0
) catch(Exception, e,
    0  // Default value on error
)
result println  // 0

// Pattern: Result or default
safeDiv := method(a, b,
    try(a / b) catch(Exception, 0)
)

safeDiv(10, 2) println  // 5
safeDiv(10, 0) println  // 0
```

## Exception Propagation

Exceptions bubble up through the call stack:

```io
level3 := method(
    Exception raise("Error at level 3")
)

level2 := method(
    "Level 2 start" println
    level3()
    "Level 2 end" println  // Never reached
)

level1 := method(
    "Level 1 start" println
    level2()
    "Level 1 end" println  // Never reached
)

try(
    level1()
) catch(Exception, e,
    ("Caught at top level: " .. e message) println
)
// Level 1 start
// Level 2 start
// Caught at top level: Error at level 3
```

## Rethrowing Exceptions

```io
processFile := method(filename,
    try(
        file := File with(filename) openForReading
        // Process file
    ) catch(Exception, e,
        ("Failed to process " .. filename) println
        e raise  // Rethrow the original exception
    )
)

try(
    processFile("nonexistent.txt")
) catch(Exception, e,
    "Caught rethrown exception" println
)
```

## Error Recovery Patterns

### Retry Pattern

```io
retryOperation := method(operation, maxAttempts,
    attempts := 0
    lastError := nil
    
    while(attempts < maxAttempts,
        attempts = attempts + 1
        
        e := try(
            return operation call(attempts)
        )
        
        if(e,
            lastError = e
            ("Attempt " .. attempts .. " failed: " .. e message) println
            if(attempts < maxAttempts, wait(0.5))
        )
    )
    
    Exception raise("All " .. maxAttempts .. " attempts failed. Last error: " .. lastError message)
)

// Usage
result := retryOperation(
    block(attempt,
        if(Random value < 0.7,
            Exception raise("Random failure"),
            "Success on attempt " .. attempt
        )
    ),
    3
)
```

### Circuit Breaker

```io
CircuitBreaker := Object clone
CircuitBreaker init := method(threshold, timeout,
    self failureCount := 0
    self threshold := threshold
    self timeout := timeout
    self state := "closed"  // closed, open, half-open
    self lastFailureTime := nil
    self
)

CircuitBreaker call := method(operation,
    if(state == "open",
        if(Date now - lastFailureTime > timeout,
            state = "half-open"
            "Circuit breaker entering half-open state" println,
            Exception raise("Circuit breaker is open")
        )
    )
    
    e := try(
        result := operation call
        if(state == "half-open",
            state = "closed"
            failureCount = 0
            "Circuit breaker closed" println
        )
        return result
    )
    
    if(e,
        failureCount = failureCount + 1
        lastFailureTime = Date now
        
        if(failureCount >= threshold,
            state = "open"
            "Circuit breaker opened" println
        )
        
        e raise
    )
)

// Usage
breaker := CircuitBreaker clone init(3, 5)

unreliableService := block(
    if(Random value < 0.8,
        Exception raise("Service unavailable"),
        "Service response"
    )
)

5 repeat(
    try(
        breaker call(unreliableService) println
    ) catch(Exception, e,
        ("Failed: " .. e message) println
    )
    wait(1)
)
```

## Assertion and Validation

```io
// Simple assertion
assert := method(condition, message,
    if(condition not,
        Exception raise(message ifNilEval("Assertion failed"))
    )
)

assert(5 > 3, "Math is broken")
// assert(3 > 5, "This will fail")

// Validation framework
Validator := Object clone
Validator rules := list()

Validator addRule := method(rule, message,
    rules append(list(rule, message))
    self
)

Validator validate := method(value,
    errors := list()
    
    rules foreach(rule,
        if(rule at(0) call(value) not,
            errors append(rule at(1))
        )
    )
    
    if(errors size > 0,
        ValidationError clone setMessage(errors join(", ")) raise
    )
    
    value
)

// Usage
ageValidator := Validator clone \
    addRule(block(v, v isKindOf(Number)), "Must be a number") \
    addRule(block(v, v >= 0), "Must be non-negative") \
    addRule(block(v, v <= 150), "Must be realistic")

try(
    ageValidator validate(25) println  // 25
    ageValidator validate(-5)  // Throws
) catch(ValidationError, e,
    e message println  // Must be non-negative
)
```

## Exception Context and Debugging

```io
// Enhanced exception with context
ContextualException := Exception clone
ContextualException context := Map clone

ContextualException addContext := method(key, value,
    context atPut(key, value)
    self
)

ContextualException describe := method(
    result := message .. "\nContext:\n"
    context foreach(key, value,
        result = result .. "  " .. key .. ": " .. value .. "\n"
    )
    result
)

// Usage
processUser := method(userData,
    if(userData at("age") < 18,
        ContextualException clone \
            setMessage("User too young") \
            addContext("userId", userData at("id")) \
            addContext("age", userData at("age")) \
            addContext("timestamp", Date now) \
            raise
    )
)

try(
    processUser(Map with("id", 123, "age", 16))
) catch(ContextualException, e,
    e describe println
)
```

## Resource Management

```io
// RAII-style resource management
withResource := method(resourceCreator, resourceUser,
    resource := nil
    try(
        resource = resourceCreator call
        resourceUser call(resource)
    ) finally(
        if(resource and resource hasSlot("close"),
            resource close
        )
    )
)

// Usage
withResource(
    block(File with("test.txt") openForReading),
    block(file,
        file contents println
    )
)

// Database connection example
withConnection := method(dbUrl, operation,
    conn := nil
    try(
        conn = Database connect(dbUrl)
        conn beginTransaction
        result := operation call(conn)
        conn commit
        result
    ) catch(Exception, e,
        if(conn, conn rollback)
        e raise
    ) finally(
        if(conn, conn close)
    )
)
```

## Global Exception Handling

```io
// Install global exception handler
System handleException := method(e,
    logFile := File with("errors.log") openForAppending
    logFile write(Date now asString .. " - " .. e message .. "\n")
    logFile close
    
    // Original behavior
    e showStack
    System exit(1)
)

// Uncaught exceptions now get logged
// Exception raise("Uncaught error")
```

## Testing with Exceptions

```io
// Test framework with exception support
Test := Object clone
Test assertRaises := method(exceptionType, block,
    raised := false
    try(
        block call
    ) catch(Exception, e,
        if(e type == exceptionType type,
            raised = true,
            Exception raise("Wrong exception type: expected " .. exceptionType type .. ", got " .. e type)
        )
    )
    
    if(raised not,
        Exception raise("Expected exception " .. exceptionType type .. " was not raised")
    )
)

// Usage
Test assertRaises(ValidationError, block(
    validateEmail("invalid")
))
"Test passed" println
```

## Performance Considerations

```io
// Exceptions have overhead
benchmark := method(name, iterations, block,
    start := Date now
    iterations repeat(block)
    elapsed := Date now - start
    (name .. ": " .. elapsed) println
)

// Without exceptions
benchmark("No exceptions", 100000, block(
    if(Random value < 0.1, nil, "success")
))

// With exceptions
benchmark("With exceptions", 100000, block(
    try(
        if(Random value < 0.1, Exception raise("error"))
        "success"
    ) catch(Exception, nil)
))

// Exceptions are slower - use for exceptional cases, not control flow
```

## Common Pitfalls

### Catching Too Broadly

```io
// BAD: Catches everything, hiding bugs
try(
    complexOperation()
) catch(Exception, e,
    // Silently ignore all errors
)

// GOOD: Catch specific exceptions
try(
    complexOperation()
) catch(NetworkError, e,
    handleNetworkError(e)
) catch(ValidationError, e,
    handleValidationError(e)
)
```

### Resource Leaks

```io
// BAD: File not closed on error
file := File with("data.txt") openForReading
processFile(file)  // If this throws, file never closes
file close

// GOOD: Use finally
file := nil
try(
    file = File with("data.txt") openForReading
    processFile(file)
) finally(
    if(file, file close)
)
```

## Exercises

1. **Result Type**: Implement a Result type that can be either Ok(value) or Error(error), similar to Rust.

2. **Retry with Exponential Backoff**: Create a retry mechanism with exponential backoff and jitter.

3. **Exception Logger**: Build a logging system that captures and categorizes exceptions.

4. **Validation Chain**: Create a validation system that accumulates all errors instead of failing on first.

5. **Async Exception Handling**: Implement exception handling for coroutine-based async operations.

## Real-World Example: HTTP Client with Error Handling

```io
HttpClient := Object clone
HttpClient timeoutMs := 5000
HttpClient maxRetries := 3

HttpError := Exception clone
HttpError statusCode := nil

HttpClient get := method(url,
    retryCount := 0
    
    loop(
        try(
            response := self doRequest(url)
            
            if(response statusCode >= 200 and response statusCode < 300,
                return response body
            )
            
            if(response statusCode >= 400 and response statusCode < 500,
                // Client error - don't retry
                HttpError clone \
                    setMessage("HTTP " .. response statusCode) \
                    setSlot("statusCode", response statusCode) \
                    raise
            )
            
            // Server error - might retry
            if(response statusCode >= 500,
                error := HttpError clone \
                    setMessage("Server error: " .. response statusCode) \
                    setSlot("statusCode", response statusCode)
                
                if(retryCount < maxRetries,
                    retryCount = retryCount + 1
                    delay := (2 pow(retryCount)) * 100
                    ("Retry " .. retryCount .. " after " .. delay .. "ms") println
                    wait(delay / 1000)
                    continue,
                    error raise
                )
            )
            
        ) catch(NetworkError, e,
            if(retryCount < maxRetries,
                retryCount = retryCount + 1
                ("Network error, retry " .. retryCount) println
                wait(1)
                continue,
                e raise
            )
        )
    )
)

// Usage with comprehensive error handling
fetchUserData := method(userId,
    try(
        data := HttpClient get("https://api.example.com/users/" .. userId)
        JSON parse(data)
    ) catch(HttpError, e,
        if(e statusCode == 404,
            nil,  // User not found
            if(e statusCode == 401,
                Exception raise("Authentication required"),
                Exception raise("HTTP error: " .. e statusCode)
            )
        )
    ) catch(NetworkError, e,
        Exception raise("Network unavailable")
    ) catch(Exception, e,
        Exception raise("Unexpected error: " .. e message)
    )
)
```

## Conclusion

Io's exception system demonstrates the language's consistency: exceptions are objects, throwing is a message, and catching is a method. This uniformity makes the system easy to understand while remaining powerful enough for sophisticated error handling.

The key to effective exception handling in Io is understanding when to use exceptions (for exceptional circumstances) versus return values (for expected conditions), and ensuring proper resource cleanup with `finally` blocks. Custom exception types and contextual information make debugging easier, while patterns like retry logic and circuit breakers add robustness to applications.

---

*Next: [Chapter 11 - Metaprogramming](11-metaprogramming.md)*
