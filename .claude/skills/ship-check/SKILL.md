---
name: ship-check
description: Pre-push quality gate that runs lint, type-check, tests, dependency audit, and a secret scan against the current project, then reports pass/fail. Use before pushing or committing, or when the user asks to "ship-check", run pre-push checks, verify a project is ready to push, or wants a final quality and security gate.
---

# Ship Check

A pre-push gate. Run it from the project root you want to check; it auto-detects the stack, runs every gate (continuing through failures so the report is complete), and exits non-zero if any gate fails.

## Run
```bash
bash ~/.claude/skills/ship-check/scripts/ship-check.sh
```
It operates on the current working directory — `cd` into the target repo first. For projects with a virtualenv or local toolchain, activate it first (e.g. `source .venv/bin/activate`) so the gates use the project's `pytest`/tools, not the system ones.

## What it checks
- **Secrets**: no `.env` / `*.key` / `*.pem` / credential files staged; `gitleaks` scan if installed; greps the diff for obvious key patterns (AWS keys, private keys, `API_KEY=`).
- **JS/TS** (package.json): `lint`, type-check (`tsc --noEmit`), `test`, and dependency `audit` — using the detected package manager (pnpm / npm / yarn / bun via lockfile).
- **Python** (pyproject.toml / requirements): `ruff`, `mypy`, `pytest`, `pip-audit` — whichever are available.

## Interpreting results
- The script prints a ✓ / ✗ / ⚠ SKIP line per gate and a final summary.
- Missing tools are reported as **SKIPPED**, not failures. If a relevant gate is skipped, suggest installing the tool.
- On any ✗, fix the reported issue and re-run. Do not push past a red gate.
