#!/usr/bin/env bash
# Custom status line. The docs call the context window "the most important
# resource to manage" and performance degrades as it fills — so show it
# continuously rather than discovering it at auto-compact time.
#
# Line 1: model · cwd · git branch (+dirty marker)
# Line 2: colour-coded context bar · session cost
#
# Receives session JSON on stdin. Must be fast and must never print an error.
# Test:  echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp"},
#               "context_window":{"used_percentage":25},"cost":{"total_cost_usd":0.42}}' \
#          | .claude/statusline.sh

input="$(cat 2>/dev/null)"

get() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

model="$(get '.model.display_name')"
dir="$(get '.workspace.current_dir')"
pct="$(get '.context_window.used_percentage')"
cost="$(get '.cost.total_cost_usd')"

[ -z "$model" ] && model="claude"
[ -z "$dir" ] && dir="$PWD"

DIM=$'\033[2m'; RESET=$'\033[0m'; BOLD=$'\033[1m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BLUE=$'\033[34m'

# ---- line 1: where am I ----
short="${dir/#$HOME/\~}"
line1="${BOLD}${model}${RESET} ${DIM}·${RESET} ${BLUE}${short}${RESET}"

branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -n "$branch" ]; then
  mark=""
  git -C "$dir" diff --quiet 2>/dev/null && git -C "$dir" diff --cached --quiet 2>/dev/null || mark="*"
  line1="${line1} ${DIM}·${RESET} ${branch}${mark}"
fi

# ---- line 2: context budget + cost ----
p="${pct%%.*}"; [ -z "$p" ] && p=0
case "$p" in (*[!0-9]*) p=0 ;; esac
[ "$p" -gt 100 ] 2>/dev/null && p=100

if   [ "$p" -ge 80 ]; then col="$RED"
elif [ "$p" -ge 60 ]; then col="$YELLOW"
else                       col="$GREEN"
fi

width=20
filled=$(( p * width / 100 ))
bar=""
i=0; while [ "$i" -lt "$width" ]; do
  if [ "$i" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
  i=$((i+1))
done

line2="${col}${bar}${RESET} ${col}${p}%${RESET} ${DIM}context${RESET}"
[ "$p" -ge 80 ] && line2="${line2} ${RED}— /clear or /compact soon${RESET}"

if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  line2="${line2} ${DIM}·${RESET} \$$(printf '%.2f' "$cost" 2>/dev/null || printf '%s' "$cost")"
fi

printf '%s\n%s' "$line1" "$line2"
