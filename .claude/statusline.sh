#!/usr/bin/env bash
# Custom status line (v2). The context window is the resource to manage, and on a
# claude.ai subscription the 5-hour / weekly limits are the budget, so both stay visible.
#
# Line 1: model · effort · cwd · git branch(+dirty) · open PR (#n, review state)
# Line 2: colour-coded context bar · 5h / 7d usage with reset countdown · est. cost
#
# One jq call per render; git state cached per session for 5 s and read with
# --no-optional-locks so the status line never takes .git/index.lock while Claude commits.
# Must be fast and must never print an error. Test:
#   echo '{"session_id":"t","model":{"display_name":"Opus 5.5"},"effort":{"level":"high"},
#          "workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":63},
#          "rate_limits":{"five_hour":{"used_percentage":41,"resets_at":2000000000}},
#          "cost":{"total_cost_usd":1.2}}' | ./statusline.sh

input="$(cat 2>/dev/null)"
IFS=$'\x1f' read -r model effort dir pct cost sid h5 h5r d7 d7r prn prs < <(jq -r '[
  (.model.display_name // "claude"), (.effort.level // ""), (.workspace.current_dir // .cwd // ""),
  ((.context_window.used_percentage // 0) | floor), (.cost.total_cost_usd // 0), (.session_id // "x"),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end), (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end), (.rate_limits.seven_day.resets_at // ""),
  (.pr.number // ""), (.pr.review_state // "")] | map(tostring | gsub("[\n\u001f]"; " ")) | join("\u001f")' <<<"$input" 2>/dev/null)
[ -n "$dir" ] || dir="$PWD"

DIM=$'\033[2m'; RESET=$'\033[0m'; BOLD=$'\033[1m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BLUE=$'\033[34m'
col() { if [ "${1:-0}" -ge 80 ]; then printf '%s' "$RED"; elif [ "${1:-0}" -ge 60 ]; then printf '%s' "$YELLOW"; else printf '%s' "$GREEN"; fi; }
left() {  # seconds until epoch $1 as 2h05m / 3d4h
  local s=$(( ${1:-0} - $(date +%s) )); [ "$s" -le 0 ] && return
  if [ $s -ge 86400 ]; then printf '%dd%dh' $((s/86400)) $((s%86400/3600)); else printf '%dh%02dm' $((s/3600)) $((s%3600/60)); fi
}

# ---- git (cached) ----
cache="${XDG_RUNTIME_DIR:-/tmp}/claude-statusline-$sid"
if [ ! -f "$cache" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) )) -gt 5 ]; then
  b="$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)"
  d=""; [ -n "$b" ] && [ -n "$(git -C "$dir" --no-optional-locks status --porcelain --untracked-files=no 2>/dev/null | head -1)" ] && d="*"
  printf '%s\x1f%s\n' "$b" "$d" > "$cache" 2>/dev/null
fi
IFS=$'\x1f' read -r branch dirty < "$cache" 2>/dev/null

# ---- line 1 ----
line1="${BOLD}${model}${RESET}"
[ -n "$effort" ] && line1="$line1 ${DIM}${effort}${RESET}"
line1="$line1 ${DIM}·${RESET} ${BLUE}${dir/#$HOME/\~}${RESET}"
[ -n "$branch" ] && line1="$line1 ${DIM}·${RESET} ${branch}${dirty}"
if [ -n "$prn" ]; then
  case "$prs" in approved) pc="$GREEN";; changes_requested) pc="$RED";; *) pc="$DIM";; esac
  line1="$line1 ${DIM}·${RESET} ${pc}#${prn}${prs:+ ${prs//_/ }}${RESET}"
fi

# ---- line 2 ----
p="${pct:-0}"; case "$p" in (*[!0-9]*|'') p=0;; esac; [ "$p" -gt 100 ] && p=100
c="$(col "$p")"; filled=$(( p / 5 )); bar=""
for ((i = 0; i < 20; i++)); do if [ $i -lt $filled ]; then bar+="█"; else bar+="░"; fi; done
line2="${c}${bar} ${p}%${RESET} ${DIM}ctx${RESET}"
[ "$p" -ge 80 ] && line2="$line2 ${RED}/compact or /clear soon${RESET}"
if [ -n "$h5" ]; then line2="$line2 ${DIM}·${RESET} $(col "$h5")5h ${h5}%${RESET}"; r="$(left "$h5r")"; [ -n "$r" ] && line2="$line2 ${DIM}↻${r}${RESET}"; fi
if [ -n "$d7" ]; then line2="$line2 ${DIM}·${RESET} $(col "$d7")7d ${d7}%${RESET}"; [ "$d7" -ge 60 ] && { r="$(left "$d7r")"; [ -n "$r" ] && line2="$line2 ${DIM}↻${r}${RESET}"; }; fi
case "$cost" in ''|0|0.0) ;; *) line2="$line2 ${DIM}· \$$(printf '%.2f' "$cost" 2>/dev/null || printf '%s' "$cost") est${RESET}";; esac

printf '%s\n%s' "$line1" "$line2"
