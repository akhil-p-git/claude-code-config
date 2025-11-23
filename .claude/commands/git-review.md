---
description: "Review git changes with security and quality checks"
allowed-tools: ["Bash", "Grep", "Read"]
model: "claude-sonnet-4-5-20250929"
---

I'll perform a comprehensive review of your git changes:

## 1. Git Status & Diff

! git status

! git diff HEAD

## 2. Security Checks

Checking for potential secrets in staged/modified files:

! git diff HEAD --name-only

I'll scan each changed file for:
- API keys, tokens, passwords
- Hardcoded credentials
- Environment variables that should be in .env
- Private keys or certificates

## 3. Code Quality Review

I'll analyze:
- Potential bugs or logic errors
- Performance implications
- Best practices adherence
- Test coverage for changes

## 4. .gitignore Validation

! cat .gitignore 2>/dev/null || echo "No .gitignore found"

Ensuring sensitive files are properly ignored:
- .env files
- .taskmaster/ directory
- API keys and credentials
- Build artifacts

## Summary

I'll provide:
✓ Security findings (if any)
✓ Code quality suggestions
✓ Recommended commit message
✓ Files that should be added to .gitignore
