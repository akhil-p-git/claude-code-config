# Node.js/Backend Standards

> Reference guide for Node.js backend development. Loaded as needed by Claude Code.

---

## General Rules

- **Use async/await** over callbacks
- **Use TypeScript** for type safety
- **Environment variables** for all configuration
- **Never hardcode** secrets or credentials

## Project Structure

```
backend/
├── src/
│   ├── index.ts              # Entry point
│   ├── app.ts                # Express app setup
│   ├── config/
│   │   └── index.ts          # Configuration loader
│   ├── routes/
│   │   ├── index.ts          # Route aggregator
│   │   └── users.ts          # User routes
│   ├── controllers/
│   │   └── users.ts          # Request handlers
│   ├── services/
│   │   └── users.ts          # Business logic
│   ├── models/
│   │   └── user.ts           # Data models
│   ├── middleware/
│   │   ├── auth.ts           # Authentication
│   │   ├── error.ts          # Error handler
│   │   └── validate.ts       # Validation
│   ├── utils/
│   │   └── logger.ts         # Logging utility
│   └── types/
│       └── index.ts          # Type definitions
├── tests/
├── .env.example
└── package.json
```

## Error Handling

```typescript
// Custom error classes
class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code: string,
    public isOperational = true
  ) {
    super(message)
    this.name = 'AppError'
    Error.captureStackTrace(this, this.constructor)
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`, 404, 'NOT_FOUND')
  }
}

class ValidationError extends AppError {
  constructor(message: string, public errors: Record<string, string>) {
    super(message, 400, 'VALIDATION_ERROR')
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED')
  }
}

// Global error handler middleware
const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err instanceof ValidationError && { errors: err.errors })
      }
    })
  }

  // Log unexpected errors
  console.error('Unexpected error:', err)

  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred'
    }
  })
}
```

## API Structure

```typescript
// RESTful naming conventions
// GET    /users          - List users
// POST   /users          - Create user
// GET    /users/:id      - Get user
// PUT    /users/:id      - Update user (full)
// PATCH  /users/:id      - Update user (partial)
// DELETE /users/:id      - Delete user

// Route definition
import { Router } from 'express'
import { validate } from '../middleware/validate'
import { createUserSchema, updateUserSchema } from '../schemas/user'
import * as userController from '../controllers/user'

const router = Router()

router.get('/', userController.list)
router.post('/', validate(createUserSchema), userController.create)
router.get('/:id', userController.get)
router.put('/:id', validate(updateUserSchema), userController.update)
router.delete('/:id', userController.remove)

export default router
```

## HTTP Status Codes

| Code | Use Case |
|------|----------|
| 200 | Success (GET, PUT, PATCH, DELETE with body) |
| 201 | Created (POST success) |
| 204 | No Content (DELETE success, no body) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid auth) |
| 403 | Forbidden (valid auth, no permission) |
| 404 | Not Found |
| 409 | Conflict (duplicate resource) |
| 422 | Unprocessable Entity (semantic error) |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |

## Input Validation (Zod)

```typescript
import { z } from 'zod'
import { Request, Response, NextFunction } from 'express'

// Schema definitions
const createUserSchema = z.object({
  body: z.object({
    email: z.string().email(),
    name: z.string().min(1).max(100),
    password: z.string().min(8).max(100)
  })
})

const getUserSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  })
})

const listUsersSchema = z.object({
  query: z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    sort: z.enum(['name', 'createdAt']).optional(),
    order: z.enum(['asc', 'desc']).default('asc')
  })
})

// Validation middleware
function validate<T extends z.ZodSchema>(schema: T) {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const validated = await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params
      })
      req.body = validated.body
      req.query = validated.query
      req.params = validated.params
      next()
    } catch (error) {
      if (error instanceof z.ZodError) {
        const errors = error.errors.reduce((acc, err) => {
          acc[err.path.join('.')] = err.message
          return acc
        }, {} as Record<string, string>)
        next(new ValidationError('Validation failed', errors))
      }
      next(error)
    }
  }
}
```

## Environment Configuration

```typescript
// config/index.ts
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),
  REDIS_URL: z.string().url().optional(),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info')
})

export const config = envSchema.parse(process.env)

// .env.example
/*
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/db
JWT_SECRET=your-super-secret-key-at-least-32-chars
JWT_EXPIRES_IN=7d
REDIS_URL=redis://localhost:6379
LOG_LEVEL=info
*/
```

## Async Handler Wrapper

```typescript
// Wrap async route handlers to catch errors
type AsyncHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<any>

const asyncHandler = (fn: AsyncHandler) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next)
  }
}

// Usage
router.get('/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id)
  if (!user) {
    throw new NotFoundError('User', req.params.id)
  }
  res.json(user)
}))
```

## Database Patterns

```typescript
// Repository pattern
class UserRepository {
  async findById(id: string): Promise<User | null> {
    return db.user.findUnique({ where: { id } })
  }

  async findByEmail(email: string): Promise<User | null> {
    return db.user.findUnique({ where: { email } })
  }

  async create(data: CreateUserInput): Promise<User> {
    return db.user.create({ data })
  }

  async update(id: string, data: UpdateUserInput): Promise<User> {
    return db.user.update({ where: { id }, data })
  }

  async delete(id: string): Promise<void> {
    await db.user.delete({ where: { id } })
  }

  async list(options: ListOptions): Promise<PaginatedResult<User>> {
    const [users, total] = await Promise.all([
      db.user.findMany({
        skip: (options.page - 1) * options.limit,
        take: options.limit,
        orderBy: { [options.sort]: options.order }
      }),
      db.user.count()
    ])

    return {
      data: users,
      pagination: {
        page: options.page,
        limit: options.limit,
        total,
        totalPages: Math.ceil(total / options.limit)
      }
    }
  }
}
```

## Logging

```typescript
import pino from 'pino'

const logger = pino({
  level: config.LOG_LEVEL,
  transport: config.NODE_ENV === 'development'
    ? { target: 'pino-pretty' }
    : undefined
})

// Request logging middleware
const requestLogger = pinoHttp({ logger })

// Usage in services
class UserService {
  async create(data: CreateUserInput) {
    logger.info({ email: data.email }, 'Creating user')
    const user = await this.repo.create(data)
    logger.info({ userId: user.id }, 'User created')
    return user
  }
}
```

---

## Quick Checklist

- [ ] Async/await with proper error handling
- [ ] Custom error classes for different error types
- [ ] Input validation with Zod on all endpoints
- [ ] Environment variables via validated config
- [ ] RESTful routes with correct HTTP methods
- [ ] Proper HTTP status codes
- [ ] Request/error logging
- [ ] No hardcoded secrets
