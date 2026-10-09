# claude-code-config

My global Claude Code configuration: instructions, rules, skills, subagents, hooks, and settings, version-controlled and symlinked into `~/.claude/`. Rebuilt in October 2026 from a survey of Anthropic's own guidance, the Claude Code team's published setups, the strongest public CLAUDE.md/AGENTS.md files, and the agent/skill/hook ecosystems — keeping only what measurably changes behavior.

## Design in one paragraph
Claude Opus 5.x already knows general engineering practice, so always-on context is reserved for facts and gotchas it can't infer (about 12 KB: `CLAUDE.md` plus three small rules). Everything else loads on demand: language and topic rules are path-scoped, procedures are skills (side-effect ones are slash-only and cost nothing per turn), domain playbooks sit behind three hub skills, isolated or fresh-eyes work goes to a small set of trigger-described subagents, and anything that must hold every time is a hook or a permission rule rather than prose.

## Layout
| Path | What | Loads |
| --- | --- | --- |
| `.claude/CLAUDE.md` | Priorities, honesty, change discipline, verification, git safety, delegation, routing index. Maintainer notes live in an HTML comment (stripped, zero tokens). | Every session |
| `.claude/rules/{storage,research,writing}.md` | Machine facts; citation discipline; writing for people (anti-slop, commits, PRs) | Every session |
| `.claude/rules/*.md` (others) | `python`, `javascript-typescript`, `react`, `web-frontend`, `nodejs-backend`, `java`, `dotnet`, `c`, `database`, `api-design`, `testing`, `accessibility`, `security`, `engineering`, `devops`, `data`, `finance` | When a matching file is read or edited |
| `.claude/skills/` | See below | Description listed; body on use |
| `.claude/agents/` | 20 subagents (see below) | Description listed; body on delegation |
| `.claude/commands/` | `reflect`, `commit-push-pr`, `handoff`, `catchup`, `security-check`, `ask`, `split-project` | Slash-only |
| `.claude/hooks/` | Guards, gates, formatter, context restore (see below); tests in `hooks/tests/` | Wired in `settings.json` |
| `.claude/settings.json` | Permissions, hooks, plugins, env | Every session |
| `.claude/statusline.sh` | Model · effort · cwd · branch · PR / context bar · 5h & 7d usage · cost | Every render |

### Skills
- **Workflow:** `spec` → `write-plan` → `execute-plan` (plan file is the ledger) · `research-codebase` · `diagnose` (reproduce first) · `review-diff` (review against intent, then triage) · `commit` · `deploy` · `release` · `incident` (respond / postmortem / SLO alerting) · `ship-check` · `new-project` · `a11y-audit` · `tech-docs` (Diátaxis) · `ui-craft` · `ask-model` (second opinion from GPT/Gemini/Grok/DeepSeek/Perplexity via OpenRouter).
- **Domain hubs** (one listing entry each, routing to `references/*.md`): `marketing` (positioning, copy/CRO, SEO + AI search, launches, email, content, pricing), `product` (PRDs, interviews, tracking plans, experiments), `finance` (backtests with tested PSR/DSR/PBO scripts, market data, SEC EDGAR, statements, valuation, portfolio risk, personal finance).

### Subagents
Reviewers and auditors (read-only, Bash backstopped by `readonly-bash-guard.sh`): `code-reviewer`, `security-auditor`, `silent-failure-hunter`, `ui-reviewer`, `dependency-auditor`, `tech-debt-analyzer`, `backtest-auditor`, `data-analyst`, `architect`, `researcher`. Runners and writers: `verifier`, `debugger`, `test-writer`, `refactorer`, `performance-optimizer`, `docs-writer`, `devops-expert`, `database-expert`, `llm-eval-designer`, `copy-editor`. Each description says when to use it and what to use instead.

### Hooks
| Hook | Event | Does |
| --- | --- | --- |
| `guard-destructive.sh` (+ `.jq`) | PreToolUse Bash/Monitor | Parses the command (quotes, heredocs, `bash -c`, `$(…)`) and denies catastrophic actions (`rm -rf ~`, force-push to main, `DROP DATABASE`, `curl \| sh`, `reset --hard` over uncommitted work) or asks for risky ones (prod deploys, publishes, force-push to feature branches). Fails closed. Audit log in `~/.claude/logs/guard-decisions.jsonl`. |
| `guard-git-secrets.sh` | PreToolUse Bash | Blocks staging secret-shaped paths |
| `secret-scan-git.sh` | PreToolUse Bash (`git *`) | Scans exactly what a commit/push would publish (gitleaks if installed) |
| `protect-files.sh` | PreToolUse Edit/Write | Keeps hands off `.env*`, lockfiles, `.git/`, generated files |
| `format-on-edit.sh` | PostToolUse Edit/Write | Formats only the touched file with the project's own formatter |
| `note-verification.sh` + `verify-gate.sh` | PostToolUse(+Failure) Bash, Stop | Records checks; nudges once if source changed since the last passing check (`CLAUDE_VERIFY_GATE=block\|warn\|off`) |
| `capture-lesson.sh` | UserPromptSubmit | Appends corrections to `~/.claude/lessons-inbox.md` for `/reflect` |
| `session-start.sh` / `session-context.sh` | SessionStart startup\|clear / compact\|resume | Config-drift and inbox notices / re-injects live repo state after compaction |
| `bash-audit-log.sh` | PostToolUse Bash (async) | Redacted command log in `~/.claude/logs/` |
| `agent-write-guard.sh`, `readonly-bash-guard.sh` | Agent-scoped | Keep read-only agents read-only |

Run all hook tests: `bash .claude/hooks/tests/run-all.sh && bash .claude/hooks/tests/test-agent-guards.sh`.

## Install on a machine
```bash
git clone https://github.com/akhil-p-git/claude-code-config ~/dev/claude-code-config
~/dev/claude-code-config/setup-claude.sh   # symlinks CLAUDE.md, settings.json, rules, skills, agents, commands, templates; installs enabled plugins
```
Each of `rules/` and `skills/` needs its own symlink — Claude Code never discovers them relative to a symlinked `CLAUDE.md`. Verify from a neutral directory (not inside this repo, where `.claude/` also loads as project config): start `claude` in `/tmp` and check `/context` or `/memory`.

Requirements: `jq`, `git`, `gh` (authenticated via `gh auth login`; never export `GITHUB_TOKEN`), Python 3, Node via fnm. Optional: `gitleaks`, `shellcheck`, language servers for the LSP plugins.

## Plugins
Enabled in `settings.json`: `vercel`, `code-simplifier`, `frontend-design`, `security-guidance` (per-turn Opus review off via `ENABLE_STOP_REVIEW=0`; commit/push review on), `context7`, `clangd-lsp`. Enabling a plugin doesn't install it; `setup-claude.sh` installs any enabled plugin that's missing.
Worth enabling once their binaries exist: `typescript-lsp` (`typescript-language-server`), `pyright-lsp` (`pyright`), `jdtls-lsp`, `csharp-lsp`.
On demand (enable, use, disable): `claude-security` (whole-repo audit), `pr-review-toolkit`, Trail of Bits `differential-review` / `supply-chain-risk-auditor`, coreyhaines31 `marketingskills` (project scope only — 50 skills overflow the listing budget), `anthropics/financial-services` (valuation models).
Installs of skills and plugins require approval (`ask` rules in `settings.json`).

## Keeping it good
- Corrections are captured automatically; run `/reflect` to promote the durable ones (human-approved, with an enforcement ladder: linter → hook/permission → skill → path-scoped rule → CLAUDE.md).
- After every model launch and every few months: `/doctor`, `/skill-doctor`, `/context`, `/reflect --prune`, `claude plugin validate ~/.claude/agents`, and the hook tests. Delete instructions the current model no longer needs.
- `.claude/skills/synced/` (account-synced, partly proprietary) and hook test fixtures are gitignored; this repo is public.
- MCP notes: [MCP.md](MCP.md). API keys for `ask-model`: see [.env.example](.env.example) (real values go in `~/.secrets.env`).
