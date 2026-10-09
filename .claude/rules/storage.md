---
description: "This machine: disk layout, where work goes, toolchains, git auth, sudo"
---

# This Machine (Arch Linux)

Verified 2026-10-08 — re-check with `df -h / /home ~/work` before trusting the numbers.

| Path | Size | Use |
| --- | --- | --- |
| `/` | 49 GB, 78% used | OS only — keep lean |
| `/home` | 1.8 TB | home, media, user-space toolchains |
| `~/work` (WORK_SSD) | 916 GB | dev work: new projects go in `~/work/Dev/<name>` |

- `/mnt/work` no longer exists; any path starting with it is stale. `~/dev` is a plain directory on `/home` (this config repo and study repos).
- `/` fills up from Docker (`/var/lib/docker` is on `/`; the old `~/work/docker-data` is unused) and pacman packages. The pacman cache is already on `~/work`. Run `df -h /` before installs, image pulls, or large builds; never put caches, models, datasets, or VM/container images on `/`.
- Toolchains: Node via fnm (`--use-on-cd`; global npm packages are per Node version); Java = pacman JDK 21 (`archlinux-java`); .NET 10 SDK in `~/.dotnet`; Python via `uv` (system Python is externally managed). `/opt/cuda` is in use — never remove it.
- After a `pacman -Syu` that upgrades `linux`, Docker networking breaks (veth) until reboot: compare `uname -r` with `ls /usr/lib/modules` and ask me to reboot.
- sudo needs a real terminal, and neither the Bash tool nor `!` has one: give me the exact command to run in a separate terminal.

## Git
- Auth comes from the `gh` keyring through the credential helper. Never export `GITHUB_TOKEN` or `ANTHROPIC_API_KEY`: they override the keyring and the claude.ai login, silently breaking pushes and connectors. Third-party API keys live in `~/.secrets.env` (scripts source it; never read or print it).
- `$HOME` is not a git repo. Before any `git add`/`commit`/`push`, confirm where you are with `git rev-parse --show-toplevel`; never `git add -A` from `$HOME`. The `guard-git-secrets.sh` hook blocks staging secret-shaped files, but it is a backstop, not a substitute for looking.
