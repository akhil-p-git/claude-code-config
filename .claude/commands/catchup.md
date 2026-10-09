---
description: Rebuild context after /clear or in a new session — read the latest handoff or plan and what changed on this branch, verify it, then summarize state and propose the next step
argument-hint: "[handoff or plan path]"
disable-model-invocation: true
allowed-tools: Bash(git *), Read, Grep, Glob
---

Catch up on in-progress work. Handoff or plan to start from: $ARGUMENTS

Branch state:
- Branch: !`git branch --show-current 2>/dev/null || echo "(unknown)"`
- Uncommitted: !`git status --short 2>/dev/null || echo "(unavailable)"`
- Recent commits: !`git log --oneline -15 2>/dev/null || echo "(no commits)"`
- Changed vs default branch: !`git diff --stat origin/HEAD...HEAD 2>/dev/null || echo "(no origin/HEAD; compute the base yourself)"`

1. If no path was given, look in `~/.local/state/claude-handoffs/` for the newest file named after this repo, and in `docs/plans/` for a plan with unchecked Progress items. Read the one that matches this branch in full, plus the files it says to read first.
2. Read the changed files that matter for the next step. Skip lockfiles, generated files, and snapshots, and use an Explore subagent if there are many.
3. Check the note against reality. Are the listed changes present? Do the verified claims still hold (rerun the cheapest check)? Has the branch moved since the note was written?
4. Reply in under 15 lines: the goal, where we are (phase or step), what's verified and what isn't, any discrepancies with the note, and the next step you propose. Wait for my go-ahead before editing anything.
