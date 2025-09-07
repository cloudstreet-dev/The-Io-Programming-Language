# Chapter 15: Real-World Patterns

After exploring Io's features in isolation, this chapter brings everything together by examining patterns and architectures for building real applications. We'll see how Io's unique features enable elegant solutions to common programming challenges.

## Model-View-Controller (MVC)

Implementing MVC in Io leverages prototypes and message passing:

```io
// Model
Model := Object clone
Model init := method(
    self observers := list()
    self data := Map clone
    self
)

Model set := method(key, value,
    oldValue := data at(key)
    if(oldValue != value,
        data atPut(key, value)
        notifyObservers(key, oldValue, value)
    )
    self
)

Model get := method(key,
    data at(key)
)

Model observe := method(observer,
    observers append(observer)
    self
)

Model notifyObservers := method(key, oldValue, newValue,
    observers foreach(observer,
        if(observer hasSlot("modelChanged"),
            observer modelChanged(self, key, oldValue, newValue)
        )
    )
)

// View
View := Object clone
View init := method(model,
    self model := model
    model observe(self)
    self elements := Map clone
    self
)

View modelChanged := method(model, key, oldValue, newValue,
    render
)

View render := method(
    // Override in subclasses
)

// Controller
Controller := Object clone
Controller init := method(model, view,
    self model := model
    self view := view
    self
)

Controller handleInput := method(input,
    // Process input and update model
)

// Example: Todo MVC
TodoModel := Model clone
TodoModel init := method(
    resend
    self set("todos", list())
    self
)

TodoModel addTodo := method(text,
    todos := get("todos") copy
    todos append(Map with("text", text, "done", false))
    set("todos", todos)
)

TodoModel toggleTodo := method(index,
    todos := get("todos") copy
    todo := todos at(index)
    todo atPut("done", todo at("done") not)
    set("todos", todos)
)

TodoView := View clone
TodoView render := method(
    "=== Todo List ===" println
    model get("todos") foreach(i, todo,
        status := if(todo at("done"), "[✓]", "[ ]")
        (i .. ". " .. status .. " " .. todo at("text")) println
    )
    "================" println
)

TodoController := Controller clone
TodoController processCommand := method(cmd,
    parts := cmd split(" ")
    action := parts at(0)
    
    if(action == "add",
        text := parts slice(1) join(" ")
        model addTodo(text)
    )
    
    if(action == "toggle",
        index := parts at(1) asNumber
        model toggleTodo(index)
    )
    
    if(action == "quit",
        System exit
    )
)

// Usage
app := Object clone
app model := TodoModel clone init
app view := TodoView clone init(app model)
app controller := TodoController clone init(app model, app view)

app view render
// Simulate commands
app controller processCommand("add Buy groceries")
app controller processCommand("add Write documentation")
app controller processCommand("toggle 0")
```

## Repository Pattern

Abstracting data access:

```io
// Base Repository
Repository := Object clone
Repository init := method(
    self storage := list()
    self nextId := 1
    self
)

Repository save := method(entity,
    if(entity hasSlot("id") not or entity id isNil,
        entity id := nextId
        nextId = nextId + 1
        storage append(entity)
    ,
        // Update existing
        index := storage detectIndex(e, e id == entity id)
        if(index, storage atPut(index, entity))
    )
    entity
)

Repository findById := method(id,
    storage detect(e, e id == id)
)

Repository findAll := method(
    storage copy
)

Repository delete := method(entity,
    storage remove(entity)
)

Repository where := method(predicate,
    storage select(predicate)
)

// Specialized repository with persistence
FileRepository := Repository clone
FileRepository filename := "data.json"

FileRepository init := method(
    resend
    load
    self
)

FileRepository load := method(
    if(File with(filename) exists,
        data := File with(filename) contents parseJson
        storage = data map(item, entityFromMap(item))
        nextId = storage map(e, e id) max + 1
    )
)

FileRepository save := method(entity,
    resend(entity)
    persist
    entity
)

FileRepository persist := method(
    data := storage map(e, e asMap)
    File with(filename) openForWriting write(data asJson) close
)

// Entity
User := Object clone
User init := method(name, email,
    self id := nil
    self name := name
    self email := email
    self createdAt := Date now
    self
)

User asMap := method(
    Map with(
        "id", id,
        "name", name,
        "email", email,
        "createdAt", createdAt asString
    )
)

// Usage
userRepo := FileRepository clone init

user1 := User clone init("Alice", "alice@example.com")
user2 := User clone init("Bob", "bob@example.com")

userRepo save(user1)
userRepo save(user2)

found := userRepo findById(1)
active := userRepo where(u, u createdAt > Date now - Duration days(30))
```

## Observer Pattern

Native implementation using Io's message passing:

```io
Observable := Object clone
Observable init := method(
    self observers := Map clone
    self
)

Observable on := method(event, observer, methodName,
    if(observers hasKey(event) not,
        observers atPut(event, list())
    )
    observers at(event) append(list(observer, methodName))
    self
)

Observable off := method(event, observer,
    if(observers hasKey(event),
        observers at(event) := observers at(event) reject(pair,
            pair at(0) == observer
        )
    )
    self
)

Observable emit := method(event,
    args := call message arguments slice(1)
    
    if(observers hasKey(event),
        observers at(event) foreach(pair,
            observer := pair at(0)
            methodName := pair at(1)
            
            msg := Message clone setName(methodName)
            args foreach(arg, msg appendArg(arg))
            
            observer doMessage(msg)
        )
    )
    self
)

// Example: Stock price monitor
Stock := Observable clone
Stock init := method(symbol, price,
    resend
    self symbol := symbol
    self price := price
    self
)

Stock setPrice := method(newPrice,
    oldPrice := price
    price = newPrice
    
    change := ((newPrice - oldPrice) / oldPrice * 100) round
    emit("priceChanged", symbol, oldPrice, newPrice, change)
    
    if(change abs > 5,
        emit("largeMoveDetected", symbol, change)
    )
)

StockAlert := Object clone
StockAlert onPriceChange := method(symbol, oldPrice, newPrice, change,
    ("Price alert: " .. symbol .. " moved from $" .. oldPrice .. 
     " to $" .. newPrice .. " (" .. change .. "%)") println
)

StockAlert onLargeMove := method(symbol, change,
    ("⚠️  Large move detected: " .. symbol .. " changed " .. change .. "%") println
)

// Usage
apple := Stock clone init("AAPL", 150.00)
alert := StockAlert clone

apple on("priceChanged", alert, "onPriceChange")
apple on("largeMoveDetected", alert, "onLargeMove")

apple setPrice(155.00)  // Normal change
apple setPrice(165.00)  // Large move triggers both alerts
```

## Dependency Injection

Using Io's dynamic nature for DI:

```io
// DI Container
Container := Object clone
Container init := method(
    self services := Map clone
    self singletons := Map clone
    self
)

Container register := method(name, factory,
    services atPut(name, factory)
    self
)

Container singleton := method(name, factory,
    services atPut(name, factory)
    singletons atPut(name, nil)
    self
)

Container get := method(name,
    if(services hasKey(name) not,
        Exception raise("Service '" .. name .. "' not registered")
    )
    
    // Check if singleton
    if(singletons hasKey(name),
        if(singletons at(name) isNil,
            singletons atPut(name, services at(name) call(self))
        )
        return singletons at(name)
    )
    
    // Regular service
    services at(name) call(self)
)

// Services
Logger := Object clone
Logger init := method(output,
    self output := output
    self
)
Logger log := method(message,
    output write("[" .. Date now .. "] " .. message .. "\n")
)

Database := Object clone
Database init := method(connectionString, logger,
    self connectionString := connectionString
    self logger := logger
    logger log("Database initialized: " .. connectionString)
    self
)

UserService := Object clone
UserService init := method(database, logger,
    self database := database
    self logger := logger
    self
)
UserService createUser := method(name,
    logger log("Creating user: " .. name)
    // database operations...
    Map with("id", 1, "name", name)
)

// Configure container
container := Container clone init

container singleton("logger", block(c,
    Logger clone init(File standardOutput)
))

container singleton("database", block(c,
    Database clone init("postgres://localhost/myapp", c get("logger"))
))

container register("userService", block(c,
    UserService clone init(c get("database"), c get("logger"))
))

// Usage
service := container get("userService")
service createUser("Alice")

// Different instance each time
service1 := container get("userService")
service2 := container get("userService")
(service1 == service2) println  // false

// Same logger instance
logger1 := container get("logger")
logger2 := container get("logger")
(logger1 == logger2) println  // true
```

## Strategy Pattern

Leveraging blocks and dynamic dispatch:

```io
// Sorting strategies
SortStrategy := Object clone

BubbleSort := SortStrategy clone
BubbleSort execute := method(list,
    result := list copy
    n := result size
    
    for(i, 0, n - 2,
        for(j, 0, n - i - 2,
            if(result at(j) > result at(j + 1),
                temp := result at(j)
                result atPut(j, result at(j + 1))
                result atPut(j + 1, temp)
            )
        )
    )
    result
)

QuickSort := SortStrategy clone
QuickSort execute := method(list,
    if(list size <= 1, return list)
    
    pivot := list at(list size / 2)
    less := list select(x, x < pivot)
    equal := list select(x, x == pivot)
    greater := list select(x, x > pivot)
    
    execute(less) appendSeq(equal) appendSeq(execute(greater))
)

// Context
DataProcessor := Object clone
DataProcessor init := method(
    self strategy := QuickSort
    self
)

DataProcessor setStrategy := method(s,
    strategy = s
    self
)

DataProcessor process := method(data,
    "Processing data..." println
    strategy execute(data)
)

// Usage with different strategies
processor := DataProcessor clone init

data := list(3, 1, 4, 1, 5, 9, 2, 6)

processor setStrategy(BubbleSort) process(data) println
processor setStrategy(QuickSort) process(data) println

// Dynamic strategy selection
selectStrategy := method(dataSize,
    if(dataSize < 10, BubbleSort, QuickSort)
)

processor setStrategy(selectStrategy(data size))
```

## Chain of Responsibility

Building processing pipelines:

```io
Handler := Object clone
Handler init := method(
    self next := nil
    self
)

Handler setNext := method(handler,
    next = handler
    handler
)

Handler handle := method(request,
    if(canHandle(request),
        process(request),
        if(next, next handle(request), nil)
    )
)

// Concrete handlers
AuthenticationHandler := Handler clone
AuthenticationHandler canHandle := method(request,
    request at("requiresAuth")
)
AuthenticationHandler process := method(request,
    if(request at("token") == "valid-token",
        "Authentication successful" println
        request atPut("authenticated", true)
        if(next, next handle(request), request)
    ,
        Exception raise("Authentication failed")
    )
)

LoggingHandler := Handler clone
LoggingHandler canHandle := method(request, true)
LoggingHandler process := method(request,
    ("Logging request: " .. request at("path")) println
    if(next, next handle(request), request)
)

RateLimitHandler := Handler clone
RateLimitHandler init := method(
    resend
    self requests := Map clone
    self limit := 10
    self window := 60  // seconds
    self
)
RateLimitHandler canHandle := method(request,
    request hasKey("clientId")
)
RateLimitHandler process := method(request,
    clientId := request at("clientId")
    now := Date now
    
    if(requests hasKey(clientId) not,
        requests atPut(clientId, list())
    )
    
    // Clean old requests
    clientRequests := requests at(clientId) select(time,
        now - time < window
    )
    
    if(clientRequests size >= limit,
        Exception raise("Rate limit exceeded"),
        clientRequests append(now)
        requests atPut(clientId, clientRequests)
        if(next, next handle(request), request)
    )
)

// Build chain
chain := LoggingHandler clone \
    setNext(RateLimitHandler clone \
        setNext(AuthenticationHandler clone))

// Process requests
request := Map with(
    "path", "/api/users",
    "clientId", "client-123",
    "requiresAuth", true,
    "token", "valid-token"
)

result := chain handle(request)
```

## Plugin Architecture

Dynamic loading and extension:

```io
PluginManager := Object clone
PluginManager init := method(
    self plugins := Map clone
    self hooks := Map clone
    self
)

PluginManager registerHook := method(name,
    if(hooks hasKey(name) not,
        hooks atPut(name, list())
    )
    self
)

PluginManager loadPlugin := method(path,
    plugin := doFile(path)
    
    if(plugin hasSlot("name") not,
        Exception raise("Plugin must have a name")
    )
    
    plugins atPut(plugin name, plugin)
    
    if(plugin hasSlot("init"),
        plugin init(self)
    )
    
    ("Plugin loaded: " .. plugin name) println
    self
)

PluginManager hook := method(name,
    args := call message arguments slice(1)
    results := list()
    
    if(hooks hasKey(name),
        hooks at(name) foreach(handler,
            result := handler doMessage(Message clone setName("call") setArguments(args))
            results append(result)
        )
    )
    
    results
)

PluginManager addHook := method(hookName, handler,
    if(hooks hasKey(hookName) not,
        registerHook(hookName)
    )
    hooks at(hookName) append(handler)
    self
)

// Example plugin
MarkdownPlugin := Object clone
MarkdownPlugin name := "markdown"
MarkdownPlugin init := method(manager,
    manager addHook("processText", block(text,
        // Simple markdown processing
        text replaceAllRegex("\\*\\*(.*?)\\*\\*", "<strong>$1</strong>") \
             replaceAllRegex("\\*(.*?)\\*", "<em>$1</em>")
    ))
    
    manager addHook("getFormats", block(
        list("markdown", "md")
    ))
)

// Usage
manager := PluginManager clone init
manager registerHook("processText")
manager registerHook("getFormats")

// Load plugins
manager loadPlugin("markdown_plugin.io")

// Use hooks
text := "This is **bold** and this is *italic*"
processed := manager hook("processText", text)
processed foreach(result, result println)

formats := manager hook("getFormats")
"Supported formats: " print
formats flatten unique println
```

## Event Sourcing

Implementing event-driven architecture:

```io
// Event
Event := Object clone
Event init := method(type, data,
    self type := type
    self data := data
    self timestamp := Date now
    self id := Random uuid
    self
)

// Event Store
EventStore := Object clone
EventStore init := method(
    self events := list()
    self snapshots := Map clone
    self
)

EventStore append := method(event,
    events append(event)
    self
)

EventStore getEvents := method(afterId,
    if(afterId isNil,
        return events
    )
    
    startIndex := events detectIndex(e, e id == afterId)
    if(startIndex,
        events slice(startIndex + 1),
        list()
    )
)

// Aggregate
Aggregate := Object clone
Aggregate init := method(id,
    self id := id
    self version := 0
    self uncommittedEvents := list()
    self
)

Aggregate applyEvent := method(event,
    // Override in subclasses
)

Aggregate raiseEvent := method(event,
    applyEvent(event)
    uncommittedEvents append(event)
    version = version + 1
)

Aggregate markEventsAsCommitted := method(
    uncommittedEvents = list()
)

Aggregate loadFromHistory := method(events,
    events foreach(event,
        applyEvent(event)
        version = version + 1
    )
)

// Example: Bank Account aggregate
BankAccount := Aggregate clone
BankAccount init := method(id,
    resend(id)
    self balance := 0
    self
)

BankAccount deposit := method(amount,
    if(amount <= 0,
        Exception raise("Amount must be positive")
    )
    
    raiseEvent(Event clone init("MoneyDeposited", 
        Map with("accountId", id, "amount", amount)))
)

BankAccount withdraw := method(amount,
    if(amount <= 0,
        Exception raise("Amount must be positive")
    )
    if(amount > balance,
        Exception raise("Insufficient funds")
    )
    
    raiseEvent(Event clone init("MoneyWithdrawn",
        Map with("accountId", id, "amount", amount)))
)

BankAccount applyEvent := method(event,
    if(event type == "MoneyDeposited",
        balance = balance + event data at("amount")
    )
    
    if(event type == "MoneyWithdrawn",
        balance = balance - event data at("amount")
    )
)

// Repository using event sourcing
AccountRepository := Object clone
AccountRepository init := method(eventStore,
    self eventStore := eventStore
    self
)

AccountRepository save := method(account,
    account uncommittedEvents foreach(event,
        eventStore append(event)
    )
    account markEventsAsCommitted
)

AccountRepository getById := method(id,
    events := eventStore getEvents select(e,
        e data at("accountId") == id
    )
    
    account := BankAccount clone init(id)
    account loadFromHistory(events)
    account
)

// Usage
store := EventStore clone init
repo := AccountRepository clone init(store)

account := BankAccount clone init("acc-123")
account deposit(100)
account withdraw(30)
account deposit(50)

repo save(account)
account balance println  // 120

// Rebuild from events
rebuilt := repo getById("acc-123")
rebuilt balance println  // 120
```

## Caching Strategy

Multi-level caching with different policies:

```io
Cache := Object clone
Cache init := method(maxSize, ttl,
    self maxSize := maxSize
    self ttl := ttl  // Time to live in seconds
    self entries := Map clone
    self accessOrder := list()
    self
)

Cache get := method(key,
    if(entries hasKey(key),
        entry := entries at(key)
        
        // Check TTL
        if(Date now - entry at("time") > ttl,
            entries removeAt(key)
            accessOrder remove(key)
            return nil
        )
        
        // Update access order (LRU)
        accessOrder remove(key)
        accessOrder append(key)
        
        entry at("value")
    ,
        nil
    )
)

Cache put := method(key, value,
    // Evict if necessary
    while(entries size >= maxSize,
        evictKey := accessOrder removeFirst
        entries removeAt(evictKey)
        ("Cache evicted: " .. evictKey) println
    )
    
    entries atPut(key, Map with(
        "value", value,
        "time", Date now
    ))
    accessOrder append(key)
    
    value
)

Cache getOrCompute := method(key, computeBlock,
    value := get(key)
    if(value isNil,
        value = computeBlock call
        put(key, value)
    )
    value
)

// Multi-level cache
MultiLevelCache := Object clone
MultiLevelCache init := method(
    self l1 := Cache clone init(10, 60)     // Small, fast, 1 minute TTL
    self l2 := Cache clone init(100, 600)   // Larger, 10 minute TTL
    self
)

MultiLevelCache get := method(key,
    // Check L1
    value := l1 get(key)
    if(value, return value)
    
    // Check L2
    value = l2 get(key)
    if(value,
        l1 put(key, value)  // Promote to L1
        return value
    )
    
    nil
)

MultiLevelCache put := method(key, value,
    l1 put(key, value)
    l2 put(key, value)
    value
)

// Usage with expensive computation
fibonacci := Object clone
fibonacci cache := MultiLevelCache clone init

fibonacci compute := method(n,
    if(n <= 1, return n)
    
    cache get(n) ifNil(
        ("Computing fib(" .. n .. ")") println
        result := compute(n - 1) + compute(n - 2)
        cache put(n, result)
        result
    )
)

fibonacci compute(10) println  // Computes
fibonacci compute(10) println  // From cache
```

## Conclusion

These patterns demonstrate how Io's features—prototype-based inheritance, message passing, blocks, and metaprogramming—combine to create elegant solutions to real-world problems. The language's flexibility allows patterns to be implemented more directly than in many mainstream languages, often with less boilerplate and more expressive code.

The key insight is that Io's uniform object model means patterns aren't special constructs but natural expressions of the language's core concepts. This makes it easy to adapt patterns to specific needs or create entirely new architectural approaches.

---

*Next: [Chapter 16 - Case Studies](16-case-studies.md)*