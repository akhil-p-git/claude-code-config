---
description: "Node.js backend API development standards"
paths:
  - "**/server/**"
  - "**/api/**"
  - "**/backend/**"
  - "**/routes/**"
  - "**/controllers/**"
  - "**/middleware/**"
  - "**/services/**"
---

# Node.js Backend Standards

Full reference: @knowledge/nodejs-backend-standards.md

## Key Rules
- async/await over callbacks, TypeScript for type safety
- Custom error classes (AppError, NotFoundError, ValidationError)
- Global error handler middleware
- Zod validation on all endpoints
- Environment config validated with Zod schema

## API Design
- RESTful: GET list, POST create, GET/:id read, PUT/:id update, DELETE/:id remove
- Correct HTTP status codes (201 created, 204 no content, 409 conflict)
- Repository pattern for database operations
- `asyncHandler` wrapper to catch errors in routes

## Logging
- Use Pino (not console.log) with structured logging
- Log level from environment config
