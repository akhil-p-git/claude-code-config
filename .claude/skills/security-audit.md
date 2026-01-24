---
name: security-audit
description: Comprehensive security audit scanning for secrets, vulnerabilities, and .gitignore validation. Use when user mentions security, audit, secrets, vulnerabilities, or before deploying to production.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
model: claude-sonnet-4-5-20250929
---

# Security Audit

Running comprehensive security checks on the project...

## 1. .gitignore Validation

First, let me check if .gitignore exists and contains required entries:

Required entries:
- `.env` and `.env.*` (except `.env.example`)
- `.taskmaster/`
- `node_modules/` or `__pycache__/`
- Credential files (`*.key`, `*.pem`, `secrets/`)

## 2. Scanning for Exposed Secrets

I'll search for potential secrets in tracked files:
- API keys (patterns like `API_KEY`, `apiKey`, `api_key`)
- Tokens (JWT, OAuth, GitHub, AWS tokens)
- Passwords or credentials in code
- Private keys or certificates
- Database connection strings with passwords
- Hardcoded URLs with credentials

## 3. Environment Files Check

Checking for sensitive files in the repository:
- `.env` files that shouldn't be committed
- Key files (`.key`, `.pem`, `.cert`)
- Credential directories

## 4. Dependency Security

Running security audits:
- `npm audit` for Node.js projects
- `pip-audit` or `safety check` for Python projects
- Checking for known vulnerable packages

## 5. Git History Scan

Checking if sensitive files were previously committed and may still be in history.

## 6. Code Security Patterns

Scanning for common vulnerabilities:
- SQL injection patterns
- Command injection risks
- XSS vulnerabilities in frontend code
- Insecure crypto usage

---

## Report

I'll provide:
1. **Critical issues** - Secrets found, missing .gitignore entries
2. **Warnings** - Potential vulnerabilities
3. **Recommendations** - Security improvements
4. **Fix commands** - How to resolve issues (including removing secrets from git history if needed)
