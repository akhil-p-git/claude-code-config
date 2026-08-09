#!/usr/bin/env bash
# Notification hook — desktop toast when Claude Code wants attention, so a long
# autonomous run can be left alone without watching the terminal for a prompt.
# Best-effort: silently no-ops when notify-send is absent or there is no display.
# ALWAYS exits 0.

command -v notify-send >/dev/null 2>&1 || exit 0
[ -n "$DISPLAY$WAYLAND_DISPLAY" ] || exit 0

input="$(cat 2>/dev/null)" || exit 0
msg="$(printf '%s' "$input" | jq -r '.message // empty' 2>/dev/null)"
typ="$(printf '%s' "$input" | jq -r '.notification_type // empty' 2>/dev/null)"
[ -z "$msg" ] && msg="Claude Code needs your attention"

case "$typ" in
  permission_prompt|agent_needs_input) urgency=critical ;;
  *)                                   urgency=normal   ;;
esac

notify-send --app-name="Claude Code" --urgency="$urgency" \
  --hint=string:desktop-entry:claude-code \
  "Claude Code" "$msg" >/dev/null 2>&1

exit 0
