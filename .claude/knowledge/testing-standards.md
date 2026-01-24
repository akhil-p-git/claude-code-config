# Testing Standards

> Reference guide for testing practices. Loaded as needed by Claude Code.

---

## Coverage Requirements

- **Minimum 80% code coverage** for new projects
- Focus on critical paths first
- Don't test trivial getters/setters
- 100% coverage on security-critical code

---

## Test Organization

### Directory Structure

```
project/
├── src/
│   ├── components/
│   │   └── Button.tsx
│   ├── services/
│   │   └── userService.ts
│   └── utils/
│       └── format.ts
└── tests/                    # or __tests__/
    ├── unit/
    │   ├── components/
    │   │   └── Button.test.tsx
    │   ├── services/
    │   │   └── userService.test.ts
    │   └── utils/
    │       └── format.test.ts
    ├── integration/
    │   └── api/
    │       └── users.test.ts
    └── e2e/
        └── auth.spec.ts
```

### Test Types

| Type | Purpose | Tools |
|------|---------|-------|
| Unit | Test individual functions/components | Jest, Vitest, pytest |
| Integration | Test API endpoints, DB operations | Supertest, pytest |
| E2E | Test user workflows | Playwright, Cypress |

---

## Test Naming

Use descriptive names that explain what's being tested:

```typescript
// Pattern: test('should [expected behavior] when [condition]')

describe('UserService', () => {
  describe('createUser', () => {
    test('should create user with valid data', async () => {})
    test('should throw ValidationError when email is invalid', async () => {})
    test('should throw ConflictError when email already exists', async () => {})
  })

  describe('deleteUser', () => {
    test('should return true when user exists', async () => {})
    test('should return false when user not found', async () => {})
    test('should throw UnauthorizedError when not owner', async () => {})
  })
})
```

---

## JavaScript/TypeScript Testing

### Jest/Vitest Setup

```typescript
// jest.config.ts
export default {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 }
  }
}
```

### Unit Test Examples

```typescript
import { describe, test, expect, beforeEach, jest } from '@jest/globals'
import { UserService } from '../src/services/userService'
import { UserRepository } from '../src/repositories/userRepository'

// Mock dependencies
jest.mock('../src/repositories/userRepository')

describe('UserService', () => {
  let service: UserService
  let mockRepo: jest.Mocked<UserRepository>

  beforeEach(() => {
    mockRepo = new UserRepository() as jest.Mocked<UserRepository>
    service = new UserService(mockRepo)
  })

  test('should return user when found', async () => {
    const mockUser = { id: '1', name: 'John', email: 'john@example.com' }
    mockRepo.findById.mockResolvedValue(mockUser)

    const result = await service.getUser('1')

    expect(result).toEqual(mockUser)
    expect(mockRepo.findById).toHaveBeenCalledWith('1')
  })

  test('should throw NotFoundError when user not found', async () => {
    mockRepo.findById.mockResolvedValue(null)

    await expect(service.getUser('999')).rejects.toThrow(NotFoundError)
  })
})
```

### React Component Testing

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { LoginForm } from '../src/components/LoginForm'

describe('LoginForm', () => {
  test('should submit form with valid credentials', async () => {
    const onSubmit = jest.fn()
    render(<LoginForm onSubmit={onSubmit} />)

    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com')
    await userEvent.type(screen.getByLabelText(/password/i), 'password123')
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      })
    })
  })

  test('should show error when email is invalid', async () => {
    render(<LoginForm onSubmit={jest.fn()} />)

    await userEvent.type(screen.getByLabelText(/email/i), 'invalid-email')
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))

    expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
  })
})
```

### API Integration Testing

```typescript
import request from 'supertest'
import { app } from '../src/app'
import { db } from '../src/db'

describe('POST /api/users', () => {
  beforeEach(async () => {
    await db.user.deleteMany()
  })

  test('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'Test User' })
      .expect(201)

    expect(response.body).toMatchObject({
      email: 'test@example.com',
      name: 'Test User'
    })
    expect(response.body.id).toBeDefined()
  })

  test('should return 400 when email is invalid', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'invalid', name: 'Test' })
      .expect(400)

    expect(response.body.error.code).toBe('VALIDATION_ERROR')
  })

  test('should return 409 when email already exists', async () => {
    await db.user.create({ data: { email: 'test@example.com', name: 'Existing' } })

    await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'New User' })
      .expect(409)
  })
})
```

---

## Python Testing

### pytest Setup

```python
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --cov=src --cov-report=term-missing --cov-fail-under=80"
```

### Unit Test Examples

```python
import pytest
from unittest.mock import Mock, AsyncMock
from src.services.user_service import UserService
from src.errors import NotFoundError

class TestUserService:
    @pytest.fixture
    def mock_repo(self):
        return Mock()

    @pytest.fixture
    def service(self, mock_repo):
        return UserService(mock_repo)

    def test_get_user_returns_user_when_found(self, service, mock_repo):
        mock_user = {"id": "1", "name": "John", "email": "john@example.com"}
        mock_repo.find_by_id.return_value = mock_user

        result = service.get_user("1")

        assert result == mock_user
        mock_repo.find_by_id.assert_called_once_with("1")

    def test_get_user_raises_not_found_when_missing(self, service, mock_repo):
        mock_repo.find_by_id.return_value = None

        with pytest.raises(NotFoundError):
            service.get_user("999")

# Async tests
class TestAsyncUserService:
    @pytest.fixture
    def mock_repo(self):
        return AsyncMock()

    @pytest.mark.asyncio
    async def test_get_user_async(self, mock_repo):
        service = UserService(mock_repo)
        mock_repo.find_by_id.return_value = {"id": "1", "name": "John"}

        result = await service.get_user_async("1")

        assert result["id"] == "1"
```

### Fixtures

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="session")
def engine():
    return create_engine("sqlite:///:memory:")

@pytest.fixture(scope="session")
def tables(engine):
    Base.metadata.create_all(engine)
    yield
    Base.metadata.drop_all(engine)

@pytest.fixture
def db_session(engine, tables):
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def user_factory(db_session):
    def create_user(**kwargs):
        defaults = {"name": "Test User", "email": "test@example.com"}
        user = User(**{**defaults, **kwargs})
        db_session.add(user)
        db_session.commit()
        return user
    return create_user
```

---

## E2E Testing (Playwright)

```typescript
import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test('should login successfully with valid credentials', async ({ page }) => {
    await page.goto('/login')

    await page.fill('[name="email"]', 'user@example.com')
    await page.fill('[name="password"]', 'password123')
    await page.click('button[type="submit"]')

    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('h1')).toContainText('Welcome')
  })

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/login')

    await page.fill('[name="email"]', 'user@example.com')
    await page.fill('[name="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')

    await expect(page.locator('.error')).toContainText('Invalid credentials')
    await expect(page).toHaveURL('/login')
  })
})
```

---

## Quick Checklist

- [ ] 80%+ code coverage on new code
- [ ] Unit tests for business logic
- [ ] Integration tests for API endpoints
- [ ] E2E tests for critical user flows
- [ ] Descriptive test names
- [ ] Tests isolated (no shared state)
- [ ] Mocks for external dependencies
- [ ] CI runs tests on every PR
