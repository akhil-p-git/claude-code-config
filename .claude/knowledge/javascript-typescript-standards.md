# JavaScript/TypeScript Standards

> Reference guide for JS/TS development. Loaded as needed by Claude Code.

---

## General Rules

- **Always use TypeScript** for new projects
- **Strict mode:** `"strict": true` in tsconfig.json
- **Formatting:** Prettier with 2-space indentation
- **Linting:** ESLint with recommended rules

## Import Order

Organize imports in this order:
1. External libraries (`react`, `lodash`, etc.)
2. Internal modules (`@/lib`, `@/utils`)
3. Relative imports (`./`, `../`)
4. Types (`type { ... }`)

```typescript
// Example
import React from 'react'
import { useState } from 'react'
import axios from 'axios'

import { api } from '@/lib/api'
import { formatDate } from '@/utils/date'

import { Button } from './Button'
import { Modal } from '../Modal'

import type { User, Post } from '@/types'
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables | `camelCase` | `userName`, `isActive` |
| Functions | `camelCase` | `getUserById`, `calculateTotal` |
| Classes | `PascalCase` | `UserService`, `ApiClient` |
| React Components | `PascalCase` | `UserProfile`, `NavBar` |
| Constants | `UPPER_SNAKE_CASE` | `API_URL`, `MAX_RETRIES` |
| Interfaces | `PascalCase` | `User`, `ApiResponse` |
| Type Aliases | `PascalCase` | `UserId`, `HttpMethod` |
| Enums | `PascalCase` | `UserRole`, `Status` |
| Enum Values | `PascalCase` | `UserRole.Admin` |

## TypeScript Best Practices

### Prefer Interfaces for Objects
```typescript
// GOOD - Use interface for object shapes
interface User {
  id: string
  name: string
  email: string
}

// GOOD - Use type for unions, primitives, computed types
type Status = 'pending' | 'active' | 'inactive'
type UserId = string
type UserWithPosts = User & { posts: Post[] }
```

### Use Discriminated Unions
```typescript
// GOOD - Type-safe state handling
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }
```

### Avoid `any`
```typescript
// BAD
function parse(data: any) { ... }

// GOOD - Use unknown and narrow
function parse(data: unknown) {
  if (typeof data === 'string') {
    return JSON.parse(data)
  }
  throw new Error('Expected string')
}
```

### Use `as const` for Literal Types
```typescript
// Creates readonly tuple with literal types
const ROLES = ['admin', 'user', 'guest'] as const
type Role = typeof ROLES[number] // 'admin' | 'user' | 'guest'
```

## Error Handling

```typescript
// Custom error classes
class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code: string
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

// Type-safe error handling
async function fetchUser(id: string): Promise<User> {
  try {
    const response = await api.get(`/users/${id}`)
    return response.data
  } catch (error) {
    if (error instanceof ApiError) {
      // Handle API errors
      console.error(`API Error ${error.code}: ${error.message}`)
    }
    throw error
  }
}
```

## Async/Await Patterns

```typescript
// GOOD - Parallel operations
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchPosts(id)
])

// GOOD - Error handling with Promise.allSettled
const results = await Promise.allSettled([
  fetchUser(id),
  fetchPosts(id)
])

results.forEach((result, index) => {
  if (result.status === 'fulfilled') {
    console.log(`Success ${index}:`, result.value)
  } else {
    console.error(`Failed ${index}:`, result.reason)
  }
})
```

## Zod Validation

```typescript
import { z } from 'zod'

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().positive().optional(),
  role: z.enum(['admin', 'user', 'guest'])
})

type User = z.infer<typeof UserSchema>

// Validate and parse
function parseUser(data: unknown): User {
  return UserSchema.parse(data)
}
```

---

## Quick Checklist

- [ ] TypeScript strict mode enabled
- [ ] No `any` types (use `unknown` + narrowing)
- [ ] Imports organized correctly
- [ ] Consistent naming conventions
- [ ] Error handling with custom error classes
- [ ] Parallel async when possible
- [ ] Input validation with Zod
