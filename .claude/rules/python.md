---
description: "Python coding standards and best practices"
paths:
  - "**/*.py"
---

# Python Standards

Full reference: @knowledge/python-standards.md

## Key Rules
- PEP 8 compliant, Black formatter (88-char lines)
- Type hints on ALL functions
- Pydantic for data validation
- `asyncio.gather()` for parallel async operations
- Context managers for resource cleanup

## Naming
- `snake_case`: variables, functions, modules
- `PascalCase`: classes
- `UPPER_SNAKE_CASE`: constants
- `_leading_underscore`: private

## Import Order (use isort)
1. Standard library
2. Third-party packages
3. Local modules

## Error Handling
- Custom exception classes inheriting from a base `AppError`
- Use `contextlib.contextmanager` for cleanup patterns
- Google-style docstrings with Args, Returns, Raises
