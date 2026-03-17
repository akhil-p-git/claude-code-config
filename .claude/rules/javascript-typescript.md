---
description: "JavaScript and TypeScript coding standards"
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.mts"
---

# JavaScript/TypeScript Standards

Full reference: @knowledge/javascript-typescript-standards.md

## Key Rules
- Always use TypeScript for new projects with `"strict": true`
- Use `unknown` + narrowing instead of `any`
- Use interfaces for object shapes, types for unions/primitives
- Use `as const` for literal types
- Parallel async: `Promise.all()` for independent operations

## Naming
- `camelCase`: variables, functions
- `PascalCase`: classes, components, interfaces, types, enums
- `UPPER_SNAKE_CASE`: constants

## Import Order
1. External libraries
2. Internal modules (`@/lib`, `@/utils`)
3. Relative imports (`./`, `../`)
4. Types (`type { ... }`)

## Validation
- Use Zod for runtime validation and type inference
