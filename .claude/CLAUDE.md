# Global Standards

> Personal Claude Code config, version-controlled at `github.com/akhil-p-git/claude-code-config`
> (local `~/dev/claude-code-config`, symlinked into `~/.claude/`).
> **Whenever you change any config file here (this file, `rules/`, `commands/`, `skills/`, `hooks/`, `settings.json`), commit and push it.**
> A `SessionStart` hook announces uncommitted/unpushed config changes so this can't silently rot.

## How this config is organized
- **This file** — universal rules, loaded every session. Keep it lean (<~100 lines): bloat makes me ignore rules.
- **`rules/*.md`** — topic rules. `engineering`, `security`, `storage`, `ai-assisted-development`, `research` load always; the rest (`python`, `react`, `testing`, …) load only when their `paths:` globs match. Don't restate their content here.
- **`commands/*.md`** and **`skills/*/SKILL.md`** — both produce `/name`. Use a **skill** when it needs bundled scripts/resources or should auto-trigger; a **command** for a simple prompt. A skill MUST be a directory containing `SKILL.md` — a bare `.md` in `skills/` is silently ignored.
- **`hooks/`** — deterministic automation wired in `settings.json`. Advisory text can't enforce; hooks can. Prefer a hook whenever a rule must hold every time.
- **`knowledge/*.md`** — long reference docs, pulled in on demand via `@knowledge/...` from a rule.

## Git operations
`gh` holds a real token in the system keyring and git uses it via the gh credential helper.
Do **not** export `GITHUB_TOKEN` — an exported value overrides the keyring, so a stale or
placeholder one silently breaks every push with "Bad credentials". Same for `ANTHROPIC_API_KEY`:
setting it overrides the claude.ai subscription login and disables connectors and Remote Control.
Plain `git push` / `git fetch` work; no env-var prefix needed. Secrets belong in `~/.secrets.env`.

## Self-improvement loop (this config iterates on itself)
1. **Capture (automatic):** a `UserPromptSubmit` hook appends your corrections to `~/.claude/lessons-inbox.md`.
2. **Promote (`/reflect`):** clusters the inbox into *generalized* rules, shows a diff, and on your approval writes them into this file or the right `rules/*.md`, clears the inbox, and pushes.
3. **Prune (`/reflect --prune`):** removes stale/contradictory rules and keeps this file lean.

Rule: **capture is automatic; promotion and pruning are always human-approved.** Never edit memory unattended.
When you learn something durable mid-session — a corrected assumption, a gotcha, a fact that
outlives this task — say so and offer to promote it. Don't wait to be asked.

## How I work
- Plan first for non-trivial tasks (3+ steps or architectural); if it goes sideways, STOP and re-plan.
- **Verify before claiming done:** run the tests/build and show the real output as evidence — never assert success I didn't observe. A `Stop` hook flags source edits that ended with no check run; export `CLAUDE_VERIFY_GATE=block` to make it a hard gate.
- Confirm before large or hard-to-reverse actions; just fix clear bugs autonomously.
- Prefer the root cause over the workaround. If I'm adding a workaround, say why the real fix is out of reach.
- Keep the main context clean by delegating to subagents; watch the context bar in the status line and `/clear` between unrelated tasks.

## Working with agents
- Spawn the right specialized agents automatically — don't ask permission. Prefer 2+ in parallel; synthesize their output. Use Explore freely; chain agents (e.g. debugger → refactorer).
- Subagents run in the **background** by default and can nest ~3 deep — launch them and keep working rather than blocking.
- Swarm on "thoroughly / comprehensive / check everything / in parallel", and on:
  - review code/PR → code-reviewer + security-auditor + performance-optimizer (or the bundled `/code-review`)
  - audit project → security-auditor + accessibility-expert + tech-debt-analyzer
  - production-ready → security-auditor + performance-optimizer + devops-expert
- Review the diff with a **fresh-context** reviewer before calling it done; it isn't biased toward code it just wrote. Tell it to report only gaps affecting correctness or stated requirements — a reviewer asked for findings will invent them.

## Core principles
- **Simplicity first** — minimal, focused diffs; touch only what's needed.
- **Root cause, not band-aid** — senior-level fixes, no temporary hacks.
- **Don't duplicate** — reuse existing code/rules; pick the right mechanism (rule vs command vs skill vs hook).

## Conventions
- Project layout: frontend in `/frontend|/client|/app`, backend in `/backend|/server|/api`, shared in `/shared|/common`.
- For data-acquisition or financial/quant work **in chat** (no matching files open yet), read `rules/data.md` or `rules/finance.md` first.

## Compaction
When compacting, preserve: the modified-files list, current plan state, test commands and their
real output, and any lessons captured this session. (A `PreCompact` hook restates this and injects
the live modified-files list, so it survives as data rather than as a promise.)
