---
description: "Security standards applied to all code"
---

# Security Standards

Full reference: @knowledge/security-standards.md

## Before Every Commit
- Check staged files: `git diff --cached --name-only`
- Verify no `.env`, `.key`, `.pem`, or credential files staged
- Validate `.gitignore` includes all sensitive patterns

## Input Validation
- Parameterized queries only (Zod for TS, Pydantic for Python)
- Use safe APIs (`fs.readdir`, not `exec` with user input)

## Auth
- bcrypt/argon2 for password hashing (SALT_ROUNDS=12)
- Short-lived JWTs (15m access, 7d refresh)
- Always check ownership or role before mutations

## Headers
- Use `helmet()` middleware for Express apps
- Set Content-Security-Policy headers
