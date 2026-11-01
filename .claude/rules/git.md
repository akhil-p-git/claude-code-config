---
description: "Git auth, secrets files and where to run git, on any machine"
---

# Git

- Auth comes from the `gh` keyring through the credential helper. Never export `GITHUB_TOKEN` or `ANTHROPIC_API_KEY`: they override the keyring and the claude.ai login, silently breaking pushes and connectors. Third-party API keys live in `~/.secrets.env` (scripts source it; never read or print it).
- `$HOME` is not a git repo. Before any `git add`/`commit`/`push`, confirm where you are with `git rev-parse --show-toplevel`; never `git add -A` from `$HOME`. The `guard-git-secrets.sh` hook blocks staging secret-shaped files, but it is a backstop, not a substitute for looking.
