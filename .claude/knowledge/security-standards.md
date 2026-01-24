# Security Standards

> Critical security guidelines for all projects. Loaded as needed by Claude Code.

---

## CRITICAL: Never Commit Secrets

### Required .gitignore Entries

```gitignore
# Environment files
.env
.env.*
!.env.example

# Credentials
*.key
*.pem
*.cert
*.p12
*.pfx
secrets/
credentials/
.credentials

# API keys and tokens
*_api_key*
*_token*
*.secret

# Task management
.taskmaster/

# IDE and local
.idea/
.vscode/settings.json
*.local

# OS files
.DS_Store
Thumbs.db
```

### Before Every Commit

1. **Check staged files:** `git diff --cached --name-only`
2. **Look for secrets:** No `.env`, `.key`, `.pem`, or credential files
3. **Validate .gitignore:** Ensure all sensitive patterns included

---

## Secret Management

### Environment Variables

```bash
# .env.example (commit this)
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
API_KEY=your-api-key-here
JWT_SECRET=your-jwt-secret-min-32-chars

# .env (NEVER commit)
DATABASE_URL=postgresql://prod_user:real_password@prod.db.com:5432/prod
API_KEY=sk-live-xxxxxxxxxxxxx
JWT_SECRET=actual-secret-key-used-in-production
```

### Loading Environment Variables

```typescript
// TypeScript/Node.js
import { config } from 'dotenv'
config()

const apiKey = process.env.API_KEY
if (!apiKey) {
  throw new Error('API_KEY environment variable is required')
}
```

```python
# Python
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv('API_KEY')
if not api_key:
    raise ValueError('API_KEY environment variable is required')
```

### Production Secret Management

| Environment | Tool |
|-------------|------|
| AWS | AWS Secrets Manager, Parameter Store |
| GCP | Secret Manager |
| Azure | Key Vault |
| Kubernetes | Secrets, External Secrets Operator |
| CI/CD | GitHub Secrets, GitLab CI Variables |

---

## Input Validation

### Never Trust User Input

```typescript
// BAD - SQL Injection vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`

// GOOD - Parameterized query
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId])

// BAD - Command injection vulnerable
exec(`ls ${userInput}`)

// GOOD - Use safe APIs
const files = await fs.readdir(sanitizedPath)
```

### Validation Libraries

```typescript
// Zod (TypeScript)
import { z } from 'zod'

const UserInput = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
  name: z.string().min(1).max(100).regex(/^[a-zA-Z\s]+$/)
})

// Validate
const validated = UserInput.parse(untrustedInput)
```

```python
# Pydantic (Python)
from pydantic import BaseModel, EmailStr, conint, constr

class UserInput(BaseModel):
    email: EmailStr
    age: conint(ge=0, le=150)
    name: constr(min_length=1, max_length=100, regex=r'^[a-zA-Z\s]+$')

# Validate
validated = UserInput(**untrusted_input)
```

---

## Authentication & Authorization

### Password Hashing

```typescript
// Use bcrypt or argon2
import bcrypt from 'bcrypt'

const SALT_ROUNDS = 12

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS)
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash)
}
```

### JWT Best Practices

```typescript
import jwt from 'jsonwebtoken'

// Short-lived access tokens
const accessToken = jwt.sign(
  { userId: user.id, role: user.role },
  process.env.JWT_SECRET!,
  { expiresIn: '15m' }
)

// Longer-lived refresh tokens (store securely)
const refreshToken = jwt.sign(
  { userId: user.id, tokenVersion: user.tokenVersion },
  process.env.JWT_REFRESH_SECRET!,
  { expiresIn: '7d' }
)

// Verify with proper error handling
try {
  const payload = jwt.verify(token, process.env.JWT_SECRET!)
} catch (error) {
  if (error instanceof jwt.TokenExpiredError) {
    // Handle expired token
  } else if (error instanceof jwt.JsonWebTokenError) {
    // Handle invalid token
  }
}
```

### Authorization Checks

```typescript
// Always check permissions
async function updateUser(requesterId: string, targetId: string, data: UpdateData) {
  const requester = await getUser(requesterId)

  // Check ownership or admin role
  if (requesterId !== targetId && requester.role !== 'admin') {
    throw new ForbiddenError('Not authorized to update this user')
  }

  return userRepository.update(targetId, data)
}
```

---

## XSS Prevention

### React (Safe by Default)

```tsx
// SAFE - React escapes by default
<div>{userInput}</div>

// DANGEROUS - Only use with trusted content
<div dangerouslySetInnerHTML={{ __html: trustedHtml }} />

// If you must render HTML, sanitize first
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(untrustedHtml) }} />
```

### Content Security Policy

```typescript
// Express middleware
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
  )
  next()
})
```

---

## CSRF Protection

```typescript
// Express with csurf
import csrf from 'csurf'

const csrfProtection = csrf({ cookie: true })

app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() })
})

app.post('/submit', csrfProtection, (req, res) => {
  // Token validated automatically
})
```

---

## Dependency Security

### Regular Audits

```bash
# Node.js
npm audit
npm audit fix

# Python
pip-audit
safety check

# Go
go list -m -json all | nancy sleuth
```

### Lock Files

Always commit lock files:
- `package-lock.json` (npm)
- `yarn.lock` (Yarn)
- `pnpm-lock.yaml` (pnpm)
- `poetry.lock` (Poetry)
- `Pipfile.lock` (Pipenv)
- `go.sum` (Go)

### Dependabot/Renovate

Enable automated dependency updates in your repository.

---

## Secure Headers

```typescript
import helmet from 'helmet'

app.use(helmet())

// Or configure individually
app.use(helmet.contentSecurityPolicy())
app.use(helmet.crossOriginEmbedderPolicy())
app.use(helmet.crossOriginOpenerPolicy())
app.use(helmet.crossOriginResourcePolicy())
app.use(helmet.dnsPrefetchControl())
app.use(helmet.frameguard())
app.use(helmet.hidePoweredBy())
app.use(helmet.hsts())
app.use(helmet.ieNoOpen())
app.use(helmet.noSniff())
app.use(helmet.originAgentCluster())
app.use(helmet.permittedCrossDomainPolicies())
app.use(helmet.referrerPolicy())
app.use(helmet.xssFilter())
```

---

## Quick Security Checklist

### Before Commit
- [ ] No secrets in code or config
- [ ] .env files not staged
- [ ] .gitignore includes sensitive patterns

### Code Review
- [ ] Input validated at entry points
- [ ] SQL queries parameterized
- [ ] No command injection vulnerabilities
- [ ] Authentication required on sensitive endpoints
- [ ] Authorization checked for resource access

### Dependencies
- [ ] `npm audit` / `pip-audit` clean
- [ ] Lock files committed
- [ ] No known vulnerable packages

### Headers & Tokens
- [ ] Security headers configured (helmet)
- [ ] CSRF protection on forms
- [ ] Short-lived JWTs
- [ ] Secure cookie flags set
