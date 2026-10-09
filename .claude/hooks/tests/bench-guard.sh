#!/usr/bin/env bash
# Latency of guard-destructive.sh per call for representative payloads (20 runs each).
here="$(cd "$(dirname "$0")" && pwd)"; hook="$here/../guard-destructive.sh"
export CLAUDE_GUARD_LOG="$here/out/bench.jsonl"; mkdir -p "$here/out"
cd "$here/fx" || exit 1
bench() {  # bench <label> <cwd> <cmd>
  local p; p="$(jq -cn --arg c "$3" --arg cwd "$2" '{session_id:"b",cwd:$cwd,tool_name:"Bash",tool_input:{command:$c}}')"
  local t0 t1; t0=$(date +%s%N)
  for _ in $(seq 20); do printf '%s' "$p" | "$hook" >/dev/null; done
  t1=$(date +%s%N); printf '%-34s %3d ms/call\n' "$1" $(( (t1 - t0) / 20000000 ))
}
bench "fast path (npm test | tail)" "$HOME/work/Dev/app" 'npm test 2>&1 | tail -20'
bench "fast path (git status)" "$HOME/work/Dev/app" 'git status --short'
bench "analyzed, no finding (rm node_modules)" "$HOME/work/Dev/app" 'rm -rf node_modules .next'
bench "analyzed deny (rm home)" "$HOME/work/Dev/app" "$(sed -n 2p "$here/guard-cases.jsonl" | jq -r .cmd)"
bench "repo check, dirty -> deny" "$here/fx/dirty" 'git reset --hard'
bench "repo check, clean -> none" "$here/fx/clean" 'git reset --hard'
