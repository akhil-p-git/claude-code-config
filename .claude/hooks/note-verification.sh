#!/usr/bin/env bash
# PostToolUse(Bash) — the "evidence recorder" half of the verification gate.
# Notes, per session, that a real test/build/lint/typecheck command actually RAN.
# verify-gate.sh (Stop hook) reads this to tell "I ran the tests" from "I claimed to".
# State lives in $XDG_RUNTIME_DIR (or /tmp), so it self-cleans on reboot.
# ALWAYS exits 0 — this hook only observes, it never blocks.

input="$(cat 2>/dev/null)" || exit 0

sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$sid" ] || [ -z "$cmd" ] && exit 0

# Only count a command as verification if it looks like a real check being run.
# Deliberately narrow: `git status` or `ls` must not satisfy the gate.
printf '%s' "$cmd" | grep -qEi \
  '(^|[[:space:]&|;])((npm|pnpm|yarn|bun)[[:space:]]+(run[[:space:]]+)?(test|lint|build|typecheck|type-check|check)|npx[[:space:]]+(tsc|eslint|vitest|jest)|pytest|tox|nox|ruff|mypy|pyright|cargo[[:space:]]+(test|check|clippy|build)|go[[:space:]]+(test|build|vet)|make[[:space:]]+(test|check|lint|build)|gradle|mvn|dotnet[[:space:]]+test|rspec|phpunit|ctest|cmake[[:space:]]+--build|tsc|eslint|vitest|jest|shellcheck|bash[[:space:]]+-n)([[:space:]]|$)' \
  || exit 0

dir="${XDG_RUNTIME_DIR:-/tmp}/claude-verify"
mkdir -p "$dir" 2>/dev/null || exit 0
printf '%s\n' "$cmd" >> "${dir}/${sid}" 2>/dev/null

exit 0
