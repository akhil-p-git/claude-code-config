---
description: "Testing standards for all languages"
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
  - "**/test/**"
  - "**/__tests__/**"
---

# Testing Standards

Full reference: @knowledge/testing-standards.md

## Requirements
- 80%+ code coverage on new code
- 100% coverage on security-critical code
- Test naming: "should [behavior] when [condition]"

## Test Types
- **Unit**: individual functions/components (Jest, Vitest, pytest)
- **Integration**: API endpoints, DB operations (Supertest, pytest)
- **E2E**: critical user flows (Playwright)

## Key Patterns
- Mock external dependencies, not internal logic
- Use `beforeEach` for test isolation
- Fixtures and factories for test data
- `@testing-library/react` for React components (query by role/label)
- pytest fixtures with proper scope (session, function)
