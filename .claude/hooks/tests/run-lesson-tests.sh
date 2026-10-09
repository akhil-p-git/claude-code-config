#!/usr/bin/env bash
# Compares the current capture-lesson.sh with the patched draft on labelled prompts.
# HOME is redirected to a scratch dir so the real ~/.claude/lessons-inbox.md is never touched.
here="$(cd "$(dirname "$0")" && pwd)"
old="$HOME/dev/claude-code-config/.claude/hooks/capture-lesson.sh"; new="$here/../capture-lesson.sh"
fake="$here/out/fakehome"; mkdir -p "$fake/.claude"
# label|prompt   (1 = a correction worth capturing, 0 = not)
cases='1|No, use pnpm not npm in this repo
1|Don'"'"'t add comments to every line
1|You keep forgetting to run the tests before saying done
1|why did you delete the migration file?
1|Actually that'"'"'s wrong, the API returns cents not dollars
1|Stop using any in TypeScript, I told you before
1|that broke the build
0|Stop the dev server and restart it
0|Actually, can you also add a dark mode toggle?
0|Nah we'"'"'re fine. Let'"'"'s start building.
0|Revert the last commit and push
0|No worries, continue
0|<task-notification> no issues found </task-notification>
0|<teammate-message teammate_id="x">No, the docs say otherwise</teammate-message>
0|Undo is fine, go ahead and implement the plan'
run() {  # run <hook> <prompt> -> 1 if captured
  rm -f "$fake/.claude/lessons-inbox.md"
  jq -cn --arg p "$2" '{session_id:"t",hook_event_name:"UserPromptSubmit",prompt:$p}' | HOME="$fake" "$1" >/dev/null 2>&1
  grep -qE '^- \[' "$fake/.claude/lessons-inbox.md" 2>/dev/null && echo 1 || echo 0
}
for h in old new; do
  hook="${!h}"; tp=0; fp=0; fn=0; tn=0
  while IFS='|' read -r want prompt; do
    got="$(run "$hook" "$prompt")"
    case "$want$got" in 11) tp=$((tp+1));; 01) fp=$((fp+1)); echo "  [$h] false positive: $prompt";; 10) fn=$((fn+1)); echo "  [$h] missed: $prompt";; 00) tn=$((tn+1));; esac
  done <<<"$cases"
  echo "$h: TP=$tp FP=$fp FN=$fn TN=$tn"
done
