#!/usr/bin/env bash
# UserPromptSubmit hook — the "capture" half of the self-improvement loop.
# When the user's prompt looks like a correction, append it to the lessons inbox
# so `/reflect` can later cluster, generalize, and promote it into CLAUDE.md / rules.
# Reads the hook JSON payload from stdin. ALWAYS exits 0 (never blocks a prompt).
#
# Only the FIRST non-empty line is tested. `grep -E '^...'` anchors to every line,
# so testing the whole prompt captured any paste that happened to contain a line
# starting with "No," / "Don't" / "Actually" — a quoted chat log or terminal dump
# would land in the inbox as a fake lesson. A correction is something the user
# *opens* with, so the first line is the right and much cheaper signal.

INBOX="${HOME}/.claude/lessons-inbox.md"

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)"
[ -z "$prompt" ] && exit 0

# First non-empty, non-quoted line only.
first="$(printf '%s\n' "$prompt" | grep -vE '^[[:space:]]*$' | head -1)"
[ -z "$first" ] && exit 0

# Skip pasted material: shell prompts, diffs, code fences, logs, slash commands.
printf '%s' "$first" | grep -qE '^[[:space:]]*(```|\$ |# |//|/[a-z]|[-+]{3} |@@ |\[[0-9]{4}-|[A-Za-z]+@[A-Za-z]+|\[[a-z]+@)' && exit 0

lc="$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')"

# Correction / feedback signals. Kept fairly precise to limit false positives.
pattern="^(no\b|nope|nah|don'?t|do not|stop|actually|wrong|that'?s not|that is not|that'?s wrong|incorrect|not what|i said|i asked|why did you|you (should|were|did ?n'?t|keep|always|never)|use .* not |don'?t use|instead of|next time|from now on|please stop|that broke|you broke|undo|revert)"

printf '%s' "$lc" | grep -qE "$pattern" || exit 0

if [ ! -f "$INBOX" ]; then
  printf '# Lessons Inbox\n\nRaw, auto-captured corrections. Run `/reflect` to cluster, generalize, and promote\nthe durable ones into CLAUDE.md / rules, then clear this file. Machine-local; gitignored.\n\n' > "$INBOX"
fi

oneline="$(printf '%s' "$prompt" | tr '\n' ' ' | tr -s ' ' | cut -c1-500)"

# Don't record the same correction twice (repeated prompts, resumed sessions).
grep -Fq -- "$oneline" "$INBOX" 2>/dev/null && exit 0

ts="$(date -Iseconds 2>/dev/null || date)"
printf -- '- [%s] %s\n' "$ts" "$oneline" >> "$INBOX"

exit 0
