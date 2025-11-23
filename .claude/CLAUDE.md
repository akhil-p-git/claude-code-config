# Global Coding Standards & Guidelines

## Project Architecture

### Frontend/Backend Separation
- **Frontend:** Always place in `/frontend`, `/client`, or `/app` directory
- **Backend:** Always place in `/backend`, `/server`, or `/api` directory
- **Shared:** Common code goes in `/shared` or `/common`
- Never mix frontend and backend logic in the same directory

### Directory Structure
```
project/
├── frontend/          # React, UI components
├── backend/           # Node.js, API, services
├── shared/            # Shared types, utilities
├── .taskmaster/       # Task management (NEVER commit)
└── .claude/           # Claude Code config (commit settings.json)
```

## Language-Specific Standards

### JavaScript/TypeScript
- **Always use TypeScript** for new projects
- **Strict mode:** `"strict": true` in tsconfig.json
- **Formatting:** Prettier with 2-space indentation
- **Linting:** ESLint with recommended rules
- **Imports:** Organize in this order:
  1. External libraries
  2. Internal modules
  3. Relative imports
  4. Types
- **Naming:**
  - `camelCase` for variables and functions
  - `PascalCase` for classes and React components
  - `UPPER_SNAKE_CASE` for constants
  - Prefix interfaces with `I` only if needed for clarity

### React
- **Use functional components** with hooks (no class components)
- **File structure:**
  - One component per file
  - `ComponentName.tsx` for component
  - `ComponentName.module.css` for styles (if CSS modules)
  - `ComponentName.test.tsx` for tests
- **Hooks:**
  - Custom hooks start with `use` prefix
  - Extract complex logic into custom hooks
  - Follow rules of hooks (no conditional hooks)
- **Props:**
  - Define prop types with TypeScript interfaces
  - Destructure props in function signature
- **State management:**
  - Local state with `useState` for component-specific data
  - Context API for shared app state
  - Consider Zustand/Redux for complex global state

### Node.js/Backend
- **Use async/await** over callbacks
- **Error handling:**
  - Always use try/catch with async functions
  - Create custom error classes
  - Never swallow errors silently
- **Environment variables:**
  - Store ALL secrets in `.env` files
  - Never hardcode API keys or credentials
  - Use `process.env.VARIABLE_NAME`
- **API structure:**
  - RESTful naming conventions
  - Use HTTP status codes correctly (200, 201, 400, 401, 404, 500)
  - Validate input with libraries like Joi or Zod

### Python
- **Follow PEP 8** style guide
- **Type hints:** Use type annotations for function signatures
- **Formatting:** Black formatter with 88-character line width
- **Imports:** Group in order (stdlib, third-party, local)
- **Naming:**
  - `snake_case` for functions and variables
  - `PascalCase` for classes
  - `UPPER_SNAKE_CASE` for constants
- **Docstrings:** Use for all public functions and classes

### C
- **Follow K&R style** or Linux kernel style
- **Memory management:**
  - Always free allocated memory
  - Check malloc/calloc return values
  - Initialize pointers to NULL
- **Error handling:**
  - Return error codes (0 for success, negative for errors)
  - Use errno for system call errors
- **Naming:**
  - `snake_case` for functions and variables
  - `UPPER_SNAKE_CASE` for macros and constants
- **Headers:** Use include guards or `#pragma once`

## Security Standards

### CRITICAL: Never Commit Secrets
- **Always add to .gitignore:**
  - `.env` and `.env.*` (except `.env.example`)
  - `*.key`, `*.pem`, `*.cert`
  - `secrets/`, `credentials/`
  - API keys, tokens, passwords
  - `.taskmaster/` directory

### Secret Management
- Use environment variables for ALL sensitive data
- Store in `.env` files (gitignored)
- Provide `.env.example` with dummy values
- Use secret management tools (AWS Secrets Manager, etc.) in production

### Input Validation
- **Never trust user input**
- Sanitize all inputs before processing
- Validate on both frontend and backend
- Prevent SQL injection, XSS, CSRF

### Dependencies
- Regularly update dependencies
- Run `npm audit` or `pip check` before commits
- Pin versions in production
- Review dependency licenses

## Testing Standards

### Coverage
- **Minimum 80% code coverage** for new projects
- Focus on critical paths first
- Don't test trivial getters/setters

### Test Organization
- **JavaScript/TypeScript:** Jest or Vitest
- **Python:** pytest
- **Structure:**
  - Unit tests: Test individual functions/components
  - Integration tests: Test API endpoints, DB operations
  - E2E tests: Test user workflows (Playwright, Cypress)

### Test Naming
- Describe what is being tested and expected behavior
- Pattern: `test('should [expected behavior] when [condition]')`
- Example: `test('should return 404 when user not found')`

## Git & Version Control

### Commit Messages
- **Format:** `type(scope): description`
- **Types:**
  - `feat:` New feature
  - `fix:` Bug fix
  - `docs:` Documentation
  - `style:` Formatting (no code change)
  - `refactor:` Code restructuring
  - `test:` Adding tests
  - `chore:` Maintenance
- **Example:** `feat(auth): add OAuth2 login support`

### Branch Strategy
- `main`/`master`: Production-ready code
- `develop`: Integration branch
- `feature/feature-name`: New features
- `fix/bug-name`: Bug fixes
- `hotfix/issue`: Emergency production fixes

### Before Committing
- Run linter and formatter
- Run tests
- Review diff for sensitive data
- Ensure .gitignore is updated

## Performance Standards

### Frontend
- Lazy load routes and heavy components
- Optimize images (WebP, correct sizes)
- Minimize bundle size (code splitting)
- Use React.memo for expensive components
- Debounce/throttle expensive operations

### Backend
- Use database indexes appropriately
- Cache frequently accessed data (Redis, in-memory)
- Implement pagination for large datasets
- Use connection pooling for databases
- Monitor and log performance metrics

## Code Review Checklist

Before submitting code, verify:
- [ ] No hardcoded secrets or API keys
- [ ] `.env` and `.taskmaster/` in .gitignore
- [ ] Tests pass with good coverage
- [ ] No console.log or debug statements
- [ ] Error handling implemented
- [ ] Code is formatted and linted
- [ ] Frontend/backend properly separated
- [ ] Dependencies are up to date
- [ ] Documentation updated if needed

## Documentation Standards

### README.md
Every project must have:
- Project description
- Prerequisites
- Installation instructions
- Environment setup (with .env.example)
- Running the project
- Running tests
- Project structure
- Contributing guidelines

### Code Comments
- Explain **why**, not **what**
- Comment complex algorithms or business logic
- Use JSDoc/docstrings for public APIs
- Keep comments up to date

## Task Management

### Taskmaster Integration
- `.taskmaster/` directory is **NEVER committed** to git
- Always in .gitignore
- Use for personal task tracking
- Tasks are project-specific, not shared

---

**Remember:** These are guidelines, not rigid rules. Use judgment based on project context, but default to these standards when in doubt.
