# Global Coding Standards & Guidelines

## Agent & Skill Automation (CRITICAL)

### Automatic Agent Selection
ALWAYS automatically spawn the appropriate agent(s) based on the task. DO NOT ask permission - just use them:

| Task Type | Agent(s) to Spawn |
|-----------|-------------------|
| Code cleanup, refactoring | `@refactorer` |
| Bug investigation | `@debugger` |
| Security review | `@security-auditor` |
| Performance issues | `@performance-optimizer` |
| API design | `@api-designer` |
| Database work | `@database-expert` |
| System design | `@architect` |
| Writing tests | `@test-writer` |
| Code review | `@code-reviewer` |
| Documentation | `@docs-writer` |
| React/UI work | `@frontend-expert` |
| Node.js/API work | `@backend-expert` |
| DevOps/CI/CD | `@devops-expert` |
| Accessibility | `@accessibility-expert` |
| Data pipelines | `@data-engineer` |
| Mobile dev | `@mobile-expert` |
| AI/ML integration | `@ai-engineer` |
| Monorepo setup | `@monorepo-expert` |
| UX issues | `@ux-reviewer` |
| Regex help | `@regex-expert` |
| Git problems | `@git-expert` |
| Migrations/upgrades | `@migration-expert` |
| Codebase exploration | Explore agent (built-in) |

### Automatic Parallel Agents (Swarms)
Spawn multiple agents IN PARALLEL when the task benefits from multiple perspectives:

**Always swarm for:**
- "Review this code/PR" → `@code-reviewer` + `@security-auditor` + `@performance-optimizer`
- "Audit this project" → `@security-auditor` + `@accessibility-expert` + `@performance-optimizer`
- "Check code quality" → `@code-reviewer` + `@refactorer` + `@test-writer`
- "Prepare for production" → `@security-auditor` + `@performance-optimizer` + `@devops-expert`
- Complex codebase questions → Multiple Explore agents on different areas

**Swarm when user says:**
- "thoroughly review/check/audit"
- "comprehensive analysis"
- "check everything"
- "multiple perspectives"
- "in parallel"

### Automatic Skill Invocation
Use skills automatically when the task matches - DO NOT ask:

| Task | Skill |
|------|-------|
| Create/edit Word docs | `docx` |
| Create/edit PDFs | `pdf` |
| Create/edit spreadsheets | `xlsx` |
| Create/edit presentations | `pptx` |
| Build React artifacts | `web-artifacts-builder` |
| Create visual designs | `canvas-design` |
| Frontend UI components | `frontend-design` |
| Generative art | `algorithmic-art` |
| Test web apps | `webapp-testing` |
| Build MCP servers | `mcp-builder` |
| Create new skills | `skill-creator` |
| Style with themes | `theme-factory` |
| Anthropic branding | `brand-guidelines` |
| Internal comms | `internal-comms` |
| Co-author docs | `doc-coauthoring` |
| Slack GIFs | `slack-gif-creator` |

### Behavior Rules
1. **Don't ask** - Just spawn agents/skills when appropriate
2. **Prefer parallel** - When 2+ agents are relevant, run them simultaneously
3. **Combine results** - Synthesize multi-agent output into coherent response
4. **Use Explore freely** - For any codebase understanding task
5. **Chain when needed** - e.g., `@debugger` finds issue → `@refactorer` fixes it

---

## Git Operations (CRITICAL)

**ALWAYS use these commands for git operations to bypass Claude Code's restricted GITHUB_TOKEN:**

```bash
# Fetch
GIT_ASKPASS="" GITHUB_TOKEN="" git fetch origin

# Push
GIT_ASKPASS="" GITHUB_TOKEN="" git push origin <branch>

# Pull
GIT_ASKPASS="" GITHUB_TOKEN="" git pull origin <branch>
```

Never use plain `git push`, `git pull`, or `git fetch` - they will fail with 403 errors.

---

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

> Full reference: `.claude/knowledge/react-best-practices.md`

**Core Standards:**
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

**Performance Rules (CRITICAL):**

*Waterfalls (#1 Performance Killer):*
```tsx
// BAD - Sequential (3x slower)
const a = await fetchA(); const b = await fetchB();
// GOOD - Parallel
const [a, b] = await Promise.all([fetchA(), fetchB()]);
```

*Bundle Optimization:*
```tsx
// BAD - Barrel imports (200-800ms cold start penalty)
import { Icon } from 'lucide-react'
// GOOD - Direct imports
import Icon from 'lucide-react/dist/esm/icons/icon'
// BEST - Next.js 13.5+ optimizePackageImports config

// BAD - Heavy component in main bundle
import { MonacoEditor } from './editor'
// GOOD - Dynamic import
const Editor = dynamic(() => import('./editor'), { ssr: false })
```

*Re-render Prevention:*
```tsx
// BAD - Object dependency (re-runs on any user change)
useEffect(() => {}, [user])
// GOOD - Primitive dependency
useEffect(() => {}, [user.id])

// BAD - Expensive initial state (runs every render)
useState(buildIndex(data))
// GOOD - Lazy initialization (runs once)
useState(() => buildIndex(data))

// BAD - Renders "0" when count is 0
{count && <Badge />}
// GOOD - Explicit conditional
{count > 0 ? <Badge /> : null}
```

*Server Components:*
```tsx
// Use React.cache() for request deduplication
const getUser = cache(async (id) => db.user.findUnique({ where: { id } }))

// Minimize RSC serialization - pass only needed fields
<ClientComponent userName={user.name} />  // Not: user={user}
```

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

### Frontend (React/Next.js)

> Priority order based on impact (see `.claude/knowledge/react-best-practices.md`):

**CRITICAL:**
- Eliminate waterfalls - use `Promise.all()` for independent operations
- Bundle optimization - `next/dynamic`, avoid barrel imports
- Preload on user intent (hover/focus)

**HIGH:**
- Server deduplication - `React.cache()` for shared queries
- Client deduplication - SWR/React Query
- Minimize RSC serialization - pass only needed fields
- Strategic Suspense boundaries

**MEDIUM:**
- Extract expensive work into memoized components
- Primitive deps in useEffect (not objects)
- Lazy state init: `useState(() => ...)`
- Use `startTransition` for non-urgent updates
- Hoist static JSX outside components
- Use Set/Map for repeated lookups

**General:**
- Lazy load routes and heavy components
- Optimize images (WebP, correct sizes)
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
