#!/usr/bin/env bash
# PreCompact hook — deterministic version of the CLAUDE.md "Compaction" section.
# Compaction is exactly when advisory instructions are most likely to be dropped,
# so restate what must survive at the moment the summary is written, and include
# the live modified-files list so it survives as data rather than as a promise.
# ALWAYS exits 0 — never block a compaction.

input="$(cat 2>/dev/null)" || exit 0
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

echo "When compacting, preserve verbatim: the modified-files list, current plan state,"
echo "exact test/build commands and their last real output, and any lessons captured"
echo "this session. Prefer dropping narration over dropping these."

top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$top" ]; then
  files="$(git -C "$top" status --porcelain 2>/dev/null | head -40)"
  if [ -n "$files" ]; then
    echo
    echo "Uncommitted changes in ${top} at compaction time:"
    printf '%s\n' "$files" | sed 's/^/  /'
  fi
fi

exit 0
