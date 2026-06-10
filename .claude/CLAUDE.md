# Global Standards

> Personal Claude Code config, version-controlled at `github.com/akhil-p-git/claude-code-config`
> (local `~/dev/claude-code-config`, symlinked into `~/.claude/`).
> **Whenever you change any config file here (this file, `rules/`, `commands/`, `hooks/`, `settings.json`), commit and push it** using the git-auth commands below.

## How this config is organized
- **This file** — universal rules, loaded every session. Keep it lean (<~100 lines): bloat makes me ignore rules.
- **`rules/*.md`** — topic rules. `engineering`, `security`, `storage`, `ai-assisted-development` load always; the rest (`python`, `react`, `testing`, `data`, `finance`, …) load only when matching files are touched. Don't restate their content here.
- **`commands/*.md`** — slash-commands (`/reflect`, `/pr`, `/security-check`, `/ship-check`, model queries, …).
- **`hooks/`** — deterministic automation wired in `settings.json` (advisory text can't enforce; hooks can).

## Git operations (machine quirk)
Claude Code's `GITHUB_TOKEN` is restricted. ALWAYS bypass it:
```bash
GIT_ASKPASS="" GITHUB_TOKEN="" git fetch origin
GIT_ASKPASS="" GITHUB_TOKEN="" git push origin <branch>
GIT_ASKPASS="" GITHUB_TOKEN="" git pull origin <branch>
```
Git/drive safety lives in `rules/storage.md` (`$HOME` is a PUBLIC repo — never `git add -A` there).

## Self-improvement loop (this config iterates on itself)
1. **Capture (automatic):** a `UserPromptSubmit` hook detects when you correct me and appends the correction to `~/.claude/lessons-inbox.md`. I never have to remember to log it.
2. **Promote (you run `/reflect`):** clusters the inbox + recent session into *generalized* rules, shows a diff, and on your approval writes each into this file or the right `rules/*.md`, clears the inbox, and pushes.
3. **Prune (`/reflect --prune`):** periodically removes stale/contradictory rules and keeps this file lean.

Rule: **capture is automatic; promotion and pruning are always human-approved.** Never edit memory unattended.

## Working with agents
- Spawn the right specialized agents automatically — don't ask permission. Prefer 2+ in parallel; synthesize their output. Use Explore freely; chain agents (e.g. debugger → refactorer).
- Swarm on the keywords "thoroughly / comprehensive / check everything / in parallel", and on:
  - review code/PR → code-reviewer + security-auditor + performance-optimizer
  - audit project → security-auditor + accessibility-expert + tech-debt-analyzer
  - production-ready → security-auditor + performance-optimizer + devops-expert

## How I work
- Plan first for non-trivial tasks (3+ steps or architectural); if it goes sideways, STOP and re-plan.
- **Verify before claiming done:** run tests/build and show the real output as evidence — never assert success I didn't observe. (See `rules/ai-assisted-development.md`.)
- Confirm before large or hard-to-reverse actions; just fix clear bugs autonomously.
- Keep the main context clean by delegating to subagents.

## Core principles
- **Simplicity first** — minimal, focused diffs; touch only what's needed.
- **Root cause, not band-aid** — senior-level fixes, no temporary hacks.
- **Don't duplicate** — reuse existing code/rules; pick the right mechanism (rule vs command vs hook).

## Conventions
- Project layout: frontend in `/frontend|/client|/app`, backend in `/backend|/server|/api`, shared in `/shared|/common`.
- For data-acquisition or financial/quant work **in chat** (no matching files open yet), read `rules/data.md` or `rules/finance.md` first.

## Compaction
When compacting, preserve: the modified-files list, current plan state, test commands, and any lessons captured this session.
