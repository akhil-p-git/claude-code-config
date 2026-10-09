#!/usr/bin/env bash
# PreToolUse(Bash) content scan: before `git commit` / `git push` runs, look for secrets in
# exactly what would be published (staged diff; plus unstaged tracked changes for
# `commit -a`/pathspecs; for push, the commits not yet on the upstream). Denies with
# file:line + rule id, never echoing the secret itself.
#   - uses gitleaks when installed (pacman -S gitleaks), else a built-in high-signal
#     regex set (cloud/API tokens, private keys, DB URLs with inline passwords)
#   - lines containing `gitleaks:allow` are skipped (same escape hatch as gitleaks)
# Complements guard-git-secrets.sh (which blocks staging secret-shaped PATHS).
# Wire it with "if" filters so it only spawns for commit/push commands.
# Fails open (exit 0) on anything unexpected: a native git pre-commit hook is the
# second layer for commits made outside Claude Code.

input="$(cat)"
# Heredoc bodies are data (commit messages, scripts fed to python): drop them before looking for git
# segments, as guard-destructive.jq does, then turn the remaining newlines into separators.
IFS=$'\x1f' read -r cmd cwd < <(jq -r '[(.tool_input.command // "" | gsub("<<-?[ \\t]*(?<q>[\u0027\"]?)(?<t>[A-Za-z_][A-Za-z0-9_]*)\\k<q>(?<rest>[^\\n]*)\\n(?<body>[\\s\\S]*?)\\n[ \\t]*\\k<t>(?=\\n|$)"; "<<HEREDOC\(.rest)")), (.cwd // "")] | map(gsub("\u001f"; " ") | gsub("\n"; " ; ")) | join("\u001f")' <<<"$input" 2>/dev/null)
[ -n "$cmd" ] || exit 0

seg="$(grep -oE '(^|[;&|(])[[:space:]]*git([[:space:]]+(-C|-c)[[:space:]]+[^[:space:];&|]+|[[:space:]]+--?[a-zA-Z-]+(=[^[:space:];&|]+)?)*[[:space:]]+(commit|push)([[:space:]][^;&|]*)?' <<<"$cmd" | head -1)"
[ -n "$seg" ] || exit 0
read -r -a words <<<"${seg#*git}"

# Follow every `cd <dir>` that runs before the git segment, in order. A target that isn't a
# literal path ($VAR, $(...), `cd -`) can't be resolved here: skip rather than scan the wrong repo.
base="$cwd"; pre="${cmd%%"$seg"*}"
cd_re='(^|[;&|(])[[:space:]]*cd[[:space:]]+([^;&|[:space:]]+)'
while [[ "$pre" =~ $cd_re ]]; do
  d="${BASH_REMATCH[2]}"; pre="${pre#*"${BASH_REMATCH[0]}"}"
  case "$d" in *'$'*|*'`'*|-) exit 0 ;; esac
  d="${d//[\"\']/}"; d="${d/#\~/$HOME}"; [[ "$d" = /* ]] || d="$base/$d"; base="$d"
done
repo="$base"; op=""; args=(); i=0
while [ $i -lt ${#words[@]} ]; do
  w="${words[$i]}"
  if [ -z "$op" ]; then
    case "$w" in
      -C) d="${words[$((i+1))]//[\"\']/}"; d="${d/#\~/$HOME}"; [[ "$d" = /* ]] && repo="$d" || repo="$base/$d"; i=$((i+1)) ;;
      -c) i=$((i+1)) ;;
      commit|push) op="$w" ;;
    esac
  else args+=("$w"); fi
  i=$((i+1))
done
[ -n "$op" ] || exit 0

G() { git -C "$repo" -c core.fsmonitor=false --no-optional-locks "$@" 2>/dev/null; }
top="$(G rev-parse --show-toplevel)" || exit 0
[ -n "$top" ] || exit 0

all=0; range=""
if [ "$op" = commit ]; then
  skip=0
  for w in "${args[@]}"; do
    if [ $skip = 1 ]; then skip=0; continue; fi
    case "$w" in
      -m|-F|-c|-C|--author|--date|--fixup|--squash|-t|--template|--trailer) skip=1 ;;
      --all|--include|--only|-i|-o) all=1 ;;
      --*) ;;
      -*a*) [[ "$w" =~ ^-[a-zA-Z]+$ ]] && all=1 ;;
    esac
  done
  # FIX: a `git add ...` earlier in the SAME command has not run yet when this PreToolUse hook fires,
  # so the index is stale. Treat it like `commit -a` and also scan untracked, non-ignored files.
  addfirst=0; [[ "$cmd" =~ (^|[\;\&\|\(])[[:space:]]*git([[:space:]]+-[^[:space:]]+)*[[:space:]]+add([[:space:]]|$) ]] && { addfirst=1; all=1; }
  diff="$(G diff --cached -U0 --no-color --no-ext-diff)"
  [ $all = 1 ] && diff+=$'\n'"$(G diff -U0 --no-color --no-ext-diff)"
  if [ $addfirst = 1 ]; then
    while IFS= read -r -d '' f; do diff+=$'\n'"$(G diff --no-index -U0 --no-color --no-ext-diff -- /dev/null "$f")"; done < <(G ls-files -z --others --exclude-standard)
  fi
  what="the staged changes"
else
  if G rev-parse -q --verify '@{upstream}' >/dev/null; then range='@{upstream}..HEAD'
  elif G rev-parse -q --verify 'refs/remotes/origin/HEAD' >/dev/null; then range='origin/HEAD..HEAD'
  else range='HEAD --not --remotes'; fi   # first publish / no origin/HEAD: scan every commit no remote has
  diff="$(G log -p -U0 --no-color --no-ext-diff $range)"
  what="the commits being pushed ($range)"
fi
[[ "$diff" =~ [^[:space:]] ]] || exit 0

findings=""; scanner=""
if command -v gitleaks >/dev/null 2>&1; then
  scanner=gitleaks
  if [ "$op" = commit ]; then
    rep="$(cd "$top" && gitleaks git --staged --redact --no-banner --log-level error --exit-code 42 --report-format json --report-path /dev/stdout . 2>/dev/null)"; rc=$?
    if [ $rc -ne 42 ] && [ $all = 1 ]; then
      rep="$(cd "$top" && gitleaks git --pre-commit --redact --no-banner --log-level error --exit-code 42 --report-format json --report-path /dev/stdout . 2>/dev/null)"; rc=$?
    fi
  else
    rep="$(cd "$top" && gitleaks git --log-opts="$range" --redact --no-banner --log-level error --exit-code 42 --report-format json --report-path /dev/stdout . 2>/dev/null)"; rc=$?
  fi
  if [ $rc -eq 42 ]; then findings="$(jq -r '.[] | "\(.File):\(.StartLine) \(.RuleID)"' <<<"$rep" 2>/dev/null | sort -u | head -10)"
  elif [ $rc -ne 0 ]; then scanner=""; fi   # gitleaks error -> fall back to the built-in scan
fi

if [ -z "$scanner" ]; then
  scanner=built-in
  findings="$(printf '%s\n' "$diff" | gawk -v maxn=10 '
    /^\+\+\+ / { f = $2; sub(/^b\//, "", f); next }
    /^@@ /     { if (match($0, /\+[0-9]+/)) ln = substr($0, RSTART + 1, RLENGTH - 1) - 1; next }
    /^\+/ {
      ln++; line = substr($0, 2)
      if (f ~ /(\.lock|-lock\.json|-lock\.yaml|\.snap|\.svg|\.min\.js|\.map)$/ || line ~ /gitleaks:allow/) next
      r = ""
      if      (line ~ /(AKIA|ASIA)[0-9A-Z]{16}/)                               r = "aws-access-key-id"
      else if (line ~ /gh[pousr]_[A-Za-z0-9]{36}/)                             r = "github-token"
      else if (line ~ /github_pat_[A-Za-z0-9_]{60,}/)                          r = "github-fine-grained-pat"
      else if (line ~ /glpat-[A-Za-z0-9_-]{20}/)                               r = "gitlab-token"
      else if (line ~ /sk-ant-[a-z]+[0-9]{2}-[A-Za-z0-9_-]{40,}/)              r = "anthropic-api-key"
      else if (line ~ /sk-or-v1-[a-f0-9]{64}/)                                 r = "openrouter-api-key"
      else if (line ~ /sk-(proj|svcacct|admin)-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{48}/) r = "openai-api-key"
      else if (line ~ /xox[baprs]-[0-9A-Za-z-]{10,}/)                          r = "slack-token"
      else if (line ~ /(sk|rk)_live_[0-9A-Za-z]{20,}/)                         r = "stripe-live-key"
      else if (line ~ /whsec_[0-9A-Za-z]{32,}/)                                r = "stripe-webhook-secret"
      else if (line ~ /AIza[0-9A-Za-z_-]{35}/)                                 r = "google-api-key"
      else if (line ~ /-----BEGIN ([A-Z]+ )?PRIVATE KEY-----/)                 r = "private-key"
      else if (line ~ /npm_[A-Za-z0-9]{36}/)                                   r = "npm-token"
      else if (line ~ /hf_[A-Za-z0-9]{34}/)                                    r = "huggingface-token"
      else if (line ~ /(postgres(ql)?|mysql|mongodb(\+srv)?|rediss?|amqps?):\/\/[^:@\/ ]+:[^@\/ ]{6,}@/ &&
               line !~ /:\/\/[^:@\/ ]+:(password|passwd|pass|secret|changeme|postgres|example|x{3,}|\*+|\$\{?[A-Za-z_]+\}?|<[^>]+>)@/) r = "database-url-with-password"
      if (r != "" && n < maxn) { print f ":" ln " " r; n++ }
    }')"
fi

[ -n "$findings" ] || exit 0
list="$(printf '%s' "$findings" | sed 's/^/  - /')"
reason="secret-scan ($scanner): possible secrets in $what:
$list
Remove them from the change (rotate any real one: it has already been on disk and may be in this transcript) and load them from a gitignored .env.local or a secret manager instead. If a hit is a false positive, mark that line with a 'gitleaks:allow' comment or add a .gitleaksignore entry, then retry."
jq -cn --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
