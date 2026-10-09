#!/usr/bin/env bash
# Creates throwaway git repos used by the hook tests. Only git init/add/commit and
# file writes inside tests/fx. Safe to re-run: it refuses to touch anything else.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
fx="$here/fx"
case "$fx" in */.claude/hooks/tests/fx) ;; *) echo "unexpected fixture path: $fx" >&2; exit 1;; esac
[ -e "$fx" ] && { echo "fixtures already exist at $fx (delete the folder by hand to rebuild)"; exit 0; }
mkdir -p "$fx"

mk() {  # mk <name> <branch>
  local d="$fx/$1"; mkdir -p "$d"
  git -C "$d" init -q -b "$2"
  git -C "$d" config user.email t@example.com; git -C "$d" config user.name test
  printf 'console.log(1)\n' > "$d/app.js"
  printf '.env\nnode_modules/\n' > "$d/.gitignore"
  git -C "$d" add app.js .gitignore; git -C "$d" commit -q -m init
}
mk clean main
mk dirty main;     printf 'console.log(2)\n' > "$fx/dirty/app.js"
mk feature main;   git -C "$fx/feature" switch -q -c feature/x
mk untracked main; printf 'scratch\n' > "$fx/untracked/scratch.txt"
mk ignored main;   printf 'SECRET=1\n' > "$fx/ignored/.env"
echo "fixtures ready in $fx"
