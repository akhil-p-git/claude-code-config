#!/usr/bin/env bash
# Stand-in for prettier/biome/ruff in tests: records its argv, appends a marker to the
# file it was given (the last argument), and fails like a parser on "SYNTAX_ERROR".
name="$(basename "$0")"
log="$(dirname "$0")/../../calls.log"; [ "$name" = ruff ] && log="$(dirname "$0")/../../calls.log"
printf '%s %s\n' "$name" "$*" >> "$log"
f="${!#}"
if grep -q SYNTAX_ERROR "$f" 2>/dev/null; then echo "[error] $f: SyntaxError: Unexpected token (3:7)" >&2; exit 2; fi
printf '\n// formatted-by-%s\n' "$name" >> "$f"
exit 0
