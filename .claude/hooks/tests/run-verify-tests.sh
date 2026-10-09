#!/usr/bin/env bash
# note-verification.sh + verify-gate.sh as a pair, with an isolated state dir.
here="$(cd "$(dirname "$0")" && pwd)"; H="$here/.."
mkdir -p "$here/fx"; root="$(mktemp -d "$here/fx/vg.XXXXXX")"
mkdir -p "$root/state" "$root/repo/src"; cd "$root/repo" || exit 1
export XDG_RUNTIME_DIR="$root/state"; unset CLAUDE_VERIFY_GATE
git init -q -b main; git config user.email t@example.com; git config user.name t
printf '{"name":"vg","scripts":{"test":"vitest run","build":"next build"}}\n' > package.json
printf 'export const a = 1\n' > src/a.ts; printf 'export const old = 1\n' > src/old.ts
git add -A; git commit -q -m init
printf 'export const old = 2\n' > src/old.ts; touch -d '2 hours ago' src/old.ts      # dirty before the session
tr="$root/transcript.jsonl"; : > "$tr"                                                 # session starts now
sleep 1
pass=0; fail=0
stop()  { jq -cn --arg cwd "$root/repo" --arg tr "$tr" --argjson active "${1:-false}" --argjson bg "${2:-[]}" \
            '{session_id:"s1",transcript_path:$tr,cwd:$cwd,hook_event_name:"Stop",stop_hook_active:$active,last_assistant_message:"done",background_tasks:$bg,session_crons:[]}' | "$H/verify-gate.sh"; }
ran()   { jq -cn --arg c "$1" --arg ev "$2" '{session_id:"s1",hook_event_name:$ev,tool_name:"Bash",tool_input:{command:$c}}' | "$H/note-verification.sh"; }
is()    { local got; got="$(jq -r 'if .hookSpecificOutput.additionalContext then "nudge" elif .decision == "block" then "block" elif .systemMessage then "warn" else "none" end' <<<"${2:-{\}}" 2>/dev/null)"; [ -z "$2" ] && got=none
          if [ "$got" = "$1" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [$3] want=$1 got=$got :: $2"; fi; }

is none "$(stop)" "only pre-session dirty file"
printf 'export const a = 2\n' > src/a.ts
o="$(stop)"; is nudge "$o" "edit, no check"; jq -r .hookSpecificOutput.additionalContext <<<"$o"
is none "$(stop)" "already nudged for this batch"
is none "$(stop true)" "stop_hook_active"
sleep 1; printf 'export const a = 3\n' > src/a.ts
is nudge "$(stop)" "new edit after nudge"
ran "git status" PostToolUse
sleep 1; printf 'export const a = 4\n' > src/a.ts
is nudge "$(stop)" "git status is not a check"
ran "pnpm test -- --run src/a.test.ts" PostToolUseFailure
o="$(stop)"; is nudge "$o" "check ran but failed"; jq -r .hookSpecificOutput.additionalContext <<<"$o" | grep -q FAILED || { fail=$((fail+1)); echo "FAIL failure not mentioned"; }
sleep 1; ran "npm test 2>&1 | tail -20" PostToolUse
is none "$(stop)" "passing check after last edit"
sleep 1; printf 'export const a = 5\n' > src/a.ts
is none "$(stop false '[{"id":"b1","type":"shell","status":"running","command":"npm run test -- --watch=false"}]')" "check running in background"
CLAUDE_VERIFY_GATE=warn is warn "$(CLAUDE_VERIFY_GATE=warn stop)" "warn mode -> systemMessage"
sleep 1; printf 'export const a = 6\n' > src/a.ts
is block "$(CLAUDE_VERIFY_GATE=block stop)" "block mode"
sleep 1; printf 'export const a = 7\n' > src/a.ts
is none "$(CLAUDE_VERIFY_GATE=off stop)" "off"
printf '# notes\n' > NOTES.md; git add NOTES.md
ran "uv run pytest -q" PostToolUse
is none "$(stop)" "uv run pytest counts; docs-only change ignored"
# note-verification counts a check only in command position, never a word inside arguments.
rec() { local d="$XDG_RUNTIME_DIR/claude-verify/s2"; rm -rf "$d"
        jq -cn --arg c "$1" '{session_id:"s2",hook_event_name:"PostToolUse",tool_name:"Bash",tool_input:{command:$c}}' | "$H/note-verification.sh"
        [ -e "$d/ok" ] && echo recorded || echo ignored; }
for c in 'git commit -m "fix tsc errors"' 'npm i -D vitest' 'pip install pytest' 'grep -rn pytest .' 'which pytest'; do
  if [ "$(rec "$c")" = ignored ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [not a check] $c"; fi
done
for c in 'pnpm --filter web test' 'pnpm -r test' '(cd p && pnpm test)' 'CI=1 npx vitest run' 'uv run pytest -q' 'npm test 2>&1 | tail -5'; do
  if [ "$(rec "$c")" = recorded ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL [is a check] $c"; fi
done

echo "verify-gate: $pass passed, $fail failed"
