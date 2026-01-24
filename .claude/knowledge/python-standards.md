# Python Standards

> Reference guide for Python development. Loaded as needed by Claude Code.

---

## Style Guide

- **Follow PEP 8** style guide
- **Formatting:** Black formatter with 88-character line width
- **Linting:** Ruff or flake8 with strict rules
- **Type Checking:** mypy with strict mode

## Import Order

Group imports in order (use isort):
1. Standard library
2. Third-party packages
3. Local modules

```python
# Standard library
import os
import sys
from datetime import datetime
from typing import Optional, List

# Third-party
import requests
from pydantic import BaseModel
from sqlalchemy import Column, String

# Local
from app.models import User
from app.utils import format_date
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables | `snake_case` | `user_name`, `is_active` |
| Functions | `snake_case` | `get_user_by_id`, `calculate_total` |
| Classes | `PascalCase` | `UserService`, `ApiClient` |
| Constants | `UPPER_SNAKE_CASE` | `API_URL`, `MAX_RETRIES` |
| Modules | `snake_case` | `user_service.py`, `api_client.py` |
| Private | `_leading_underscore` | `_internal_method` |
| Dunder | `__double_underscore__` | `__init__`, `__str__` |

## Type Hints

```python
from typing import Optional, List, Dict, Union, Callable, TypeVar

# Basic types
def greet(name: str) -> str:
    return f"Hello, {name}"

# Optional and Union
def get_user(id: int) -> Optional[User]:
    return db.get(id)

def process(value: Union[str, int]) -> str:
    return str(value)

# Collections
def get_users() -> List[User]:
    return db.query(User).all()

def get_config() -> Dict[str, str]:
    return {"key": "value"}

# Callables
Handler = Callable[[str, int], bool]

def register_handler(handler: Handler) -> None:
    pass

# Generics
T = TypeVar('T')

def first(items: List[T]) -> Optional[T]:
    return items[0] if items else None
```

## Pydantic Models

```python
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: str = Field(..., description="User email")
    name: str = Field(..., min_length=1, max_length=100)
    age: Optional[int] = Field(None, ge=0, le=150)

    @validator('email')
    def validate_email(cls, v: str) -> str:
        if '@' not in v:
            raise ValueError('Invalid email')
        return v.lower()

class User(UserCreate):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True
```

## Error Handling

```python
# Custom exceptions
class AppError(Exception):
    """Base application error."""
    pass

class NotFoundError(AppError):
    """Resource not found."""
    def __init__(self, resource: str, id: str):
        self.resource = resource
        self.id = id
        super().__init__(f"{resource} with id {id} not found")

class ValidationError(AppError):
    """Validation failed."""
    def __init__(self, field: str, message: str):
        self.field = field
        super().__init__(f"{field}: {message}")

# Usage
def get_user(user_id: str) -> User:
    user = db.get(user_id)
    if not user:
        raise NotFoundError("User", user_id)
    return user

# Context managers for cleanup
from contextlib import contextmanager

@contextmanager
def database_session():
    session = create_session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

## Async Python

```python
import asyncio
from typing import List

# Parallel async operations
async def fetch_all_users(ids: List[str]) -> List[User]:
    tasks = [fetch_user(id) for id in ids]
    return await asyncio.gather(*tasks)

# With error handling
async def fetch_all_safe(ids: List[str]) -> List[Optional[User]]:
    tasks = [fetch_user(id) for id in ids]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return [r if not isinstance(r, Exception) else None for r in results]

# Async context manager
class AsyncDatabase:
    async def __aenter__(self):
        await self.connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.disconnect()
```

## Docstrings

```python
def calculate_discount(
    price: float,
    discount_percent: float,
    min_price: float = 0
) -> float:
    """Calculate discounted price with minimum floor.

    Args:
        price: Original price in dollars.
        discount_percent: Discount percentage (0-100).
        min_price: Minimum allowed price after discount.

    Returns:
        The discounted price, not less than min_price.

    Raises:
        ValueError: If discount_percent is not between 0 and 100.

    Example:
        >>> calculate_discount(100, 20)
        80.0
        >>> calculate_discount(100, 20, min_price=85)
        85.0
    """
    if not 0 <= discount_percent <= 100:
        raise ValueError("Discount must be between 0 and 100")

    discounted = price * (1 - discount_percent / 100)
    return max(discounted, min_price)
```

## Project Structure

```
project/
├── pyproject.toml
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── models/
│       ├── services/
│       └── utils/
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_*.py
└── .env.example
```

---

## Quick Checklist

- [ ] PEP 8 compliant (Black formatted)
- [ ] Type hints on all functions
- [ ] Docstrings on public functions/classes
- [ ] Custom exceptions for error handling
- [ ] Pydantic for data validation
- [ ] asyncio.gather() for parallel async
- [ ] Context managers for resource cleanup
