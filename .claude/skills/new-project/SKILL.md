---
name: new-project
description: Scaffold a new application or website project on the WORK_SSD (/mnt/work/dev) with this user's standards — strict TypeScript, Vitest, ESLint/Prettier, a secrets-safe .gitignore, a README, and its own git repo. Use when the user asks to start, create, scaffold, bootstrap, or set up a new project, app, website, CLI, or repo.
---

# New Project Scaffold

Create a new project on the WORK_SSD following the user's conventions. Never scaffold on the root drive or directly in $HOME.

## 1. Gather (ask only what's missing)
- Project name (kebab-case).
- Stack: `next` (React web app), `react-vite` (SPA), `ts-node` (library/CLI/API), or `python`.
- One-line purpose (for the README).

## 2. Location
- Create at `/mnt/work/dev/<name>` (reachable as `~/dev/<name>` via symlink). Confirm it does not already exist.
- Never create under `/` or directly in `$HOME`. See the storage rules.

## 3. Scaffold by stack (prefer official scaffolders, then apply standards)
- **next**: `npx create-next-app@latest <name> --ts --eslint --app --src-dir`
- **react-vite**: `npm create vite@latest <name> -- --template react-ts`
- **ts-node**: `npm init -y`; add TypeScript + tsx/tsup; set `"type": "module"`.
- **python**: `uv init <name>` (or venv + pyproject); add ruff + pytest.

## 4. Apply standards (all stacks)
- TypeScript: `"strict": true` in tsconfig. Python: type hints + ruff + mypy.
- Testing: add Vitest (JS/TS) or pytest (Python) with one example test.
- Lint/format: ESLint + Prettier (JS/TS) or ruff (Python).
- `.gitignore` must exclude `.env`, `.env.*` (keep `!.env.example`), `*.key`, `*.pem`, `secrets/`, `node_modules/`, `dist/`, `.venv/`, and build/cache dirs.
- Add `.env.example` (never a real `.env`). Add `README.md` with purpose, setup, run, and test commands.

## 5. Initialize git
- `git init` so the project gets its OWN repo — do NOT rely on the $HOME repo (confirm `git rev-parse --show-toplevel` points at the new project).
- First commit with Conventional Commits: `chore: initial project scaffold`.
- Do NOT add a remote or push unless asked.

## 6. Verify
- Install deps, then run the test command once to confirm the scaffold is green. Report the result and the project path.
