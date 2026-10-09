#!/usr/bin/env bash
# PreToolUse guard for read-only agents that use `memory:`.
# `memory:` silently grants Read/Write/Edit (code.claude.com/docs/en/sub-agents#enable-persistent-memory),
# so a "read-only" reviewer with memory can write anywhere. This keeps its writes inside its own
# memory dir (user/project/local scope) or /tmp. Exit 2 blocks the call and tells the agent why.
#
# Agent frontmatter:
#   hooks:
#     PreToolUse:
#       - matcher: "Write|Edit|NotebookEdit"
#         hooks:
#           - type: command
#             command: "/home/akhil/dev/claude-code-config/.claude/hooks/agent-write-guard.sh <agent-name>"
set -uo pipefail

agent="${1:-}"
input=$(cat)
path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
cwd="${cwd:-$PWD}"

[ -z "$path" ] && exit 0
if [ -z "$agent" ]; then
  echo "agent-write-guard: missing agent-name argument in the hook command" >&2
  exit 2
fi

case "$path" in /*) ;; *) path="$cwd/$path" ;; esac
real=$(realpath -m -- "$path")

for allowed in "$HOME/.claude/agent-memory/$agent" \
               "$cwd/.claude/agent-memory/$agent" \
               "$cwd/.claude/agent-memory-local/$agent" \
               "/tmp" "${TMPDIR:-/tmp}"; do
  base=$(realpath -m -- "$allowed")
  case "$real/" in "$base"/*) exit 0 ;; esac
done

echo "Blocked by agent-write-guard: '$agent' is read-only and may write only to its memory directory or /tmp (attempted: $path). Report the change instead of making it." >&2
exit 2
