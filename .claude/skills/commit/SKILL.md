---
name: commit
description: Commit the current change as one logical commit with a Conventional Commits message that explains why, matching the repo's own convention when it differs, then lint the message. Run only when the user invokes /commit.
argument-hint: "[optional note on intent]"
disable-model-invocation: true
---

# Commit

Intent from the user, if any: `$ARGUMENTS`

## Context

- Status: !`git status --short | head -60`
- Staged diff: !`git diff --cached | head -400`
- Unstaged and untracked (stat only): !`git diff --stat | tail -20`
- Recent subjects (the style to match): !`git log -15 --format=%s 2>/dev/null || true`

## Steps

1. **Scope.** If nothing is staged, stage the files that make up one logical change, by name. Never stage `.env*` files (except `.env.example`, `.sample`, `.template`), keys, credentials, or build output. If the tree mixes unrelated changes, propose how to split them into separate commits and ask before committing.
2. **Message.** Write it to a file in the session scratchpad:
   - Header: `type(scope): description`, at most 72 characters, lowercase imperative, no period, completing "If applied, this commit will…". Types: feat, fix, perf, refactor, docs, test, build, ci, chore, revert. If the recent subjects above follow a different convention, follow the repo.
   - Body, wrapped at 72, only when the header doesn't already explain why: the problem, its visible effect, why this approach, and any trade-off or follow-up. Give numbers for performance claims. Skip the "how"; the diff shows it.
   - Footers, each on its own line: `BREAKING CHANGE: <what breaks and how to migrate>`, `Fixes #<n>`, `Refs: #<n>`, then the attribution trailer the harness specifies, if any.
   - Never: "This commit…", a list of touched files, "various fixes", "improve code quality", vague assurances ("ensure robust handling", "enhance", "streamline"), or a note about what didn't change.
3. **Check.** Re-read the message against the Commits and Summaries lines of `~/.claude/rules/writing.md`; fix anything vague or inaccurate.
4. **Commit.** `git commit -F <message-file>`, then show `git log -1 --stat`. Don't push unless the user asks.
