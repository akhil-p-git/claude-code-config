# Storage & Workspace

This machine has three drives:
- `/` — root, **50 GB, keep lean** (OS only).
- `/home` — 1.8 TB, games and media.
- `/mnt/work` — the WORK_SSD, 916 GB, **all dev work**. Owned by the user, writable without sudo.

`~/dev` and `~/Dev` are symlinks into `/mnt/work`, so existing absolute paths keep working.

## Dev Work Location
- Do ALL dev work on the WORK_SSD at `/mnt/work`.
- Create new projects under `/mnt/work/dev/` (reachable as `~/dev/` via the symlink).
- Never create projects or scratch work on the root drive `/`.

## Keep Root Lean
- Root `/` is only 50 GB — never let caches, model files, datasets, build artifacts, or container/VM images land there.
- When configuring tools (Docker, pacman, Ollama, npm/pnpm, pip, cargo, etc.), point their data/cache directories at `/mnt/work`.
- Large media and games belong on `/home`.

## Git Safety
- `/home/akhil` (`$HOME`) is itself a git repo wired to a PUBLIC remote.
- Before ANY `git add` / `commit` / `push`, run `git rev-parse --show-toplevel` to confirm which repo you are in.
- NEVER run `git add -A` from `$HOME` — it would stage secrets (`.ssh`, `.env`, `.gnupg`, shell history).

## sudo Handoff
- sudo credentials cached via the `!` prompt do NOT carry into Claude's Bash tool (the timestamp is tty-scoped).
- For commands that need sudo, hand them to the user to run via `!` rather than invoking sudo directly.
