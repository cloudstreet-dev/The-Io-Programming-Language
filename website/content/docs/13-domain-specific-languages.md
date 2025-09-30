---
title: "Domain-Specific Languages"
weight: 140
---



# Chapter 13: Domain-Specific Languages

Io's minimal syntax, message-passing model, and metaprogramming capabilities make it ideal for creating Domain-Specific Languages (DSLs). This chapter explores how to build expressive DSLs that feel native to their problem domains.

## Why Io Excels at DSLs

Several features make Io particularly suitable for DSLs:

1. **Minimal syntax** - Less language machinery to work around
2. **Optional parentheses** - Clean, readable DSL code
3. **Message chains** - Natural expression of domain concepts
4. **Runtime flexibility** - Modify behavior on the fly
5. **Homoiconicity** - Code as manipulable data

Compare a hypothetical DSL in Io vs Ruby:

```io
// Io DSL - clean, minimal
recipe "Chocolate Cake" makes(8) servings {
    ingredient "flour" amount(2) cups
    ingredient "sugar" amount(1.5) cups
    
    step "Mix dry ingredients"
    step "Add wet ingredients"
    bake at(350) degrees for(30) minutes
}
```

```ruby
# Ruby DSL - more syntax artifacts
recipe "Chocolate Cake" do
    makes 8.servings
    
    ingredient "flour", amount: 2.cups
    ingredient "sugar", amount: 1.5.cups
    
    step "Mix dry ingredients"
    step "Add wet ingredients"
    bake at: 350.degrees, for: 30.minutes
end
```

## Building Your First DSL

Let's create a simple configuration DSL:

```io
// Define the DSL
Config := Object clone
Config settings := Map clone

Config set := method(key, value,
    settings atPut(key asString, value)
    self  // For chaining
)

Config get := method(key,
    settings at(key asString)
)

Config section := method(name,
    sec := Config clone
    settings atPut(name asString, sec)
    sec
)

// Use the DSL
config := Config clone
config set("host", "localhost") \
      set("port", 8080) \
      section("database") \
          set("driver", "postgresql") \
          set("name", "myapp")

config get("host") println           // localhost
config get("database") get("driver") println  // postgresql
```

## HTML Builder DSL

A more complex example - generating HTML:

```io
HTML := Object clone

// Handle any tag name via forward
HTML forward := method(
    tagName := call message name
    attributes := Map clone
    children := list()
    
    // Process arguments
    call message arguments foreach(arg,
        argValue := call sender doMessage(arg)
        
        if(argValue type == "Map",
            // It's attributes
            attributes = argValue
        ,
            // It's content or children
            if(argValue type == "Sequence",
                children append(argValue),
                if(argValue type == "List",
                    children appendSeq(argValue),
                    children append(argValue asString)
                )
            )
        )
    )
    
    // Build HTML
    result := "<" .. tagName
    attributes foreach(key, value,
        result = result .. " " .. key .. "=\"" .. value .. "\""
    )
    
    if(children size == 0,
        result = result .. " />",
        result = result .. ">"
        children foreach(child, result = result .. child)
        result = result .. "</" .. tagName .. ">"
    )
    
    result
)

// Helper for attributes
Object attrs := method(
    args := call message arguments
    map := Map clone
    
    args foreach(arg,
        pair := arg name split(":")
        if(pair size == 2,
            map atPut(pair at(0), call sender doMessage(arg arguments at(0)))
        )
    )
    map
)

// Usage
html := HTML clone

page := html div(attrs(class: "container", id: "main"),
    html h1("Welcome to My Site"),
    html p(attrs(class: "intro"), 
        "This is a paragraph with ",
        html strong("bold text"),
        " in it."
    ),
    html ul(
        html li("First item"),
        html li("Second item"),
        html li("Third item")
    )
)

page println
// <div class="container" id="main"><h1>Welcome to My Site</h1>...
```

## SQL Query Builder

```io
Query := Object clone
Query init := method(
    self selections := list("*")
    self tables := list()
    self conditions := list()
    self joins := list()
    self
)

Query select := method(
    self selections = call message arguments map(arg,
        call sender doMessage(arg) asString
    )
    self
)

Query from := method(table,
    tables append(table)
    self
)

Query where := method(
    condition := call argAt(0)
    conditions append(condition code asString)
    self
)

Query join := method(table, on,
    joins append("JOIN " .. table .. " ON " .. on code asString)
    self
)

Query toSQL := method(
    sql := "SELECT " .. selections join(", ")
    sql = sql .. " FROM " .. tables join(", ")
    
    if(joins size > 0,
        sql = sql .. " " .. joins join(" ")
    )
    
    if(conditions size > 0,
        sql = sql .. " WHERE " .. conditions join(" AND ")
    )
    
    sql
)

// Usage
query := Query clone init

sql := query select("name", "age", "email") \
            from("users") \
            join("profiles", users.id == profiles.user_id) \
            where(age > 18) \
            where(status == "active") \
            toSQL

sql println
// SELECT name, age, email FROM users JOIN profiles ON users.id == profiles.user_id WHERE age > 18 AND status == "active"
```

## Unit Testing DSL

```io
TestSuite := Object clone
TestSuite tests := list()
TestSuite currentTest := nil

TestSuite describe := method(description,
    suite := TestSuite clone
    suite description := description
    suite tests = list()
    
    # Execute the test definition block
    call evalArgAt(1)
    
    suite
)

TestSuite it := method(testName,
    test := Object clone
    test name := testName
    test block := call argAt(1)
    tests append(test)
)

TestSuite before := method(
    self beforeBlock := call argAt(0)
)

TestSuite after := method(
    self afterBlock := call argAt(0)
)

TestSuite run := method(
    ("\n" .. description) println
    ("=" repeated(description size)) println
    
    passed := 0
    failed := 0
    
    tests foreach(test,
        if(hasSlot("beforeBlock"), beforeBlock doInContext(self))
        
        e := try(
            test block doInContext(self)
            ("✓ " .. test name) println
            passed = passed + 1
        ) catch(Exception, e,
            ("✗ " .. test name) println
            ("  " .. e message) println
            failed = failed + 1
        )
        
        if(hasSlot("afterBlock"), afterBlock doInContext(self))
    )
    
    ("\nPassed: " .. passed .. ", Failed: " .. failed) println
)

// Assertion helpers
Object expect := method(actual,
    Expectation clone setActual(actual)
)

Expectation := Object clone
Expectation setActual := method(value,
    self actual := value
    self
)

Expectation toBe := method(expected,
    if(actual != expected,
        Exception raise("Expected " .. expected .. " but got " .. actual)
    )
)

Expectation toEqual := method(expected,
    if(actual != expected,
        Exception raise("Expected " .. expected .. " but got " .. actual)
    )
)

Expectation toContain := method(item,
    if(actual contains(item) not,
        Exception raise("Expected " .. actual .. " to contain " .. item)
    )
)

// Usage
MathTests := describe("Math operations",
    before(
        self calculator := Object clone
        calculator add := method(a, b, a + b)
        calculator multiply := method(a, b, a * b)
    )
    
    it("should add numbers correctly",
        expect(calculator add(2, 3)) toBe(5)
        expect(calculator add(-1, 1)) toBe(0)
    )
    
    it("should multiply numbers correctly",
        expect(calculator multiply(3, 4)) toBe(12)
        expect(calculator multiply(0, 5)) toBe(0)
    )
    
    it("should handle edge cases",
        expect(calculator add(0, 0)) toBe(0)
    )
)

MathTests run
```

## State Machine DSL

```io
StateMachine := Object clone
StateMachine states := Map clone
StateMachine currentState := nil
StateMachine initialState := nil

StateMachine state := method(name,
    s := State clone
    s name := name
    s machine := self
    states atPut(name, s)
    
    if(initialState isNil, initialState = s)
    
    s
)

State := Object clone
State transitions := Map clone

State on := method(event, targetState,
    transitions atPut(event, targetState)
    self
)

State enter := method(
    self enterBlock := call argAt(0)
    self
)

State exit := method(
    self exitBlock := call argAt(0)
    self
)

StateMachine start := method(
    currentState = initialState
    if(currentState hasSlot("enterBlock"),
        currentState enterBlock call
    )
)

StateMachine trigger := method(event,
    if(currentState transitions hasKey(event),
        nextStateName := currentState transitions at(event)
        nextState := states at(nextStateName)
        
        if(currentState hasSlot("exitBlock"),
            currentState exitBlock call
        )
        
        ("Transitioning from " .. currentState name .. " to " .. nextStateName) println
        currentState = nextState
        
        if(currentState hasSlot("enterBlock"),
            currentState enterBlock call
        )
    ,
        ("No transition for event '" .. event .. "' from state '" .. currentState name .. "'") println
    )
)

// Usage
door := StateMachine clone

door state("closed") \
    on("open", "opened") \
    on("lock", "locked") \
    enter(block("Door is now closed" println))

door state("opened") \
    on("close", "closed") \
    enter(block("Door is now open" println))

door state("locked") \
    on("unlock", "closed") \
    enter(block("Door is now locked" println))

door start
door trigger("open")   // Transitioning from closed to opened
door trigger("close")  // Transitioning from opened to closed
door trigger("lock")   // Transitioning from closed to locked
door trigger("open")   // No transition for event 'open' from state 'locked'
```

## Routing DSL (Web Framework Style)

```io
Router := Object clone
Router routes := list()

Router get := method(path,
    addRoute("GET", path, call argAt(1))
)

Router post := method(path,
    addRoute("POST", path, call argAt(1))
)

Router put := method(path,
    addRoute("PUT", path, call argAt(1))
)

Router delete := method(path,
    addRoute("DELETE", path, call argAt(1))
)

Router addRoute := method(method, path, handler,
    routes append(Map with(
        "method", method,
        "path", path,
        "pattern", pathToRegex(path),
        "handler", handler
    ))
    self
)

Router pathToRegex := method(path,
    // Convert :param to regex groups
    pattern := path
    pattern = pattern replaceAllRegex(":([^/]+)", "([^/]+)")
    "^" .. pattern .. "$"
)

Router handle := method(method, path,
    routes foreach(route,
        if(route at("method") == method,
            match := path matchesRegex(route at("pattern"))
            if(match,
                params := extractParams(route at("path"), path, match)
                return route at("handler") call(params)
            )
        )
    )
    
    Map with("status", 404, "body", "Not Found")
)

Router extractParams := method(pattern, path, match,
    params := Map clone
    
    // Extract named parameters
    names := pattern allMatchesOfRegex(":([^/]+)") map(m, m at(1))
    names foreach(i, name,
        params atPut(name, match at(i + 1))
    )
    
    params
)

// Usage
app := Router clone

app get("/", block(params,
    Map with("status", 200, "body", "Welcome to the home page")
))

app get("/users/:id", block(params,
    Map with("status", 200, "body", "User " .. params at("id"))
))

app post("/users", block(params,
    Map with("status", 201, "body", "User created")
))

// Simulate requests
app handle("GET", "/") at("body") println        // Welcome to the home page
app handle("GET", "/users/123") at("body") println  // User 123
app handle("POST", "/users") at("body") println  // User created
app handle("GET", "/unknown") at("body") println // Not Found
```

## Data Validation DSL

```io
Validator := Object clone

Validator field := method(name,
    f := Field clone
    f name := name
    f rules := list()
    self currentField := f
    f
)

Field := Object clone

Field required := method(
    rules append(block(value,
        if(value isNil or value == "",
            Exception raise(name .. " is required"),
            true
        )
    ))
    self
)

Field minLength := method(min,
    rules append(block(value,
        if(value size < min,
            Exception raise(name .. " must be at least " .. min .. " characters"),
            true
        )
    ))
    self
)

Field maxLength := method(max,
    rules append(block(value,
        if(value size > max,
            Exception raise(name .. " must be at most " .. max .. " characters"),
            true
        )
    ))
    self
)

Field matches := method(regex,
    rules append(block(value,
        if(value matchesRegex(regex) not,
            Exception raise(name .. " has invalid format"),
            true
        )
    ))
    self
)

Field validate := method(value,
    rules foreach(rule,
        rule call(value)
    )
    true
)

// Usage
userValidator := Validator clone

username := userValidator field("username") \
    required \
    minLength(3) \
    maxLength(20) \
    matches("^[a-zA-Z0-9_]+$")

email := userValidator field("email") \
    required \
    matches("^[^@]+@[^@]+\\.[^@]+$")

// Test validation
try(
    username validate("ab")
) catch(Exception, e,
    e message println  // username must be at least 3 characters
)

try(
    email validate("not-an-email")
) catch(Exception, e,
    e message println  // email has invalid format
)

username validate("valid_user123") println  // true
email validate("user@example.com") println  // true
```

## DSL Best Practices

### 1. Natural Language Flow

```io
// Good - reads naturally
recipe needs(2) cups of("flour")
order shipping priority within(3) days

// Bad - programmer-centric
recipe setAmount(2) setUnit("cups") setIngredient("flour")
order setShipping("priority") setDeliveryDays(3)
```

### 2. Method Chaining

```io
// Enable fluent interfaces
Object withChaining := method(
    call message arguments foreach(arg,
        slotName := arg name
        self setSlot(slotName, call evalArgAt(0))
    )
    self  // Always return self
)

Person := Object clone
Person configure := method(
    withChaining(
        name(n, self name := n),
        age(a, self age := a),
        email(e, self email := e)
    )
)

person := Person clone configure \
    name("Alice") \
    age(30) \
    email("alice@example.com")
```

### 3. Context Management

```io
DSLContext := Object clone
DSLContext stack := list()

DSLContext push := method(obj,
    stack append(obj)
)

DSLContext pop := method(
    stack pop
)

DSLContext current := method(
    stack last
)

DSLContext with := method(obj, block,
    push(obj)
    e := try(result := block call)
    pop
    if(e, e raise, result)
)

// Usage in DSL
Form := Object clone
Form fields := list()

Form field := method(name,
    f := Field clone
    f name := name
    DSLContext with(f,
        call evalArgAt(1)
    )
    fields append(f)
)

Field label := method(text,
    DSLContext current label := text
)
```

## Exercises

1. **CSS DSL**: Create a DSL for generating CSS with nested rules and variables.

2. **Graph Description Language**: Build a DSL for describing graphs and their relationships.

3. **Build System DSL**: Implement a make/rake-like build system DSL.

4. **BDD Testing DSL**: Create a Behavior-Driven Development testing framework.

5. **Configuration Management**: Build a DSL for system configuration management.

## Real-World Example: Migration DSL

```io
Migration := Object clone
Migration changes := list()

Migration createTable := method(name,
    table := TableDefinition clone
    table name := name
    table columns := list()
    
    call evalArgAt(1)
    
    changes append(Map with(
        "type", "createTable",
        "table", table
    ))
    self
)

Migration dropTable := method(name,
    changes append(Map with(
        "type", "dropTable",
        "name", name
    ))
    self
)

TableDefinition := Object clone

TableDefinition column := method(name, type,
    columns append(Map with(
        "name", name,
        "type", type,
        "constraints", list()
    ))
    self
)

TableDefinition primaryKey := method(col,
    columns last at("constraints") append("PRIMARY KEY")
    self
)

TableDefinition notNull := method(
    columns last at("constraints") append("NOT NULL")
    self
)

TableDefinition unique := method(
    columns last at("constraints") append("UNIQUE")
    self
)

Migration toSQL := method(
    sql := list()
    
    changes foreach(change,
        if(change at("type") == "createTable",
            table := change at("table")
            stmt := "CREATE TABLE " .. table name .. " (\n"
            
            cols := table columns map(col,
                "  " .. col at("name") .. " " .. col at("type") .. 
                if(col at("constraints") size > 0,
                    " " .. col at("constraints") join(" "),
                    ""
                )
            )
            
            stmt = stmt .. cols join(",\n") .. "\n);"
            sql append(stmt)
        )
        
        if(change at("type") == "dropTable",
            sql append("DROP TABLE " .. change at("name") .. ";")
        )
    )
    
    sql join("\n\n")
)

// Usage
migration := Migration clone

migration createTable("users",
    column("id", "INTEGER") primaryKey,
    column("username", "VARCHAR(50)") notNull unique,
    column("email", "VARCHAR(100)") notNull unique,
    column("created_at", "TIMESTAMP") notNull
)

migration createTable("posts",
    column("id", "INTEGER") primaryKey,
    column("user_id", "INTEGER") notNull,
    column("title", "VARCHAR(200)") notNull,
    column("content", "TEXT"),
    column("published_at", "TIMESTAMP")
)

migration toSQL println
```

## Conclusion

Domain-Specific Languages in Io demonstrate the language's expressive power. By leveraging message passing, optional parentheses, method chaining, and metaprogramming, you can create DSLs that feel natural to domain experts while remaining fully integrated with the host language.

The key to successful DSLs in Io is understanding that you're not fighting against language syntax—you're working with it. Messages become domain commands, objects become domain concepts, and the minimal syntax stays out of your way. This makes Io ideal for creating internal DSLs that are both powerful and readable.

---

