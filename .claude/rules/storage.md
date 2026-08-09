---
description: "Storage layout, dev-work location, and git/sudo safety for this machine"
---

# Storage & Workspace

Verified 2026-08-09. Re-check with `lsblk` / `df -h` before trusting these numbers.

| Path | Device | Size | Use |
| --- | --- | --- | --- |
| `/` | nvme1n1p2 | 50 GB | OS only — **keep lean** |
| `/home` | nvme1n1p3 | 1.8 TB | home, games, media |
| `~/work` | nvme0n1 (label `WORK_SSD`) | 931 GB | **all dev work** |

`~/work` is mounted from `/etc/fstab` (`nofail`). **The WORK_SSD moved: it used to be
`/mnt/work`, which no longer exists.** `~/dev` and `~/Dev` are no longer symlinks into it —
they are ordinary directories on `/home`. Any path starting `/mnt/work` is stale.

## Dev Work Location
- Do dev work on the WORK_SSD: create new projects under `~/work/dev/`.
- Existing projects live there (`~/work/dev/localAI`, `Personal-Portfolio`, …).
- Never create projects or scratch work on the root drive `/`.

## Keep Root Lean
- `/` is 50 GB and was **95% full (2.4 GB free) on 2026-08-09** — check `df -h /` before
  any install, image pull, or large build, and clear space rather than filling it.
- Never let caches, model files, datasets, build artifacts, or container/VM images land on `/`.
  Point tool data/cache dirs (Docker, pacman, Ollama, npm/pnpm, pip, cargo) at `~/work`
  (`~/work/docker-data` and `~/work/pacman-cache` already exist).
- Large media and games belong on `/home`.

## Git Safety
- `$HOME` is **not** a git repo (it was one previously; the remote and repo are gone).
  If one is ever re-initialized there, never run `git add -A` from `$HOME` — it would stage
  `.ssh`, `.env`, `.gnupg`, and shell history.
- Before ANY `git add` / `commit` / `push`, run `git rev-parse --show-toplevel` to confirm
  which repo you are in. A `PreToolUse` hook (`guard-git-secrets.sh`) blocks staging of
  secret-shaped paths, but it is a backstop, not a substitute for looking.
- **Two copies of `claude-code-config` exist**: `~/dev/claude-code-config` is the live one
  (`~/.claude/*` symlinks point at it); `~/work/dev/claude-code-config` is a stale checkout.
  Always edit the `~/dev` one.

## sudo Handoff
- sudo credentials cached via the `!` prompt do NOT carry into Claude's Bash tool (the
  timestamp is tty-scoped).
- For commands that need sudo, hand them to the user to run via `!` rather than invoking
  sudo directly.
