---
description: "Create a GitHub pull request with intelligent description"
allowed-tools: ["Bash"]
model: "claude-sonnet-4-5-20250929"
---

# Create Pull Request

I'll help you create a well-structured GitHub PR.

## 1. Current Branch Status

! git status

! git branch --show-current

## 2. Changes Summary

! git diff $(git merge-base HEAD origin/main)..HEAD --stat

! git log --oneline $(git merge-base HEAD origin/main)..HEAD

## 3. PR Details

Based on your changes, I'll generate:

**Title:** Clear, concise summary of changes

**Description:**
- Summary of changes
- Why these changes were made
- Related issues/tickets
- Screenshots (if UI changes)
- Testing performed
- Breaking changes (if any)

## 4. Pre-PR Checklist

Before creating the PR, verifying:
- [ ] All tests pass
- [ ] No console.log or debug code
- [ ] No secrets or API keys
- [ ] Code is formatted and linted
- [ ] .gitignore is up to date
- [ ] Branch is up to date with main

## 5. Create PR

! gh pr create --web

Or I can create it directly with:
`gh pr create --title "..." --body "..." --base main`

Would you like me to proceed?
