---
description: "C language coding standards"
paths:
  - "**/*.c"
  - "**/*.h"
---

# C Standards

Full reference: @knowledge/c-standards.md

## Key Rules
- K&R style, 4-space indentation, 80-char line width
- ALWAYS check malloc/calloc return values
- ALWAYS free allocated memory
- Initialize pointers to NULL
- Use `goto cleanup` pattern for multi-resource functions

## Naming
- `snake_case`: variables, functions
- `UPPER_SNAKE_CASE`: macros, constants
- `snake_case_t`: typedefs

## Safety
- Use `snprintf` (not `sprintf`), `strncpy` (not `strcpy`)
- Include guards (`#ifndef`) or `#pragma once` in all headers
- Parenthesize all macro parameters
- Use `do { } while(0)` for multi-statement macros
- C99 designated initializers for struct init
