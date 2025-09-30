#!/usr/bin/env io
# HTML DSL example from Chapter 13

HTML := Object clone

# Handle any tag name via forward
HTML forward := method(
    tagName := call message name
    attributes := Map clone
    children := list()
    
    # Process arguments
    call message arguments foreach(arg,
        argValue := call sender doMessage(arg)
        
        if(argValue type == "Map",
            attributes = argValue,
            if(argValue type == "Sequence",
                children append(argValue),
                if(argValue type == "List",
                    children appendSeq(argValue),
                    children append(argValue asString)
                )
            )
        )
    )
    
    # Build HTML
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

# Helper for attributes
Object attrs := method(
    map := Map clone
    call message arguments foreach(arg,
        key := arg name
        value := call sender doMessage(arg arguments at(0))
        map atPut(key, value)
    )
    map
)

# Usage example
"\n=== HTML DSL Demo ===" println

html := HTML clone

page := html html(
    html head(
        html title("My Io Website"),
        html meta(attrs(charset: "UTF-8"))
    ),
    html body(attrs(class: "container"),
        html h1("Welcome to Io!"),
        html p(attrs(class: "intro"), 
            "This is a paragraph with ",
            html strong("bold text"),
            " and ",
            html em("italic text"),
            "."
        ),
        html ul(attrs(id: "features"),
            html li("Prototype-based OOP"),
            html li("Everything is an object"),
            html li("Powerful metaprogramming")
        ),
        html footer(
            html p("© 2024 - Built with Io")
        )
    )
)

# Output the generated HTML
page println