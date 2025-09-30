#!/usr/bin/env io
# Simple To-Do List Manager from Chapter 2

TodoList := Object clone
TodoList items := list()

TodoList add := method(task,
    items append(task)
    self
)

TodoList show := method(
    if(items size == 0,
        "No tasks!" println,
        items foreach(i, task,
            ("  " .. (i + 1) .. ". " .. task) println
        )
    )
    self
)

TodoList complete := method(index,
    if(index > 0 and index <= items size,
        task := items at(index - 1)
        items removeAt(index - 1)
        ("Completed: " .. task) println,
        "Invalid task number" println
    )
    self
)

# Usage
todo := TodoList clone
todo add("Learn Io") add("Build something cool") add("Share with friends")

"=== My Todo List ===" println
todo show

todo complete(1)

"=== Updated List ===" println
todo show