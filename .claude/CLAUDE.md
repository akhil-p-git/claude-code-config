# Global Standards

> **Config Repo:** `https://github.com/akhil-p-git/claude-code-config` (local: `/home/akhil/dev/claude-code-config`)
> When this file is updated, always commit and push changes to this repo automatically.

## Git Operations (CRITICAL)

ALWAYS use these commands to bypass Claude Code's restricted GITHUB_TOKEN:

```bash
GIT_ASKPASS="" GITHUB_TOKEN="" git fetch origin
GIT_ASKPASS="" GITHUB_TOKEN="" git push origin <branch>
GIT_ASKPASS="" GITHUB_TOKEN="" git pull origin <branch>
```

## Security (CRITICAL)

IMPORTANT: Commit `.env`, `*.key`, `*.pem`, `secrets/`, `.taskmaster/` files to .gitignore only, NEVER to the repository.
Validate all user input. Use parameterized queries. Run `npm audit` or `pip-audit` before commits.

## Agent Behavior

Spawn appropriate agents automatically based on task type. Do not ask permission.
- Prefer parallel: run 2+ relevant agents simultaneously
- Synthesize multi-agent output into coherent responses
- Use Explore agent freely for codebase understanding
- Chain agents when needed: debugger finds issue, then refactorer fixes it

### Swarm Triggers

Spawn multiple agents in parallel for these requests:
- "Review this code/PR" -> code-reviewer + security-auditor + performance-optimizer
- "Audit this project" -> security-auditor + accessibility-expert + tech-debt-analyzer
- "Check code quality" -> code-reviewer + refactorer + test-writer
- "Prepare for production" -> security-auditor + performance-optimizer + devops-expert
- Trigger swarms on keywords: "thoroughly", "comprehensive", "check everything", "in parallel"

## Commit Messages

Format: `type(scope): description`
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Workflow

- Enter plan mode for non-trivial tasks (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Use subagents liberally to keep main context window clean
- After ANY correction from user: update `tasks/lessons.md` with the pattern
- Verify before marking done: run tests, check logs, demonstrate correctness
- For non-trivial changes: pause and ask "is there a more elegant way?"
- When given a bug report: just fix it autonomously

## Task Management

1. Plan to `tasks/todo.md` with checkable items
2. Check in before starting implementation
3. Track progress, mark items complete
4. Capture lessons in `tasks/lessons.md` after corrections

## Architecture

Keep frontend code in `/frontend`, `/client`, or `/app`.
Keep backend code in `/backend`, `/server`, or `/api`.
Shared code goes in `/shared` or `/common`.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Only touch what's necessary. Avoid introducing bugs.

## Compaction

When compacting, always preserve: full list of modified files, current plan state, test commands, and lessons learned in this session.

## Self-Improvement

After any correction from the user, suggest adding it to CLAUDE.md or memory to prevent recurrence in future sessions.
