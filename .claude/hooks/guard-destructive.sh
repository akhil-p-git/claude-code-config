#!/usr/bin/env bash
# PreToolUse(Bash|Monitor) guard against destructive and exfiltrating shell commands.
#
# Why a hook and not only permission rules: a deny/ask hook runs before permission
# rules and in EVERY mode (auto, acceptEdits, bypassPermissions), and it sees the
# whole command (compound commands, $(...), bash -c '...', heredocs fed to a shell,
# `git -C dir push`). Broad allow rules such as Bash(git:*) resolve before the auto
# mode classifier, so without this hook `git push --force` or `git reset --hard`
# under such a rule is never reviewed at all.
#
# Analysis lives in guard-destructive.jq (one jq process, never executes the command).
# This wrapper resolves the findings that need repo state, read-only:
#   tracked -> git status --porcelain --untracked-files=no  (reset --hard, checkout ., ...)
#   clean   -> git clean -n <same -d/-x/-X flags>            (git clean -f...)
#   branch  -> git symbolic-ref --short HEAD                 (force-push with no refspec)
# Decisions: deny > ask > (no output = normal permission flow). Never "allow".
#
# Fail-safe: unreadable input or a failed analysis exits 2 (blocks); also register with
# "onFailure": "block" (Claude Code >= 2.1.295) so a crash or timeout blocks the call too. Analysis errors inside
# jq degrade to "ask". Set CLAUDE_GUARD_DISABLE=1 in the environment you launch
# claude from to switch the guard off (an inline VAR=1 in a command does not reach it).

set -o pipefail
input="$(cat)"
[ "${CLAUDE_GUARD_DISABLE:-0}" = "1" ] && exit 0
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")" || { echo "guard-destructive: unreadable hook input" >&2; exit 2; }
[ -z "$cmd" ] && exit 0   # e.g. Monitor in WebSocket mode

# Fast path (~5 ms): only commands naming something the rules care about pay for the
# full analysis (~25 ms, almost all of it jq compiling the rule program).
w='(^|[^A-Za-z0-9_.-])'; e='($|[^A-Za-z0-9_-])'
trig="${w}(rm|find|chmod|chown|chgrp|dd|mkfs[.a-z0-9]*|mke2fs|mkswap|wipefs|fdisk|sfdisk|cfdisk|parted|gdisk|sgdisk|blkdiscard|shred|psql|mysql|mariadb|sqlite3|duckdb|sqlcmd|cockroach|clickhouse-client|mongosh|mongo|redis-cli|pgcli|mycli|litecli|dropdb|prisma|drizzle-kit|supabase|neonctl|turso|rails|rake|vercel|vc|publish|unpublish|deprecate|twine|gem|cargo|gh|docker|docker-compose|podman|kubectl|helm|terraform|tofu|terragrunt|pulumi|aws|gcloud|az|curl|wget|xh|http|https|aria2c|scp|rsync|sftp|rclone|nc|ncat|netcat|socat|telnet|sudo|doas|run0|eval|ssh|bash|sh|zsh|dash|ksh|xargs|base64|xxd|od|hexdump|strings)${e}"
trig="$trig|${w}git[[:space:]]([^;&|]*[[:space:]])?(push|reset|checkout|switch|restore|clean|stash|branch|filter-branch|filter-repo|reflog|gc|update-ref|remote|commit|worktree|rm)${e}"
trig="$trig|manage\.py|\.ssh/|\.aws/|\.gnupg|credentials|\.secrets|\.netrc|\.git-credentials|\.npmrc|\.pypirc|\.kube/|\.docker/config|com\.vercel\.cli|:[[:space:]]*\([[:space:]]*\)[[:space:]]*\{|of=/dev/|>[[:space:]]*/dev/(sd|nvme|hd|vd|xvd|mmcblk|md[0-9]|dm-|disk|mapper)"
[[ "$cmd" =~ $trig ]] || exit 0

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
protected="${CLAUDE_GUARD_PROTECTED_BRANCHES:-main|master|trunk|prod|production|release(/.*)?|gh-pages}"

analysis="$(printf '%s' "$input" | jq -r --arg home "$HOME" --arg protected "$protected" \
  --arg projdir "${CLAUDE_PROJECT_DIR:-}" -f "$here/guard-destructive.jq")" \
  || { echo "guard-destructive: analysis failed" >&2; exit 2; }   # exit 2 blocks even without onFailure
[ -z "$analysis" ] && exit 0

g() { git -C "$1" -c core.fsmonitor=false --no-optional-locks "${@:2}" 2>/dev/null; }

deny=(); ask=()
while IFS=$'\x1f' read -r level kind dir reason fd fx fX ifprot otherwise paths; do
  if [ "$level" = check ]; then
    if [ -z "$dir" ] || ! g "$dir" rev-parse --is-inside-work-tree >/dev/null; then
      ask+=("$reason (could not inspect the repository to check what would be lost)"); continue
    fi
    case "$kind" in
      tracked)
        n="$(g "$dir" status --porcelain --untracked-files=no | grep -c .)"
        [ "${n:-0}" -gt 0 ] && deny+=("$reason: $n tracked file(s) have uncommitted changes in $dir. Commit or 'git stash push -m <msg>' first, or discard only specific files") ;;
      clean)
        flags=(-n); [ "$fd" = true ] && flags+=(-d); [ "$fx" = true ] && flags+=(-x); [ "$fX" = true ] && flags+=(-X)
        if [ -n "$paths" ]; then IFS=$'\x1e' read -r -a pa <<<"$paths"; flags+=(-- "${pa[@]}"); fi
        out="$(g "$dir" clean "${flags[@]}")"
        if [ -n "$out" ]; then
          n="$(grep -c . <<<"$out")"; sample="$(head -5 <<<"$out" | sed 's/^Would remove //' | paste -sd, -)"
          deny+=("$reason: it would remove $n path(s) in $dir (e.g. $sample). Delete specific paths instead, after confirming none are needed (.env files, local databases)")
        fi ;;
      branch)
        b="$(g "$dir" symbolic-ref --short -q HEAD)"
        if [ -z "$b" ] || [[ "$b" =~ ^($protected)$ ]]; then lvl="$ifprot"; msg="$reason to ${b:-a detached/unknown HEAD} (protected branch)"
        else lvl="$otherwise"; msg="$reason to $b rewrites remote history"; fi
        [ "$lvl" = deny ] && deny+=("$msg"); [ "$lvl" = ask ] && ask+=("$msg") ;;
    esac
  elif [ "$level" = deny ]; then deny+=("$reason")
  elif [ "$level" = ask ]; then ask+=("$reason")
  fi
done <<<"$analysis"

if [ "${#deny[@]}" -gt 0 ]; then decision=deny; reasons=("${deny[@]}")
elif [ "${#ask[@]}" -gt 0 ]; then decision=ask; reasons=("${ask[@]}")
else exit 0; fi

msg="$(printf '%s; ' "${reasons[@]:0:3}")"; msg="guard-destructive: ${msg%; }."
[ "$decision" = deny ] && msg="$msg If this is really intended, stop and ask the user to run it themselves (they can type: ! <command>)."

# Audit trail of every deny/ask, with common token shapes redacted.
log="${CLAUDE_GUARD_LOG:-$HOME/.claude/logs/guard-decisions.jsonl}"
mkdir -p "$(dirname "$log")" 2>/dev/null && printf '%s' "$input" | jq -c --arg d "$decision" --arg m "$msg" '
  {ts: (now | todate), session: .session_id, cwd, mode: .permission_mode, decision: $d, reason: $m,
   command: ((.tool_input.command // "")[0:2000]
     | gsub("(?<k>(sk-ant-|sk-or-|sk-proj-|sk-|ghp_|gho_|ghu_|ghs_|ghr_|github_pat_|glpat-|xox[abposr]-|sk_live_|rk_live_|AKIA|npm_|hf_)[A-Za-z0-9]{0,4})[A-Za-z0-9_\\-]{12,}"; "\(.k)…REDACTED")
     | gsub("(?<k>(Bearer|token|password|passwd|secret|api[_-]?key)[=: ]+)[^\\s\"]{8,}"; "\(.k)REDACTED"; "i")
     | gsub("(?<k>://[^:/@\\s]+:)[^@/\\s]+@"; "\(.k)REDACTED@"))}' \
  >> "$log" 2>/dev/null

jq -cn --arg d "$decision" --arg r "$msg" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
exit 0
