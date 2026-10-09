#!/usr/bin/env bash
# PostToolUse + PostToolUseFailure (Bash|Monitor), registered with "async": true:
# append one JSON line per shell command Claude ran, for "what exactly did the agent do?"
# reviews that outlive transcript cleanup (cleanupPeriodDays). Zero added latency (async).
# Token-shaped strings are redacted; output is not logged (transcripts already hold it).
# File: ~/.claude/logs/bash-YYYY-MM.jsonl (monthly; prune old months by hand).

input="$(cat 2>/dev/null)" || exit 0
log="${CLAUDE_AUDIT_DIR:-$HOME/.claude/logs}/bash-$(date +%Y-%m).jsonl"
mkdir -p "$(dirname "$log")" 2>/dev/null || exit 0
jq -c '
  {ts: (now | todate), session: .session_id, agent: (.agent_type // null), mode: .permission_mode, cwd,
   tool: .tool_name, ok: (.hook_event_name == "PostToolUse"),
   exit: (if .hook_event_name == "PostToolUseFailure" then ((.error // "") | capture("^Exit code (?<n>[0-9]+)").n // "error") else "0" end),
   ms: .duration_ms, bg: (.tool_input.run_in_background // false),
   command: ((.tool_input.command // "")[0:4000]
     | gsub("(?<k>(sk-ant-|sk-or-|sk-proj-|sk-|ghp_|gho_|ghu_|ghs_|ghr_|github_pat_|glpat-|xox[abposr]-|sk_live_|rk_live_|AKIA|npm_|hf_)[A-Za-z0-9]{0,4})[A-Za-z0-9_\\-]{12,}"; "\(.k)…REDACTED")
     | gsub("(?<k>(Bearer|token|password|passwd|secret|api[_-]?key)[=: ]+)[^\\s\"]{8,}"; "\(.k)REDACTED"; "i")
     | gsub("(?<k>://[^:/@\\s]+:)[^@/\\s]+@"; "\(.k)REDACTED@"))}' <<<"$input" >> "$log" 2>/dev/null
exit 0
