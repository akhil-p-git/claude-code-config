#!/usr/bin/env bash
# PreToolUse(Bash) backstop for read-only agents (reviewers, auditors, analysts).
# Blocks commands that change the working tree, git state, installed packages, remote
# state (gh/curl writes, docker), or databases, and file writes outside /tmp. Scratch work
# under /tmp is allowed. It is a slip-catcher, not a sandbox: the agent prompt is the first
# line of defense, and deliberate obfuscation (bash -c, eval, scripts) gets through.
#
# Agent frontmatter:
#   hooks:
#     PreToolUse:
#       - matcher: "Bash"
#         hooks:
#           - type: command
#             command: "/home/akhil/dev/claude-code-config/.claude/hooks/readonly-bash-guard.sh"
# Tests: test-guards.sh (exit 2 = blocked, 0 = allowed).
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() {
  echo "Blocked by readonly-bash-guard ($1). This agent is read-only: inspect with git diff/log/show/blame/status, rg, grep, cat, ls, find; run project binaries with 'npx --no -- <bin>' or 'pnpm exec <bin>'; use 'uv run --frozen'; write scratch files only under /tmp. Report changes instead of making them." >&2
  exit 2
}

# 1. Heredoc bodies are data (usually a script written to /tmp): skip them, keep the lines around them.
heredoc_re='(^|[^<])<<-?[[:space:]]*['"'"'"]?([A-Za-z_][A-Za-z0-9_]*)'
s="" delim="" bodies=""
while IFS= read -r line || [ -n "$line" ]; do
  if [ -n "$delim" ]; then
    if [[ "$line" =~ ^[[:space:]]*"$delim"[[:space:]]*$ ]]; then delim=""; else bodies+="$line"$'\n'; fi
    continue
  fi
  s+="$line"$'\n'
  [[ "$line" =~ $heredoc_re ]] && delim="${BASH_REMATCH[2]}"
done <<<"$cmd"

# SQL clients: scan the statement text (quoted strings and heredoc bodies). Temp tables and COPY ... TO are fine.
if grep -Eq '(^|[;&|(`])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(psql|mysql|mariadb|sqlite3|duckdb|clickhouse-client|clickhouse)([[:space:]]|$)' <<<"$s"; then
  sql=$( { grep -ozE "'[^']*'|\"[^\"]*\"" <<<"$cmd" | tr '\0' '\n'; printf '%s' "$bodies"; } \
    | sed -E 's/COPY[[:space:]]*\(.*\)[[:space:]]*TO[[:space:]]/COPY_TO /Ig; s/CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?(TEMP|TEMPORARY)[[:space:]]/CREATE_TEMP /Ig')
  if grep -Eqiw 'INSERT|UPDATE|DELETE|MERGE|UPSERT|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE|VACUUM|REINDEX|ATTACH|DETACH|COPY' <<<"$sql"; then
    block "SQL that writes or changes the database"
  fi
fi

# 2. Allowed writes: redirects to /dev/null or /tmp (quoted or not) and fd duplication.
s=$(sed -zE '
  s#&>>?[[:space:]]*/dev/null##g
  s#[0-9]*>>?[[:space:]]*/dev/null##g
  s#[0-9]*>>?[[:space:]]*["'"'"']?(/tmp/|\$TMPDIR|\$\{TMPDIR\})[^[:space:];|&"'"'"']*["'"'"']?##g
  s#[0-9]*>&[0-9-]+##g' <<<"$s")

# 3. Quoted strings (even multi-line) become one token: /tmp paths stay recognizable,
#    everything else becomes Q, so search patterns can't trip rules but still count as arguments.
s=$(sed -zE '
  s#"(/tmp/[^"]*)"#/tmp/Q#g
  s#'"'"'(/tmp/[^'"'"']*)'"'"'#/tmp/Q#g
  s#"[^"]*"#Q#g
  s#'"'"'[^'"'"']*'"'"'#Q#g' <<<"$s")

# find expressions may contain \( \), so check deletes/execs before splitting.
if grep -Eq "(^|[;&|(\`[:space:]])find([[:space:]]+[^;&|]*)?[[:space:]](-delete|-fprint[^[:space:]]*|-fls|-exec(dir)?[[:space:]]+(rm|rmdir|mv|cp|mkdir|touch|chmod|chown|ln|truncate|shred|dd|tee|unlink|sed|perl))([[:space:]]|$)" <<<"$s"; then
  block "find that deletes or changes files"
fi

# 4. One simple command per line: split on && || ; | & $( ( ) and backticks.
segs=$(sed -E 's/(&&|\|\||;|\||&|\$\(|\(|\)|`)/\n/g' <<<"$s")

E='([[:space:]]|$)'
ARGS='([[:space:]]+[^[:space:]]+)*'
GIT='^git([[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|[[:space:]]+--?[A-Za-z][^[:space:]]*)*[[:space:]]+'
TMP='^(/tmp(/|$)|\$TMPDIR|\$\{TMPDIR\}|/dev/null$)'
WRAP='^(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|time|nice|nohup|command|exec|builtin|stdbuf|timeout|env|xargs|-[^[:space:]]+|[0-9.]+[smhd]?|\{\})[[:space:]]+)+'
FILE_CMDS='rm|rmdir|mv|cp|mkdir|touch|chmod|chown|chgrp|ln|truncate|shred|dd|tee|unlink|install|patch'

has() { [[ $seg =~ $1 ]]; }

# File-changing commands are allowed only when every target is under /tmp.
tmp_targets_only() {
  local -a w args=()
  read -ra w <<<"$seg"
  local cmdw="${w[0]}" t
  for t in "${w[@]:1}"; do
    [[ $t == -* || ( $cmdw == chmod && $t == +* ) ]] && continue
    args+=("$t")
  done
  if [[ $cmdw =~ ^(chmod|chown|chgrp)$ && ${#args[@]} -gt 0 && ! ${args[0]} =~ ^[/.$] ]]; then
    args=("${args[@]:1}")   # drop the mode/owner operand
  fi
  [ ${#args[@]} -ge 1 ] || return 1
  case $cmdw in
    cp|ln|install) [[ ${args[-1]} =~ $TMP ]] ;;
    dd)
      for t in "${args[@]}"; do [[ $t == of=* ]] && { [[ ${t#of=} =~ $TMP ]]; return; }; done
      return 1 ;;
    *) for t in "${args[@]}"; do [[ $t =~ $TMP ]] || return 1; done ;;
  esac
}

while IFS= read -r seg; do
  # Normalize to the command word: trim, drop wrappers (env assignments, time, xargs, ...),
  # path prefixes (/usr/bin/rm) and alias-bypass backslashes (\rm).
  seg="${seg#"${seg%%[![:space:]]*}"}"
  if [[ $seg =~ ^(time|nice|nohup|command|exec|builtin|stdbuf|timeout|env|xargs|[A-Za-z_][A-Za-z0-9_]*=) ]]; then
    seg=$(sed -E "s/$WRAP//" <<<"$seg")
  fi
  seg=$(sed -E 's#^(\\|/usr/local/bin/|/usr/bin/|/bin/)##' <<<"$seg")
  [ -z "$seg" ] && continue

  # Files outside /tmp.
  if [[ $seg =~ ^($FILE_CMDS)([[:space:]]|$) ]]; then
    tmp_targets_only || block "file change outside /tmp"
  fi
  has "^find${ARGS}[[:space:]]+(-delete|-fprint[^[:space:]]*|-fls)$E" && block "find that deletes or writes"
  has "^find${ARGS}[[:space:]]+-exec(dir)?[[:space:]]+($FILE_CMDS|sed|perl)$E" && block "find -exec that changes files"
  has "^(sudo|su|doas|systemctl|service|shutdown|reboot|mount|umount|crontab|chattr|mkfs[^[:space:]]*)$E" && block "system command"

  # Git state: commits, refs, index, HEAD, config, worktrees.
  has "${GIT}(add|commit|push|pull|merge|rebase|reset|checkout|switch|restore|clean|rm|mv|cherry-pick|revert|am|apply|bisect|update-ref|update-index|filter-branch|filter-repo|init|gc|prune|repack)$E" && block "git state change"
  has "${GIT}stash([[:space:]]*$|[[:space:]]+(push|pop|apply|drop|clear|save|store|create|branch|-))" && block "git stash"
  has "${GIT}(worktree[[:space:]]+(add|remove|move|prune|lock|unlock|repair)|notes[[:space:]]+(add|append|copy|edit|merge|remove|prune)|remote[[:space:]]+(add|remove|rm|rename|set-url|set-head|prune|update)|submodule[[:space:]]+(add|update|deinit|sync|init)|lfs[[:space:]]+(pull|fetch|checkout|prune|install))" && block "git state change"
  has "${GIT}tag[[:space:]]+(-d|-a|-s|-f|-m|[^-[:space:]])" && block "git tag change"
  has "${GIT}config${ARGS}[[:space:]]+(--unset[^[:space:]]*|--add|--replace-all|--rename-section|--remove-section|set|unset)$E" && block "git config change"
  has "${GIT}config([[:space:]]+--(global|system|local|worktree)|[[:space:]]+--file[[:space:]=][^[:space:]]+)*[[:space:]]+[^-[:space:]][^[:space:]]*[[:space:]]+[^-[:space:]]" && block "git config change"
  if has "${GIT}branch$E"; then
    has "${GIT}branch${ARGS}[[:space:]]+(-[dDmMcCfu]|--delete|--move|--copy|--force|--set-upstream-to[^[:space:]]*|--unset-upstream|--edit-description)$E" && block "git branch change"
    if ! has '[[:space:]](-a|--all|-r|--remotes|-l|--list|-v|-vv|--verbose|--show-current|--contains|--no-contains|--merged|--no-merged|--points-at|--format[^[:space:]]*|--sort[^[:space:]]*)([[:space:]]|$)'; then
      has "${GIT}branch[[:space:]]+[^-[:space:]]" && block "git branch creation"
    fi
  fi

  # GitHub CLI, HTTP, containers: anything that changes local branches or remote state.
  has "^gh[[:space:]]+(pr|issue|release|repo|workflow|run|secret|variable|label|gist|ruleset|cache|project|codespace|extension|auth|ssh-key|gpg-key|alias|config)[[:space:]]+(checkout|merge|close|reopen|comment|review|create|edit|delete|rerun|cancel|run|enable|disable|set|clone|fork|lock|unlock|ready|develop|upload|download|archive|unarchive|rename|sync|transfer|add|remove|delete-asset|login|logout|refresh|setup-git|install|upgrade|import)$E" && block "gh write"
  has "^gh[[:space:]]+api${ARGS}[[:space:]]+(-X|--method)[[:space:]=]*(POST|PUT|PATCH|DELETE|post|put|patch|delete)$E" && block "gh api write"
  has "^gh[[:space:]]+api${ARGS}[[:space:]]+(-f|-F|--field|--raw-field|--input)$E" && block "gh api write"
  has "^curl${ARGS}[[:space:]]+(-X[[:space:]]*(POST|PUT|PATCH|DELETE)|--request[[:space:]=]*(POST|PUT|PATCH|DELETE)|-d|--data[^[:space:]]*|-F|--form|-T|--upload-file)$E" && block "HTTP write"
  if has "^curl${ARGS}[[:space:]]+(-o|--output|-O|--remote-name)$E"; then
    has '(-o|--output)[[:space:]]+(/tmp/|/dev/null)' || block "download outside /tmp"
  fi
  if has "^wget$E|^wget[[:space:]]"; then
    has '(-O|--output-document)[[:space:]=]*(-|/tmp/|/dev/null)|-qO-|-O-|--spider' || block "download outside /tmp"
  fi
  has "^docker([[:space:]]+-[^[:space:]]+)*[[:space:]]+(run|rm|rmi|kill|stop|start|restart|build|push|pull|exec|create|commit|tag|cp|volume|network|system|image[[:space:]]+(rm|prune)|compose[[:space:]]+(up|down|rm|build|pull|push|run|exec|start|stop|restart|kill|create))$E" && block "docker state change"

  # Packages: installs and lockfile rewrites, unless this segment is a check or dry run.
  pkg_exempt=0
  has '[[:space:]](--dry-run|--check|--check-exists)([[:space:]]|$)' && pkg_exempt=1
  # uv sync that cannot rewrite uv.lock (it still installs into the project's .venv, like uv run --frozen).
  has '^uv[[:space:]]+sync([[:space:]]|$)' && has '[[:space:]](--locked|--frozen)([[:space:]]|$)' && pkg_exempt=1
  if [ $pkg_exempt -eq 0 ]; then
    has "^(npm|pnpm|yarn|bun)[[:space:]]+(i|install|add|remove|rm|uninstall|update|upgrade|up|ci|link|unlink|dedupe|prune|version|publish|unpublish|deprecate|dist-tag|init|create|rebuild|pkg[[:space:]]+(set|delete|fix))$E" && block "package change"
    has "^(pip|pip3|uv|poetry|pipx|conda|mamba|pipenv)[[:space:]]+(install|add|remove|uninstall|sync|lock|update|upgrade|inject|init|new)$E" && block "package change"
    has "^uv[[:space:]]+(pip[[:space:]]+(install|uninstall|sync|compile)|tool[[:space:]]+(install|upgrade|uninstall)|python[[:space:]]+(install|uninstall)|venv|self[[:space:]]+update)$E" && block "package change"
    has "^(cargo[[:space:]]+(install|add|remove|update|fix)|go[[:space:]]+(get|install|mod[[:space:]]+(tidy|edit|vendor))|brew[[:space:]]+(install|upgrade|uninstall)|pacman[[:space:]]+-S[^[:space:]]*|apt(-get)?[[:space:]]+(install|remove|upgrade))$E" && block "package change"
  fi
  has "^yarn[[:space:]]*$" && block "bare yarn installs packages"
  if has "^uv[[:space:]]+run$E"; then
    has '[[:space:]](--frozen|--locked|--no-project)([[:space:]]|$)' || block "uv run can rewrite uv.lock; use uv run --frozen"
  fi
  # Runners that download and execute packages on demand.
  if has "^(npx|bunx|uvx)$E|^(pnpm|yarn)[[:space:]]+dlx$E|^npm[[:space:]]+(exec|x)$E|^pipx[[:space:]]+run$E"; then
    has '[[:space:]](--no|--no-install|--offline)([[:space:]]|$)' || block "npx/dlx may download and run a package"
  fi
  has "(^|[[:space:]])playwright[[:space:]]+install$E" && block "browser install"

  # In-place edits, formatters, and fixers.
  has "^sed${ARGS}[[:space:]]+(-[a-zA-Z]*i[^[:space:]]*|--in-place[^[:space:]]*)$E" && block "in-place edit"
  has "^perl${ARGS}[[:space:]]+-[a-zA-Z]*i[^[:space:]]*$E" && block "in-place edit"
  has "[[:space:]](--fix|--write|--apply|--apply-unsafe)$E|^(npm|pnpm|yarn)[[:space:]]+audit[[:space:]]+fix$E" && block "auto-fix or write flag"
  has "(^|[[:space:]])(prettier|gofmt|goimports)${ARGS}[[:space:]]+-w$E" && block "formatter write"
  if has "(^|[[:space:]])(black|isort|ruff[[:space:]]+format|cargo[[:space:]]+fmt|terraform[[:space:]]+fmt|go[[:space:]]+fmt)$E"; then
    has '[[:space:]](--check|-check|--diff|-diff)([[:space:]]|=|$)' || block "formatter write"
  fi

  # Any redirect still present writes to a file outside /tmp.
  has '>' && block "redirect outside /tmp"
done <<<"$segs"
exit 0
