#!/usr/bin/env bash
# PreToolUse(Bash) guard — blocks committing secrets into git.
# Inspects ONLY the `git add`/`git stage` invocation(s): the command is split on
# && || ; | and newlines, and a segment counts only if it *starts* with `git … add`
# (after leading ENV=val assignments). So commit messages and other chained
# commands are never matched.
# Blocks staging of: *.env (not .env.example/sample/template/dist), *.key/*.pem/
# *.p12/*.pfx/*.keystore, ssh keys, secrets//.ssh//.gnupg/ dirs, .taskmaster; and
# blanket `git add -A|.|*` when the repo top-level is $HOME (a PUBLIC repo).
# exit 2 = block; exit 0 = allow. FAILS OPEN on any parse error.

input="$(cat 2>/dev/null)" || exit 0
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -z "$cmd" ] && exit 0
printf '%s' "$cmd" | grep -qE '\bgit\b[^&|;]*\b(add|stage)\b' || exit 0
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"

norm="$(printf '%s' "$cmd" | sed -E 's/&&|\|\||;|\|/\n/g')"

block=0; reason=""
while IFS= read -r seg; do
  seg="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//')"
  while printf '%s' "$seg" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+'; do
    seg="$(printf '%s' "$seg" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+//')"
  done
  printf '%s' "$seg" | grep -qE '^git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(add|stage)\b' || continue
  args="$(printf '%s' "$seg" | sed -E 's/^git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(add|stage)\b//')"
  scrub="$(printf '%s' "$args" | sed -E 's#[^[:space:]]*\.env\.(example|sample|template|dist)\b##g')"

  if    printf '%s' "$scrub" | grep -qiE '(^|[[:space:]])[^[:space:]]*\.env(\.[[:alnum:]_-]+)*([[:space:]]|$)' \
     || printf '%s' "$scrub" | grep -qiE '\.(key|pem|p12|pfx|keystore)([[:space:]]|$)' \
     || printf '%s' "$scrub" | grep -qiE '(^|[[:space:]/])(id_rsa|id_ed25519|id_dsa)([[:space:]]|$|\.)' \
     || printf '%s' "$scrub" | grep -qiE '(^|[[:space:]])(\./)?(secrets?|\.ssh|\.gnupg)/' \
     || printf '%s' "$scrub" | grep -qiE '(^|[[:space:]/])[^[:space:]]*\.taskmaster'; then
    block=1; reason="a secret/credential/.taskmaster path"; break
  fi
  if printf '%s' "$args" | grep -qE '(^|[[:space:]])(-A|--all|\.|\*)([[:space:]]|$)'; then
    top="$(git -C "${cwd:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "")"
    if [ -n "$top" ] && [ "$top" = "$HOME" ]; then
      block=1; reason="blanket 'git add -A/./*' from \$HOME (a PUBLIC repo)"; break
    fi
  fi
done <<EOF
$norm
EOF

if [ "$block" -eq 1 ]; then
  echo "❌ Blocked: refusing to stage ${reason}. Stage explicit non-secret files; keep these in .gitignore (rules/security.md, storage.md)." >&2
  exit 2
fi
exit 0
