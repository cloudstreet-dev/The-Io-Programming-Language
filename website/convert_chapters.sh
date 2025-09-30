#!/bin/bash

# Part 1: Foundations
echo "---
title: \"Preface\"
weight: 1
---
" > website/content/docs/part-1-foundations/00-preface.md
tail -n +2 00-preface.md >> website/content/docs/part-1-foundations/00-preface.md

echo "---
title: \"Introduction\"
weight: 2
---
" > website/content/docs/part-1-foundations/01-introduction.md
tail -n +2 01-introduction.md >> website/content/docs/part-1-foundations/01-introduction.md

echo "---
title: \"Getting Started\"
weight: 3
---
" > website/content/docs/part-1-foundations/02-getting-started.md
tail -n +2 02-getting-started.md >> website/content/docs/part-1-foundations/02-getting-started.md

# Part 2: Core Concepts
echo "---
title: \"Everything is an Object\"
weight: 4
---
" > website/content/docs/part-2-core-concepts/03-everything-is-an-object.md
tail -n +2 03-everything-is-an-object.md >> website/content/docs/part-2-core-concepts/03-everything-is-an-object.md

echo "---
title: \"Prototypes, Not Classes\"
weight: 5
---
" > website/content/docs/part-2-core-concepts/04-prototypes-not-classes.md
tail -n +2 04-prototypes-not-classes.md >> website/content/docs/part-2-core-concepts/04-prototypes-not-classes.md

echo "---
title: \"Messages and Slots\"
weight: 6
---
" > website/content/docs/part-2-core-concepts/05-messages-and-slots.md
tail -n +2 05-messages-and-slots.md >> website/content/docs/part-2-core-concepts/05-messages-and-slots.md

echo "---
title: \"Cloning and Inheritance\"
weight: 7
---
" > website/content/docs/part-2-core-concepts/06-cloning-and-inheritance.md
tail -n +2 06-cloning-and-inheritance.md >> website/content/docs/part-2-core-concepts/06-cloning-and-inheritance.md

# Part 3: Language Features
echo "---
title: \"Control Flow\"
weight: 8
---
" > website/content/docs/part-3-language-features/07-control-flow.md
tail -n +2 07-control-flow.md >> website/content/docs/part-3-language-features/07-control-flow.md

echo "---
title: \"Collections\"
weight: 9
---
" > website/content/docs/part-3-language-features/08-collections.md
tail -n +2 08-collections.md >> website/content/docs/part-3-language-features/08-collections.md

echo "---
title: \"Blocks and Closures\"
weight: 10
---
" > website/content/docs/part-3-language-features/09-blocks-and-closures.md
tail -n +2 09-blocks-and-closures.md >> website/content/docs/part-3-language-features/09-blocks-and-closures.md

echo "---
title: \"Exceptions\"
weight: 11
---
" > website/content/docs/part-3-language-features/10-exceptions.md
tail -n +2 10-exceptions.md >> website/content/docs/part-3-language-features/10-exceptions.md

# Part 4: Advanced Topics
echo "---
title: \"Metaprogramming\"
weight: 12
---
" > website/content/docs/part-4-advanced-topics/11-metaprogramming.md
tail -n +2 11-metaprogramming.md >> website/content/docs/part-4-advanced-topics/11-metaprogramming.md

echo "---
title: \"Concurrency\"
weight: 13
---
" > website/content/docs/part-4-advanced-topics/12-concurrency.md
tail -n +2 12-concurrency.md >> website/content/docs/part-4-advanced-topics/12-concurrency.md

echo "---
title: \"Domain-Specific Languages\"
weight: 14
---
" > website/content/docs/part-4-advanced-topics/13-domain-specific-languages.md
tail -n +2 13-domain-specific-languages.md >> website/content/docs/part-4-advanced-topics/13-domain-specific-languages.md

echo "---
title: \"C Integration\"
weight: 15
---
" > website/content/docs/part-4-advanced-topics/14-c-integration.md
tail -n +2 14-c-integration.md >> website/content/docs/part-4-advanced-topics/14-c-integration.md

# Part 5: Practical Applications
echo "---
title: \"Real-World Patterns\"
weight: 16
---
" > website/content/docs/part-5-practical-applications/15-real-world-patterns.md
tail -n +2 15-real-world-patterns.md >> website/content/docs/part-5-practical-applications/15-real-world-patterns.md

echo "---
title: \"Case Studies\"
weight: 17
---
" > website/content/docs/part-5-practical-applications/16-case-studies.md
tail -n +2 16-case-studies.md >> website/content/docs/part-5-practical-applications/16-case-studies.md

echo "---
title: \"Ecosystem and Libraries\"
weight: 18
---
" > website/content/docs/part-5-practical-applications/17-ecosystem-and-libraries.md
tail -n +2 17-ecosystem-and-libraries.md >> website/content/docs/part-5-practical-applications/17-ecosystem-and-libraries.md

echo "---
title: \"Conclusion\"
weight: 19
---
" > website/content/docs/part-5-practical-applications/18-conclusion.md
tail -n +2 18-conclusion.md >> website/content/docs/part-5-practical-applications/18-conclusion.md
