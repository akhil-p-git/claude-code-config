#!/usr/bin/env bash
# SessionStart hook — surfaces pending lessons + current git branch into context,
# so I'm nudged to run /reflect when corrections have piled up. Non-blocking.
# stdout is injected into the session context. ALWAYS exits 0.

INBOX="${HOME}/.claude/lessons-inbox.md"

if [ -f "$INBOX" ]; then
  n="$(grep -cE '^- \[' "$INBOX" 2>/dev/null || echo 0)"
  if [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    echo "📝 ${n} pending lesson(s) in lessons-inbox.md — run /reflect to review & promote them."
  fi
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -n "$branch" ] && echo "📍 git branch: ${branch}"

exit 0
