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
# Also skip harness-injected turns (UserPromptSubmit fires for background-agent reports,
# teammate/cross-session messages and pastes, which arrive wrapped in <tags>).
printf '%s' "$first" | grep -qE '^[[:space:]]*(<|```|\$ |# |//|/[a-z]|[-+]{3} |@@ |\[[0-9]{4}-|[A-Za-z]+@[A-Za-z]+|\[[a-z]+@)' && exit 0

lc="$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')"

# Correction / feedback signals. Kept fairly precise to limit false positives.
# Strong openers are corrections on their own. Weak openers ("stop", "actually", "no ...")
# also start ordinary instructions ("Stop the dev server", "Actually, also add X"), so they
# count only with a correction cue on the same line.
strong="^(no[,.!]|nope[,.!]|don'?t|do not|wrong|that'?s not|that is not|that'?s wrong|incorrect|not what|i said|i asked|why did you|you (should|were|did ?n'?t|keep|always|never)|use .* not |don'?t use|instead of|next time|from now on|please stop|that broke|you broke)"
weak="^(no\b|nope|nah|stop|actually|undo|revert)"
cue="\b(not|n'?t|never|instead|wrong|should|again|always|said|asked|broke|mistake|told you)\b"
if ! printf '%s' "$lc" | grep -qE "$strong"; then
  printf '%s' "$lc" | grep -qE "$weak" && printf '%s' "$lc" | grep -qE "$cue" || exit 0
fi

if [ ! -f "$INBOX" ]; then
  printf '# Lessons Inbox\n\nRaw, auto-captured corrections. Run `/reflect` to cluster, generalize, and promote\nthe durable ones into CLAUDE.md / rules, then clear this file. Machine-local; gitignored.\n\n' > "$INBOX"
fi

oneline="$(printf '%s' "$prompt" | tr '\n' ' ' | tr -s ' ' | cut -c1-500)"

# Don't record the same correction twice (repeated prompts, resumed sessions).
grep -Fq -- "$oneline" "$INBOX" 2>/dev/null && exit 0

ts="$(date -Iseconds 2>/dev/null || date)"
printf -- '- [%s] %s\n' "$ts" "$oneline" >> "$INBOX"

exit 0
