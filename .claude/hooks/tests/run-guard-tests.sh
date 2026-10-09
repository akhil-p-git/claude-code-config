#!/usr/bin/env bash
# Feeds every case in guard-cases.jsonl to guard-destructive.sh as a synthetic
# PreToolUse payload and compares the decision. The commands are DATA: they are
# only ever passed to jq --arg and piped to the hook, never evaluated.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/../guard-destructive.sh"
fx="$here/fx"
export CLAUDE_GUARD_LOG="$here/out/guard-decisions.jsonl"; mkdir -p "$here/out"; : > "$CLAUDE_GUARD_LOG"
cd "$here/fx" || exit 1   # never run from a real project
pass=0; fail=0; total_ms=0; n=0; verbose="${VERBOSE:-0}"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  expect="$(jq -r .expect <<<"$line")"
  cwd="$(jq -r .cwd <<<"$line" | sed -e "s#@FX#$fx#g" -e "s#@APP#$HOME/work/Dev/app#g")"
  cmd="$(jq -r .cmd <<<"$line" | sed -e "s#@FX#$fx#g")"
  payload="$(jq -cn --arg c "$cmd" --arg cwd "$cwd" '{session_id:"test",cwd:$cwd,permission_mode:"auto",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c,description:"t"},tool_use_id:"toolu_test"}')"
  t0=$(date +%s%N)
  out="$(printf '%s' "$payload" | "$hook")"; rc=$?
  t1=$(date +%s%N); ms=$(( (t1 - t0) / 1000000 )); total_ms=$((total_ms + ms)); n=$((n + 1))
  got="$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$out" 2>/dev/null)"; [ -z "$got" ] && got=none
  [ $rc -ne 0 ] && got="exit$rc"
  if [ "$got" = "$expect" ]; then pass=$((pass + 1)); [ "$verbose" = 1 ] && printf 'ok   %-5s %4sms  %s\n' "$got" "$ms" "$(printf '%s' "$cmd" | tr '\n' ' ' | cut -c1-90)"
  else fail=$((fail + 1)); printf 'FAIL want=%-5s got=%-5s %4sms  %s\n      %s\n' "$expect" "$got" "$ms" "$(printf '%s' "$cmd" | tr '\n' ' ' | cut -c1-100)" "$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out" 2>/dev/null | cut -c1-200)"; fi
done < "$here/guard-cases.jsonl"
echo "guard: $pass passed, $fail failed, $n cases, avg $((total_ms / (n > 0 ? n : 1)))ms/case"
[ $fail -eq 0 ]
