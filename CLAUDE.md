# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive book about the Io Programming Language, written in Markdown format with one file per chapter. The book targets experienced programmers and provides in-depth comparisons with mainstream languages like JavaScript, Python, Ruby, and Java.

## Repository Structure

- **Root directory**: Contains 19 Markdown files (chapters 00-18) that make up the book
- **examples/**: Runnable Io code examples organized by chapter
  - Each chapter subdirectory contains `.io` files demonstrating concepts from that chapter
  - Examples can be run with: `io examples/chapter-XX/filename.io`

## Commands

### Running Io Code Examples
```bash
# Run any example file
io examples/chapter-02/hello.io

# Run Io REPL for interactive exploration
io
```

### Working with the Book Content
The book is written entirely in Markdown. Each chapter is a standalone `.md` file numbered sequentially (00-preface.md through 18-conclusion.md).

## Code Architecture

This is a documentation/book project, not a software application. The structure is:

1. **Book Content**: Individual Markdown files for each chapter containing:
   - Conceptual explanations
   - Code examples (inline in Markdown)
   - Comparisons to Python, JavaScript, Ruby, and Java
   - Exercises and "Try This" sections

2. **Example Code**: Standalone `.io` files in the `examples/` directory that readers can run to follow along with the book

## Key Considerations

- When editing chapters, maintain consistency in:
  - Code example formatting (use ```io code blocks)
  - Comparison style with other languages
  - Progressive building of concepts from earlier chapters
  
- When creating new Io examples:
  - Place them in the appropriate `examples/chapter-XX/` directory
  - Ensure they are self-contained and runnable
  - Include comments explaining key concepts

- The book emphasizes prototype-based programming concepts and frequently contrasts Io with class-based languages to help readers understand the paradigm shift

## Language Context

Io is:
- A prototype-based object-oriented language (like JavaScript's prototype system)
- Dynamically typed
- Homoiconic (code is data)
- Message-passing based
- Uses differential inheritance through cloning

Common Io patterns seen in examples:
- Everything is an object receiving messages
- Methods are defined as slots: `Object methodName := method(...)`
- Cloning for inheritance: `Child := Parent clone`
- Blocks for closures: `block(x, x * 2)`