#!/usr/bin/env bash
# PostToolUse(Bash) + PostToolUseFailure(Bash): the evidence recorder for verify-gate.sh.
# Records, per session, that a real test/build/lint/typecheck command RAN and whether it
# passed (PostToolUse fires only on success; a non-zero exit fires PostToolUseFailure).
# State: $XDG_RUNTIME_DIR/claude-verify/<session>/{log,ok,fail} (self-cleans on reboot).
#   ok / fail are touched so the gate can compare their mtime with the newest edit.
# ALWAYS exits 0: it only observes.

# The check must be in command position (after ^ ; & | ( plus optional VAR=x, time, timeout N), so
# `git commit -m "fix tsc errors"` or `npm i -D vitest` never count as a check run.
input="$(cat 2>/dev/null)" || exit 0
IFS=$'\x1f' read -r sid ev cmd < <(jq -r '[.session_id // "", .hook_event_name // "", (.tool_input.command // "" | gsub("[\n\u001f]"; " "))] | join("\u001f")' <<<"$input" 2>/dev/null)
[ -n "$sid" ] && [ -n "$cmd" ] || exit 0
cmd="${cmd:0:4000}"   # bash =~ on very large commands is slow (200 KB ~ 1 s, 800 KB ~ 17 s)

pos='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|(time|nice|nohup|timeout[[:space:]]+[0-9smh]+)[[:space:]]+)*'
pmo='((-r|-w|--recursive|(--filter|-F|-C|--prefix|--workspace)[[:space:]]+[^[:space:]]+)[[:space:]]+)*'
tools='tsc|eslint|biome|vitest|jest|playwright|pytest|mypy|pyright|ruff|unittest|next[[:space:]]+(build|lint)'
re="${pos}("
re+="(npm|pnpm|yarn|bun)[[:space:]]+${pmo}(run[[:space:]]+)?(test|tests|lint|build|typecheck|type-check|tsc|check|verify|ci|e2e|test:[a-z0-9:-]+|lint:[a-z0-9:-]+)"
re+="|yarn[[:space:]]+workspace[[:space:]]+[^[:space:]]+[[:space:]]+(run[[:space:]]+)?(test|lint|build|typecheck)"
re+="|((npx|bunx|uv[[:space:]]+run|poetry[[:space:]]+run|python3?[[:space:]]+-m)[[:space:]]+|(pnpm|yarn|bun)[[:space:]]+${pmo}((exec|dlx)[[:space:]]+)?)(${tools})"
re+="|(turbo|nx)[[:space:]]+(run[[:space:]]+)?(test|lint|build|typecheck)|next[[:space:]]+(build|lint)"
re+="|pytest|py\.test|tox|nox|ruff[[:space:]]+check|mypy|pyright|basedpyright|cargo[[:space:]]+(test|check|clippy|build|nextest)|go[[:space:]]+(test|build|vet)|golangci-lint"
re+="|make[[:space:]]+(test|check|lint|build|ci)|gradle|mvn|dotnet[[:space:]]+test|rspec|phpunit|ctest|cmake[[:space:]]+--build|deno[[:space:]]+(test|check|lint)|node[[:space:]]+--test"
re+="|tsc|eslint|biome[[:space:]]+(check|lint|ci)|vitest|jest|playwright[[:space:]]+test|shellcheck|bash[[:space:]]+-n"
re+=")([[:space:]);&|]|\$)"
[[ "$cmd" =~ $re ]] || exit 0

dir="${XDG_RUNTIME_DIR:-/tmp}/claude-verify/$sid"
mkdir -p "$dir" 2>/dev/null || exit 0
if [ "$ev" = PostToolUseFailure ]; then st=fail; else st=ok; fi
printf '%s\t%s\t%s\n' "$(date +%s)" "$st" "$cmd" >> "$dir/log" 2>/dev/null
touch "$dir/$st" 2>/dev/null
[ "$st" = fail ] && printf '%s\n' "$cmd" > "$dir/fail.cmd" 2>/dev/null
exit 0
