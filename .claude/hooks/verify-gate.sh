#!/usr/bin/env bash
# Stop hook: deterministic backstop for "verify before claiming done", without loops.
#
# Fires only when ALL hold:
#   1. cwd is in a git repo (not $HOME)
#   2. a source file changed in THIS session (mtime >= session start) ...
#   3. ... and more recently than the last PASSING check recorded by note-verification.sh
#      and than this gate's own last nudge (so it speaks once per batch of edits)
#   4. no check is still running as a background shell task
#   5. the project exposes a check (package.json script, uv/pytest, cargo, go, make)
# Modes (CLAUDE_VERIFY_GATE): nudge (default) = additionalContext, Claude continues once
#   and is labeled "Stop hook feedback"; block = decision:block (labeled as a hook block);
#   warn = systemMessage to YOU only, the turn ends; off.
# Loop safety: exits when stop_hook_active is true, and the per-batch "gated" marker means
# a "no check applies here" answer is accepted. FAILS OPEN on any error.

input="$(cat 2>/dev/null)" || exit 0
mode="${CLAUDE_VERIFY_GATE:-nudge}"
[ "$mode" = off ] && exit 0
IFS=$'\x1f' read -r sid cwd active tpath running < <(jq -r '[.session_id // "", .cwd // "", ((.stop_hook_active // false) | tostring), .transcript_path // "",
    ([.background_tasks[]? | select(.type == "shell") | .command // ""] | join(" ;; "))] | map(gsub("[\n\u001f]"; " ")) | join("\u001f")' <<<"$input" 2>/dev/null)
[ "$active" = true ] && exit 0
[ -n "$sid" ] || exit 0
# Turn is paused waiting on subagents/workflows/teammates, not finished — don't nag yet.
inflight="$(jq -r '[(.background_tasks // [])[] | select(.type == "subagent" or .type == "workflow" or .type == "teammate")] | length' <<<"$input" 2>/dev/null)"
[ "${inflight:-0}" -gt 0 ] 2>/dev/null && exit 0
[ -n "$cwd" ] || cwd="$PWD"

G() { git -C "$1" -c core.fsmonitor=false --no-optional-locks "${@:2}" 2>/dev/null; }
top="$(G "$cwd" rev-parse --show-toplevel)" || exit 0
[ -n "$top" ] && [ "$top" != "$HOME" ] || exit 0

src='\.(ts|tsx|js|jsx|mjs|cjs|mts|cts|py|go|rs|c|h|cc|cpp|hpp|java|kt|rb|php|cs|swift|scala|sh|bash|sql|vue|svelte|astro)$'
mapfile -t files < <(G "$top" status --porcelain --untracked-files=all | grep -vE '^(D.|.D) ' \
  | sed -E 's/^.. //; s/^.* -> //; s/^"(.*)"$/\1/' | grep -E "$src" | head -300)
[ "${#files[@]}" -gt 0 ] || exit 0

state="${XDG_RUNTIME_DIR:-/tmp}/claude-verify/$sid"
mt() { local t; t="$(stat -c %.9Y "$1" 2>/dev/null)"; t="${t/./}"; echo "${t:-0}"; }   # mtime in ns
start=0; [ -n "$tpath" ] && start="$(stat -c %W "$tpath" 2>/dev/null)"; [[ "$start" =~ ^[0-9]+$ ]] && start="${start}000000000" || start=0
newest=0; changed=()
for f in "${files[@]}"; do
  t="$(mt "$top/$f")"
  [ "$t" -ge "$start" ] || continue          # dirty before this session started: not ours
  changed+=("$f"); [ "$t" -gt "$newest" ] && newest=$t
done
[ "$newest" -gt 0 ] || exit 0
ok="$(mt "$state/ok")"; gated="$(mt "$state/gated")"; failed="$(mt "$state/fail")"
since=$ok; [ "$gated" -gt "$since" ] && since=$gated
# speak if there are edits newer than the last pass/nudge, or a check FAILED after both
failed_new=0; [ "$failed" -gt "$since" ] && [ "$failed" -ge "$newest" ] && failed_new=1
[ "$newest" -le "$since" ] && [ $failed_new = 0 ] && exit 0

checkre='(test|tests|lint|build|typecheck|type-check|tsc|vitest|jest|pytest|playwright|cargo|go[[:space:]]+(test|build|vet)|make)'
[ -n "$running" ] && [[ "$running" =~ $checkre ]] && exit 0   # a check is still running in the background

check=""
if [ -f "$top/package.json" ]; then
  pm="npm run"; [ -f "$top/pnpm-lock.yaml" ] && pm="pnpm"; [ -f "$top/yarn.lock" ] && pm="yarn"
  { [ -f "$top/bun.lock" ] || [ -f "$top/bun.lockb" ]; } && pm="bun run"
  for s in test typecheck type-check lint build check; do
    jq -e --arg s "$s" '.scripts[$s] // empty' "$top/package.json" >/dev/null 2>&1 && { check="$pm $s"; break; }
  done
fi
if [ -z "$check" ] && { [ -f "$top/pytest.ini" ] || [ -d "$top/tests" ] || grep -qs '^\[tool\.pytest' "$top/pyproject.toml"; }; then
  if [ -f "$top/uv.lock" ]; then check="uv run pytest"; else check="pytest"; fi
fi
[ -z "$check" ] && [ -f "$top/Cargo.toml" ] && check="cargo test"
[ -z "$check" ] && [ -f "$top/go.mod" ] && check="go test ./..."
[ -z "$check" ] && [ -f "$top/Makefile" ] && grep -qE '^(test|check):' "$top/Makefile" && check="make test"
[ -n "$check" ] || exit 0

n=${#changed[@]}; sample="$(printf '%s, ' "${changed[@]:0:3}")"; sample="${sample%, }"
if [ $failed_new = 1 ] || { [ "$failed" -ge "$newest" ] && [ "$failed" -gt "$ok" ]; }; then
  msg="Verification gate: the latest check after your edits FAILED ($(head -c 200 "$state/fail.cmd" 2>/dev/null)). Fix it, or report the failure plainly; do not describe the work as done."
else
  msg="Verification gate: $n source file(s) in $(basename "$top") changed since the last passing check (${sample}$([ "$n" -gt 3 ] && echo ", ...")). Run \`$check\` (or the narrower relevant test) and show its real output before reporting this as done. If no check applies to this change, say so and why."
fi

mkdir -p "$state" 2>/dev/null && touch "$state/gated" 2>/dev/null
case "$mode" in
  block) jq -cn --arg r "$msg" '{decision: "block", reason: $r}' ;;
  warn)  jq -cn --arg m "$msg" '{systemMessage: $m}' ;;
  *)     jq -cn --arg c "$msg" '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $c}}' ;;
esac
exit 0
