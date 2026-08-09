#!/usr/bin/env bash
# SessionStart hook — surfaces, at the one moment it will actually be read:
#   1. pending lessons waiting for /reflect (the "promote" half of the loop)
#   2. UNCOMMITTED / UNPUSHED changes in the config repo itself
#   3. the current git branch
#
# (2) exists because CLAUDE.md says "whenever you change any config file here,
# commit and push it" — and the failure mode of that rule is silent: an edit made
# late in a session simply never gets pushed and is lost on the next machine.
# Announcing the drift at startup makes it self-correcting.
#
# stdout is injected into the session context. ALWAYS exits 0. Must stay fast:
# no network calls, and git work is confined to the local object store.

INBOX="${HOME}/.claude/lessons-inbox.md"
CONFIG_REPO="${HOME}/dev/claude-code-config"

if [ -f "$INBOX" ]; then
  n="$(grep -cE '^- \[' "$INBOX" 2>/dev/null || echo 0)"
  if [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    echo "📝 ${n} pending lesson(s) in lessons-inbox.md — run /reflect to review & promote them."
  fi
fi

if [ -d "$CONFIG_REPO/.git" ]; then
  dirty="$(git -C "$CONFIG_REPO" status --porcelain 2>/dev/null | head -12)"
  if [ -n "$dirty" ]; then
    c="$(printf '%s\n' "$dirty" | grep -c .)"
    echo "⚠️  claude-code-config has ${c} uncommitted change(s) — commit & push (CLAUDE.md rule):"
    printf '%s\n' "$dirty" | sed 's/^/     /'
  fi
  # Unpushed commits: compare against the recorded upstream only. No fetch —
  # a SessionStart hook must never block startup on the network.
  ahead="$(git -C "$CONFIG_REPO" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)"
  if [ "${ahead:-0}" -gt 0 ] 2>/dev/null; then
    echo "⬆️  claude-code-config has ${ahead} unpushed commit(s) — push it."
  fi
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -n "$branch" ] && echo "📍 git branch: ${branch}"

exit 0
