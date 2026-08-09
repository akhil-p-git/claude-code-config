#!/usr/bin/env bash
# Stop hook — deterministic backstop for the CLAUDE.md rule
# "Verify before claiming done: run tests/build and show the real output".
#
# Advisory text gets lost in a long context; a hook fires at exactly the moment
# it matters. Fires ONLY when all of these hold, so chat-only turns stay silent:
#   1. cwd is inside a git repo
#   2. tracked source files were actually modified this session
#   3. the project exposes a check to run (package.json script, Makefile, pytest, ...)
#   4. no test/build/lint command was recorded by note-verification.sh this session
#
# Default is WARN (inject a reminder, let the turn end). Export
# CLAUDE_VERIFY_GATE=block to make it a hard gate that blocks the turn instead.
# Claude Code force-ends the turn after 8 consecutive blocks, so it can't wedge.
# FAILS OPEN on any error. Never blocks in warn mode.

input="$(cat 2>/dev/null)" || exit 0

sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

# 4. Already verified this session? Nothing to say.
[ -n "$sid" ] && [ -s "${XDG_RUNTIME_DIR:-/tmp}/claude-verify/${sid}" ] && exit 0

# 1. In a git repo?
top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -z "$top" ] && exit 0

# Never nag in $HOME — it is a dotfile repo, not a project with a test suite.
[ "$top" = "$HOME" ] && exit 0

# 2. Any modified/added SOURCE files? Docs- or config-only edits don't need a test run.
changed="$(git -C "$top" status --porcelain 2>/dev/null \
  | grep -E '^[ MARC?][ MARCD?][[:space:]]' \
  | grep -EI '\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|c|h|cpp|hpp|java|kt|rb|php|cs|swift|scala|sh|bash|sql|vue|svelte)$' \
  | head -20)"
[ -z "$changed" ] && exit 0
n="$(printf '%s\n' "$changed" | grep -c . )"

# 3. What check does this project actually expose? First match wins.
check=""
if [ -f "$top/package.json" ]; then
  for s in test lint typecheck type-check build check; do
    if jq -e --arg s "$s" '.scripts[$s] // empty' "$top/package.json" >/dev/null 2>&1; then
      pm="npm run"
      [ -f "$top/pnpm-lock.yaml" ] && pm="pnpm run"
      [ -f "$top/yarn.lock" ]      && pm="yarn"
      [ -f "$top/bun.lockb" ]      && pm="bun run"
      check="$pm $s"; break
    fi
  done
fi
[ -z "$check" ] && [ -f "$top/Makefile" ] && grep -qE '^(test|check):' "$top/Makefile" 2>/dev/null && check="make test"
[ -z "$check" ] && { [ -f "$top/pytest.ini" ] || [ -f "$top/tox.ini" ] || [ -f "$top/pyproject.toml" ] || [ -d "$top/tests" ]; } && check="pytest"
[ -z "$check" ] && [ -f "$top/Cargo.toml" ] && check="cargo test"
[ -z "$check" ] && [ -f "$top/go.mod" ]     && check="go test ./..."
[ -z "$check" ] && exit 0

msg="Verification gate: ${n} source file(s) modified in $(basename "$top"), but no test/build/lint command ran this session. Run \`${check}\` and show the real output before reporting this as done — per CLAUDE.md, never assert a result you did not observe. If the check genuinely does not apply here, say so explicitly and why."

if [ "${CLAUDE_VERIFY_GATE:-warn}" = "block" ]; then
  jq -cn --arg r "$msg" '{decision:"block", reason:$r}' 2>/dev/null \
    || printf '{"decision":"block","reason":"Verification gate: run the project checks before finishing."}'
  exit 0
fi

jq -cn --arg c "$msg" \
  '{hookSpecificOutput:{hookEventName:"Stop", additionalContext:$c}}' 2>/dev/null \
  || exit 0
exit 0
