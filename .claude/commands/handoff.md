---
description: Write a handoff note so a fresh session (after /clear, a new terminal, or a background agent) can continue this work without rediscovering it
argument-hint: "[what the next session should focus on]"
disable-model-invocation: true
allowed-tools: Bash(git *), Read, Write
---

Write a handoff for the next session. Its focus: $ARGUMENTS

Current state:
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || echo "(not a git repo)"`
- Branch: !`git branch --show-current 2>/dev/null || echo "(unknown)"`
- Working tree: !`git status --short 2>/dev/null || echo "(unavailable)"`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "(no commits)"`

If a plan file already holds the state, update its Progress and Decision log first and keep this note to what the plan doesn't cover.

Save to `~/.local/state/claude-handoffs/<repo-name>-<YYYY-MM-DD_HHMM>-<slug>.md`, outside the repo so it's never committed and any worktree can read it. Keep it short and specific, and point to artifacts instead of copying them:
- **Goal** — the overall objective and the immediate next one.
- **Status** — done, in progress, or not started, per task. Name the plan or spec file and the phase or step we're on.
- **Changed so far** — files with a one-line reason each (file:line where it helps), and commits made.
- **Verified** — commands that were run and their real results. List anything claimed but not verified as unverified.
- **Learnings** — non-obvious facts: root causes, gotchas, commands that finally worked, approaches that failed and why.
- **Next steps** — ordered and concrete, starting with the first command to run.
- **Open questions and risks** — decisions still needed from me.
- **Read first** — the 2–5 paths the next session should read before acting.

Redact secrets and tokens. Then print the path and the line to resume with: `/catchup <path>`.
