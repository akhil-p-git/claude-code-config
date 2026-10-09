#!/usr/bin/env bash
# SessionStart(compact|resume): re-inject LIVE working state right after a compaction
# (or when resuming), so it survives as data rather than as a promise.
#
# Replaces precompact-preserve.sh: a PreCompact hook's stdout is NOT added to Claude's
# context (only UserPromptSubmit, UserPromptExpansion, SessionStart and PostModelSwitch
# stdout is), so restating "preserve X" there reached only the debug log. What steers the
# summary itself is the "Compaction" section of CLAUDE.md; this hook restores the facts.
#
# Plain stdout = context for Claude. Written as factual statements (imperative "system"
# wording can trip prompt-injection defenses). Fast, local-only, ALWAYS exits 0.

input="$(cat 2>/dev/null)"
IFS=$'\x1f' read -r src sid cwd < <(jq -r '[.source // "", .session_id // "", .cwd // ""] | join("\u001f")' <<<"$input" 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"
G() { git -C "$cwd" -c core.fsmonitor=false --no-optional-locks "$@" 2>/dev/null; }

printf 'Working state re-read after %s (SessionStart hook, %s):\n' "${src:-start}" "$(date '+%Y-%m-%d %H:%M')"
top="$(G rev-parse --show-toplevel)"
if [ -n "$top" ]; then
  branch="$(G symbolic-ref --short -q HEAD || G rev-parse --short HEAD)"
  ab="$(G rev-list --left-right --count '@{upstream}...HEAD' | awk '{ if ($1 || $2) print $2 " ahead, " $1 " behind upstream" }')"
  printf -- '- Repository %s on branch %s%s\n' "$top" "$branch" "${ab:+ ($ab)}"
  status="$(G status --porcelain --untracked-files=normal)"
  if [ -n "$status" ]; then
    n="$(grep -c . <<<"$status")"
    printf -- '- %s uncommitted path(s) (git status --porcelain):\n' "$n"
    head -40 <<<"$status" | sed 's/^/    /'; [ "$n" -gt 40 ] && echo "    ... ($((n - 40)) more)"
  else
    echo "- Working tree clean"
  fi
  printf -- '- Last commits:\n'; G log --oneline -5 | sed 's/^/    /'
fi

st="${XDG_RUNTIME_DIR:-/tmp}/claude-verify/$sid"
if [ -n "$sid" ] && [ -s "$st/log" ]; then
  IFS=$'\t' read -r ts res c < <(tail -1 "$st/log")
  printf -- '- Last recorded check: `%s` %s at %s\n' "${c:0:200}" "$([ "$res" = ok ] && echo passed || echo FAILED)" "$(date -d "@$ts" '+%H:%M' 2>/dev/null)"
fi

inbox="$HOME/.claude/lessons-inbox.md"
if [ -f "$inbox" ]; then
  les="$(grep -F -- "- [$(date +%Y-%m-%d)" "$inbox" | tail -5 | cut -c1-220)"
  [ -n "$les" ] && { echo "- Corrections the user made today (lessons inbox):"; sed 's/^/    /' <<<"$les"; }
fi

plan="$(ls -t "${top:-/nonexistent}"/docs/plans/*.md "${top:-/nonexistent}"/.claude/plans/*.md "$HOME"/.claude/plans/*.md 2>/dev/null | head -1)"
[ -n "$plan" ] && [ -n "$(find "$plan" -mmin -720 2>/dev/null)" ] && printf -- '- Most recently updated plan file: %s\n' "$plan"
exit 0
