#!/usr/bin/env bash
# UserPromptSubmit hook — the "capture" half of the self-improvement loop.
# When the user's prompt looks like a correction, append it to the lessons inbox
# so `/reflect` can later cluster, generalize, and promote it into CLAUDE.md / rules.
# Reads the hook JSON payload from stdin. ALWAYS exits 0 (never blocks a prompt).

INBOX="${HOME}/.claude/lessons-inbox.md"

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)"
[ -z "$prompt" ] && exit 0

lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"

# Correction / feedback signals. Kept fairly precise to limit false positives.
pattern="^(no\b|nope|nah|don'?t|do not|stop|actually|wrong|that'?s not|that is not|that'?s wrong|incorrect|not what|i said|i asked|why did you|you (should|were|did ?n'?t|keep|always|never)|use .* not |don'?t use|instead of|next time|from now on|please stop|that broke|you broke|undo|revert)"

if printf '%s' "$lc" | grep -qE "$pattern"; then
  if [ ! -f "$INBOX" ]; then
    printf '# Lessons Inbox\n\nRaw, auto-captured corrections. Run `/reflect` to cluster, generalize, and promote\nthe durable ones into CLAUDE.md / rules, then clear this file. Machine-local; gitignored.\n\n' > "$INBOX"
  fi
  ts="$(date -Iseconds 2>/dev/null || date)"
  oneline="$(printf '%s' "$prompt" | tr '\n' ' ' | cut -c1-500)"
  printf -- '- [%s] %s\n' "$ts" "$oneline" >> "$INBOX"
fi

exit 0
