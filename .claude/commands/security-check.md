---
description: "Scan project for security issues, secrets, and validate .gitignore"
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
model: "claude-sonnet-4-5-20250929"
---

# Security Audit

Running comprehensive security checks on your project...

## 1. .gitignore Validation

! cat .gitignore 2>/dev/null || echo "WARNING: No .gitignore found!"

Checking for required entries:
- `.env` and `.env.*` (except `.env.example`)
- `.taskmaster/`
- `node_modules/`
- Credential files (*.key, *.pem, secrets/)

## 2. Scanning for Exposed Secrets

Searching for potential secrets in tracked files:

! git ls-files | head -100

I'll scan for:
- API keys (patterns like `API_KEY`, `apiKey`, etc.)
- Tokens (JWT, OAuth, GitHub tokens)
- Passwords or credentials
- Private keys
- Database connection strings

## 3. Environment Files Check

! ls -la | grep -E "\.env|\.key|\.pem|\.cert|secrets|credentials" || echo "No sensitive files in root"

## 4. Dependency Security

Checking for vulnerable dependencies:

! npm audit 2>/dev/null || pip check 2>/dev/null || echo "No package manager detected"

## 5. Git History Scan

Checking if sensitive files were previously committed:

! git log --all --pretty=format: --name-only --diff-filter=A | sort -u | grep -E "\.env$|\.key$|\.pem$|secret" || echo "No suspicious files in git history"

---

## Summary

I'll provide:
- Missing .gitignore entries
- Found secrets or credentials (if any)
- Recommended fixes
- Commands to remove secrets from git history if needed
