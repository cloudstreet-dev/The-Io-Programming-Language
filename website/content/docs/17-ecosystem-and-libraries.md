---
title: "Ecosystem and Libraries"
weight: 180
---



# Chapter 17: Ecosystem and Libraries

While Io has a smaller ecosystem compared to mainstream languages, it offers a thoughtfully curated set of libraries and tools. This chapter explores the available resources, how to use them effectively, and how to contribute to the Io ecosystem.

## Core Libraries

Io comes with several built-in libraries that extend its capabilities:

### File I/O and System

```io
// File operations
file := File with("data.txt")

// Reading
if(file exists,
    contents := file contents
    lines := file readLines
    
    // Read with encoding
    file setEncoding("UTF-8")
    text := file contents
)

// Writing
file openForWriting
file write("Hello, World!\n")
file write("Line 2\n")
file close

// Appending
file openForAppending
file write("Additional line\n")
file close

// File information
file size println
file lastModified println
file isDirectory println

// Directory operations
dir := Directory with("./src")
dir files foreach(file,
    file name println
)

dir directories foreach(subdir,
    subdir path println
)

// Recursive directory walking
dir recursiveFilesOfType("io") foreach(ioFile,
    ioFile path println
)

// System operations
System system("ls -la")  // Execute shell command
System getEnvironmentVariable("HOME") println
System setEnvironmentVariable("MY_VAR", "value")
System exit(0)
```

### Networking

```io
// HTTP Client
url := URL with("https://api.example.com/data")
url fetch println  // Simple GET request

// With headers
url setHeader("Authorization", "Bearer token")
url setHeader("Content-Type", "application/json")
response := url fetch

// POST request
url setMethod("POST")
url setBody("{\"key\": \"value\"}")
response := url fetch

// Socket programming
// Server
server := Socket clone
server setHost("127.0.0.1")
server setPort(8080)
server bind
server listen

loop(
    client := server accept
    @(
        data := client readUntilSeq("\n")
        client write("Echo: " .. data)
        client close
    )
)

// Client
client := Socket clone
client setHost("127.0.0.1")
client setPort(8080)
client connect
client write("Hello, server!\n")
response := client readUntilSeq("\n")
response println
client close
```

### Date and Time

```io
// Current date/time
now := Date now
now println

// Date components
now year println
now month println
now day println
now hour println
now minute println
now second println

// Date arithmetic
tomorrow := now + Duration days(1)
nextWeek := now + Duration weeks(1)
hourAgo := now - Duration hours(1)

// Formatting
now asString("%Y-%m-%d %H:%M:%S") println
now asString("%B %d, %Y") println

// Parsing
date := Date fromString("2024-01-15", "%Y-%m-%d")

// Duration
duration := Duration clone
duration setDays(2) setHours(3) setMinutes(30)
duration asSeconds println

// Timing code
start := Date now
// ... code to time ...
elapsed := Date now - start
("Elapsed: " .. elapsed) println
```

### Regular Expressions

```io
// Basic matching
text := "The year 2024 has 365 days"
text matchesRegex("\\d+") println  // true

// Finding matches
match := text findRegex("\\d+")
match start println  // Starting position
match end println    // Ending position
match string println // Matched string

// All matches
matches := text allMatchesOfRegex("\\d+")
matches foreach(m,
    m string println  // 2024, 365
)

// Replacement
result := text replaceFirstRegex("\\d+", "N")
result println  // The year N has 365 days

result := text replaceAllRegex("\\d+", "N")
result println  // The year N has N days

// Capture groups
email := "user@example.com"
pattern := "(\\w+)@([\\w.]+)"
if(match := email matchesOfRegex(pattern),
    match at(1) println  // user
    match at(2) println  // example.com
)

// Compiling regex for reuse
regex := Regex with("\\b\\w{5}\\b")  // 5-letter words
regex matches("hello") println  // true
regex matches("hi") println     // false
```

### JSON

```io
// Parsing JSON
jsonString := """
{
    "name": "Alice",
    "age": 30,
    "interests": ["coding", "music"],
    "address": {
        "city": "New York",
        "zip": "10001"
    }
}
"""

data := jsonString parseJson
data at("name") println  // Alice
data at("interests") at(0) println  // coding
data at("address") at("city") println  // New York

// Creating JSON
person := Map with(
    "name", "Bob",
    "age", 25,
    "active", true,
    "tags", list("developer", "gamer")
)

json := person asJson
json println  // {"name":"Bob","age":25,"active":true,"tags":["developer","gamer"]}

// Pretty printing
json := person asJson(true)  // Pretty format
```

### XML

```io
// Parsing XML
xmlString := """
<root>
    <person id="1">
        <name>Alice</name>
        <age>30</age>
    </person>
    <person id="2">
        <name>Bob</name>
        <age>25</age>
    </person>
</root>
"""

doc := SGML parseString(xmlString)
root := doc root

// Navigate XML
people := root elementsWithName("person")
people foreach(person,
    id := person attributeAt("id")
    name := person elementWithName("name") text
    age := person elementWithName("age") text
    (id .. ": " .. name .. " (" .. age .. ")") println
)

// Build XML
doc := SGML clone
root := doc addElement("catalog")

book := root addElement("book")
book setAttribute("isbn", "123456")
book addElement("title") setText("Io Programming")
book addElement("author") setText("Jane Doe")
book addElement("price") setText("29.99")

doc asString println
```

## Addon System

Io's addon system allows loading C-based extensions:

```io
// Loading addons
Addon load("Socket")   // Network programming
Addon load("Random")   // Random number generation
Addon load("Regex")    // Regular expressions
Addon load("SQLite")   // Database access

// Check available addons
Addon availableAddons foreach(name,
    name println
)

// Addon information
addon := Addon named("Socket")
addon path println
addon dependencies println
```

## Database Libraries

### SQLite

```io
// SQLite integration
db := SQLite clone
db open("app.db")

// Create table
db exec("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
""")

// Insert data
stmt := db prepare("INSERT INTO users (name, email) VALUES (?, ?)")
stmt bind(1, "Alice")
stmt bind(2, "alice@example.com")
stmt step
stmt reset

// Query data
results := db exec("SELECT * FROM users WHERE name LIKE 'A%'")
results foreach(row,
    ("ID: " .. row at("id") .. ", Name: " .. row at("name")) println
)

// Prepared statements with results
stmt := db prepare("SELECT * FROM users WHERE id = ?")
stmt bind(1, 1)

while(stmt step == SQLite ROW,
    name := stmt columnText(1)
    email := stmt columnText(2)
    (name .. " - " .. email) println
)

stmt finalize
db close

// Transactions
db begin
try(
    db exec("INSERT INTO users ...")
    db exec("UPDATE users ...")
    db commit
) catch(Exception, e,
    db rollback
    e raise
)
```

## Graphics and GUI

### OpenGL

```io
// OpenGL addon (if available)
Addon load("OpenGL")

// Basic window setup
window := GLApp clone
window width := 800
window height := 600
window title := "Io OpenGL"

window draw := method(
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    
    glBegin(GL_TRIANGLES)
    glColor3f(1, 0, 0)
    glVertex2f(-0.5, -0.5)
    glColor3f(0, 1, 0)
    glVertex2f(0.5, -0.5)
    glColor3f(0, 0, 1)
    glVertex2f(0, 0.5)
    glEnd
    
    swapBuffers
)

window run
```

### Image Processing

```io
// Image addon
Addon load("Image")

// Load and manipulate images
img := Image clone
img open("photo.jpg")

// Get information
img width println
img height println
img componentCount println  // Color channels

// Basic operations
img resize(800, 600)
img crop(100, 100, 400, 300)
img flip("horizontal")
img rotate(90)

// Filters
img blur(5)
img sharpen
img adjustBrightness(1.2)
img adjustContrast(1.5)
img grayscale

// Save
img save("modified.png")

// Create new image
canvas := Image clone
canvas allocate(500, 500, 3)  // RGB
canvas fill(Color with(0.5, 0.5, 1.0))  // Light blue

// Draw on image
canvas drawLine(0, 0, 500, 500, Color red)
canvas drawCircle(250, 250, 100, Color green)
canvas drawRectangle(100, 100, 300, 200, Color blue)

canvas save("drawing.png")
```

## Cryptography

```io
// Crypto addon
Addon load("MD5")
Addon load("SHA1")

// Hashing
text := "Hello, World!"

md5 := MD5 clone
md5 appendSeq(text)
md5 hexDigest println  // MD5 hash

sha := SHA1 clone
sha appendSeq(text)
sha hexDigest println  // SHA1 hash

// File hashing
file := File with("document.pdf")
hash := MD5 hashFile(file path)
hash println

// HMAC (if available)
key := "secret-key"
message := "Important message"
hmac := HMAC sha256(key, message)
hmac println
```

## Third-Party Libraries

### Package Management

While Io doesn't have a centralized package manager like npm or pip, libraries can be managed through:

```io
// Simple package loader
PackageLoader := Object clone
PackageLoader paths := list(
    "~/.io/packages",
    "/usr/local/io/packages",
    "./packages"
)

PackageLoader load := method(name,
    paths foreach(path,
        packageFile := Path with(path, name, "init.io")
        if(File with(packageFile) exists,
            doFile(packageFile)
            return true
        )
    )
    Exception raise("Package not found: " .. name)
)

// Usage
PackageLoader load("web-framework")
PackageLoader load("test-framework")
```

### Creating Libraries

Structure for an Io library:

```io
// mylib/init.io - Entry point
MyLib := Object clone
MyLib version := "1.0.0"

// Load components
doRelativeFile("core.io")
doRelativeFile("utils.io")
doRelativeFile("extensions.io")

// Export public API
MyLib

// mylib/core.io
MyLib Core := Object clone
MyLib Core process := method(data,
    // Core functionality
)

// mylib/utils.io
MyLib Utils := Object clone
MyLib Utils helper := method(
    // Utility functions
)

// mylib/extensions.io
// Extend built-in types
List customMethod := method(
    // Extended functionality
)
```

### Testing Frameworks

Simple testing framework example:

```io
// SimpleTest framework
Test := Object clone
Test suites := list()

Test describe := method(name, block,
    suite := TestSuite clone
    suite name := name
    suite tests := list()
    
    suite it := method(desc, testBlock,
        tests append(list(desc, testBlock))
    )
    
    block call(suite)
    suites append(suite)
)

Test run := method(
    totalTests := 0
    passedTests := 0
    
    suites foreach(suite,
        ("\n" .. suite name) println
        ("=" repeated(suite name size)) println
        
        suite tests foreach(test,
            desc := test at(0)
            block := test at(1)
            totalTests = totalTests + 1
            
            e := try(
                block call
                ("  ✓ " .. desc) println
                passedTests = passedTests + 1
            ) catch(Exception, e,
                ("  ✗ " .. desc) println
                ("    " .. e message) println
            )
        )
    )
    
    ("\n" .. passedTests .. "/" .. totalTests .. " tests passed") println
)

// Usage
Test describe("Array operations", suite,
    suite it("should append elements", 
        arr := list(1, 2)
        arr append(3)
        assert(arr size == 3)
    )
    
    suite it("should remove elements",
        arr := list(1, 2, 3)
        arr remove(2)
        assert(arr contains(2) not)
    )
)

Test run
```

## Documentation Tools

### Generating Documentation

```io
// Simple documentation generator
DocGen := Object clone
DocGen init := method(
    self docs := Map clone
    self
)

DocGen document := method(obj, name,
    info := Map clone
    info atPut("name", name)
    info atPut("type", obj type)
    info atPut("slots", obj slotNames sort)
    
    // Extract method signatures
    methods := Map clone
    obj slotNames foreach(slotName,
        slot := obj getSlot(slotName)
        if(slot type == "Block",
            methods atPut(slotName, slot argumentNames)
        )
    )
    info atPut("methods", methods)
    
    docs atPut(name, info)
    self
)

DocGen generateMarkdown := method(
    md := "# API Documentation\n\n"
    
    docs foreach(name, info,
        md = md .. "## " .. name .. "\n\n"
        md = md .. "**Type**: " .. info at("type") .. "\n\n"
        
        methods := info at("methods")
        if(methods size > 0,
            md = md .. "### Methods\n\n"
            methods foreach(method, args,
                md = md .. "- `" .. method .. "(" .. args join(", ") .. ")`\n"
            )
            md = md .. "\n"
        )
    )
    
    md
)

// Usage
docGen := DocGen clone init
docGen document(MyClass, "MyClass")
docGen document(MyUtils, "MyUtils")

File with("API.md") openForWriting write(docGen generateMarkdown) close
```

## Development Tools

### REPL Enhancements

```io
// Enhanced REPL
REPL := Object clone
REPL history := list()
REPL commands := Map clone

REPL registerCommand := method(name, block,
    commands atPut(name, block)
)

REPL run := method(
    loop(
        "io> " print
        input := File standardInput readLine
        
        if(input beginsWithSeq(":"),
            // Handle commands
            cmd := input afterSeq(":")
            if(commands hasKey(cmd),
                commands at(cmd) call,
                ("Unknown command: " .. cmd) println
            ),
            // Evaluate Io code
            history append(input)
            e := try(
                result := doString(input)
                ("==> " .. result) println
            ) catch(Exception, e,
                ("Error: " .. e message) println
            )
        )
    )
)

// Register commands
REPL registerCommand("help", block(
    "Available commands:" println
    commands keys foreach(cmd,
        ("  :" .. cmd) println
    )
))

REPL registerCommand("history", block(
    history foreach(i, line,
        (i .. ": " .. line) println
    )
))

REPL registerCommand("clear", block(
    System system("clear")
))

REPL registerCommand("quit", block(
    System exit
))

// Run enhanced REPL
REPL run
```

### Debugging Tools

```io
// Simple debugger
Debugger := Object clone
Debugger breakpoints := list()
Debugger stepping := false

Object debug := method(
    Debugger enter(self, call)
)

Debugger enter := method(context, callObj,
    "=== Debugger ===" println
    ("Context: " .. context type) println
    ("Location: " .. callObj message) println
    
    loop(
        "> " print
        cmd := File standardInput readLine split(" ")
        
        if(cmd at(0) == "inspect",
            target := cmd at(1)
            if(target,
                obj := context doString(target)
                obj slotNames foreach(slot,
                    ("  " .. slot .. ": " .. obj getSlot(slot) type) println
                )
            )
        )
        
        if(cmd at(0) == "eval",
            code := cmd slice(1) join(" ")
            result := context doString(code)
            result println
        )
        
        if(cmd at(0) == "continue",
            break
        )
        
        if(cmd at(0) == "help",
            "Commands: inspect <obj>, eval <code>, continue, help" println
        )
    )
)
```

## Community Resources

### Finding Libraries

Common sources for Io libraries:

1. **GitHub**: Search for "io-language" or "iolanguage" topics
2. **Official Repository**: https://github.com/IoLanguage/io
3. **Community Addons**: Various developers maintain addon collections

### Contributing

Creating an addon for the community:

```io
// addon.io - Addon metadata
Addon := Object clone
Addon name := "MyAddon"
Addon version := "1.0.0"
Addon author := "Your Name"
Addon description := "Description of what your addon does"
Addon license := "MIT"
Addon dependencies := list("OtherAddon")

Addon install := method(
    // Installation logic
    "Installing " .. name .. " v" .. version println
    
    // Copy files
    // Compile C extensions if needed
    // Register with Io
)

Addon uninstall := method(
    // Cleanup logic
)

// Make addon discoverable
Addon register
```

## Performance Libraries

### Profiling

```io
// Simple profiler
Profiler := Object clone
Profiler data := Map clone

Object profile := method(name,
    start := Date now
    result := call evalArgAt(0)
    elapsed := Date now - start
    
    if(Profiler data hasKey(name) not,
        Profiler data atPut(name, list(0, 0))
    )
    
    stats := Profiler data at(name)
    stats atPut(0, stats at(0) + 1)  // Count
    stats atPut(1, stats at(1) + elapsed)  // Total time
    
    result
)

Profiler report := method(
    "=== Profile Report ===" println
    data foreach(name, stats,
        count := stats at(0)
        total := stats at(1)
        avg := total / count
        
        (name .. ": " .. count .. " calls, " ..
         total .. "s total, " .. avg .. "s average") println
    )
)

// Usage
profile("database",
    // Expensive operation
    wait(0.1)
)

Profiler report
```

## Future of Io Libraries

The Io ecosystem continues to evolve with:

1. **WebAssembly Support**: Potential for running Io in browsers
2. **Modern Addons**: Integration with contemporary libraries
3. **Cloud Services**: AWS, Azure, GCP client libraries
4. **Machine Learning**: Bindings to TensorFlow, PyTorch
5. **Improved Tooling**: Better IDE support, linters, formatters

## Conclusion

While Io's ecosystem is smaller than mainstream languages, it provides essential functionality and excellent extensibility through its addon system. The simplicity of creating libraries, combined with seamless C integration, means that missing functionality can often be added quickly. The community, though small, is knowledgeable and helpful, making it easy to find or create the tools you need.

The key to working effectively with Io's ecosystem is understanding that it favors simplicity and extensibility over having every possible library pre-built. This philosophy encourages developers to understand their tools deeply and create exactly what they need.

---

