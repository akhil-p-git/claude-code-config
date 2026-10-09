#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): format ONLY the file Claude just touched, with the
# formatter the project itself pins. Never downloads anything (no npx/bunx fetches):
# a project without a local formatter is left alone.
#   JS/TS/JSON/CSS/MD/YAML...: local Biome if a biome.json(c) is found, else local Prettier
#                              if the project configures it; the binary is found by walking up
#                              to the nearest node_modules/.bin that has it (monorepo roots too)
#   Python: black if [tool.black] is configured, else ruff format if the project configures ruff
#           or installs it in .venv; a file outside any Python project is left alone
#   Go: gofmt   Rust: rustfmt (edition from Cargo.toml)   Shell: shfmt, only with an .editorconfig
# A formatter failure is usually a syntax error, so it is reported to Claude as
# additionalContext (non-blocking). Success is silent. Disable with CLAUDE_NO_FORMAT=1.

[ "${CLAUDE_NO_FORMAT:-0}" = "1" ] && exit 0
input="$(cat)"
fp="$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null)"
[ -n "$fp" ] && [ -f "$fp" ] || exit 0
case "$fp" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/.next/*|*/vendor/*|*/.venv/*|*.min.js|*.min.css|*.lock|*-lock.json|*-lock.yaml) exit 0 ;;
esac

dir="$(dirname "$fp")"
find_up() {  # nearest ancestor of the file holding any of the given names; stops at $HOME and /
  local d="$dir" m
  while [ "$d" != "/" ] && [ "$d" != "$HOME" ]; do
    for m in "$@"; do [ -e "$d/$m" ] && { printf '%s' "$d"; return 0; }; done
    d="${d%/*}"; [ -n "$d" ] || d=/
  done
  return 1
}
find_bin() {  # nearest ancestor whose node_modules/.bin holds the given tool
  local d="$dir"
  while [ "$d" != "/" ] && [ "$d" != "$HOME" ]; do
    [ -x "$d/node_modules/.bin/$1" ] && { printf '%s' "$d"; return 0; }
    d="${d%/*}"; [ -n "$d" ] || d=/
  done
  return 1
}

tool=""; out=""; rc=0
case "${fp##*.}" in
  js|jsx|mjs|cjs|ts|tsx|mts|cts|json|jsonc|json5|css|scss|less|html|vue|svelte|astro|md|mdx|yaml|yml|graphql|gql|hbs)
    root="$(find_up package.json)" || exit 0
    if bin="$(find_bin biome)" && find_up biome.json biome.jsonc >/dev/null; then
      tool=biome
      out="$(cd "$bin" && timeout 20 node_modules/.bin/biome format --write --no-errors-on-unmatched --files-ignore-unknown=true "$fp" 2>&1)"; rc=$?
    elif bin="$(find_bin prettier)" && { find_up .prettierrc .prettierrc.json .prettierrc.json5 .prettierrc.yaml .prettierrc.yml .prettierrc.toml .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.ts prettier.config.js prettier.config.cjs prettier.config.mjs prettier.config.ts >/dev/null \
                   || jq -e '.prettier // .devDependencies.prettier // .dependencies.prettier' "$root/package.json" "$bin/package.json" >/dev/null 2>&1; }; then
      tool=prettier
      out="$(cd "$bin" && timeout 20 node_modules/.bin/prettier --write --log-level warn "$fp" 2>&1)"; rc=$?
    fi ;;
  py|pyi)
    root="$(find_up pyproject.toml ruff.toml .ruff.toml setup.cfg)" || exit 0
    ruff=""; for c in "$root/.venv/bin/ruff" "$(command -v ruff 2>/dev/null)"; do [ -n "$c" ] && [ -x "$c" ] && { ruff="$c"; break; }; done
    if [ -x "$root/.venv/bin/black" ] && grep -qs '^\[tool\.black\]' "$root/pyproject.toml"; then
      tool=black; out="$(cd "$root" && timeout 20 .venv/bin/black --quiet "$fp" 2>&1)"; rc=$?
    elif [ -n "$ruff" ] && { [ "$ruff" = "$root/.venv/bin/ruff" ] || [ -e "$root/ruff.toml" ] || [ -e "$root/.ruff.toml" ] || grep -qs '^\[tool\.ruff' "$root/pyproject.toml"; }; then
      tool=ruff; out="$(cd "$root" && timeout 20 "$ruff" format --quiet "$fp" 2>&1)"; rc=$?
    fi ;;
  go) command -v gofmt >/dev/null && { tool=gofmt; out="$(timeout 20 gofmt -w "$fp" 2>&1)"; rc=$?; } ;;
  rs)
    if command -v rustfmt >/dev/null; then
      ed="$(grep -hsoE '^edition[[:space:]]*=[[:space:]]*"[0-9]{4}"' "$(find_up Cargo.toml)/Cargo.toml" | grep -oE '[0-9]{4}')"
      tool=rustfmt; out="$(timeout 20 rustfmt --edition "${ed:-2021}" "$fp" 2>&1)"; rc=$?
    fi ;;
  sh|bash) command -v shfmt >/dev/null && find_up .editorconfig >/dev/null && { tool=shfmt; out="$(timeout 20 shfmt -w "$fp" 2>&1)"; rc=$?; } ;;
esac

[ -z "$tool" ] || [ "$rc" -eq 0 ] && exit 0
msg="$tool could not format $(basename "$fp") (exit $rc)"; [ "$rc" -eq 124 ] && msg="$tool timed out formatting $(basename "$fp")"
jq -cn --arg c "$msg. This usually means a syntax error in the edit: $(printf '%s' "$out" | head -c 1500)" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
exit 0
