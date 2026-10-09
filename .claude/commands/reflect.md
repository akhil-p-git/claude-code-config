---
description: "Promote auto-captured lessons into CLAUDE.md / rules / skills / hooks (human-approved); --prune to audit and trim"
argument-hint: "[--prune]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Grep", "Glob"]
# Enforces "promotion and pruning are always human-approved": this command rewrites the config
# and pushes to git, so only an explicit `/reflect` from the user may run it.
disable-model-invocation: true
---

# /reflect — promote lessons into the config

The raw inbox is `~/.claude/lessons-inbox.md`; the config repo is `~/dev/claude-code-config/.claude/`.
Arguments: `$ARGUMENTS` — with `--prune`, also run the prune pass (step 5).

## 1. Gather
- Read the inbox. No `- [timestamp]` entries → say there's nothing to promote and stop (unless `--prune`).
- Skim this session for corrections the hook missed. Drop capture noise: pasted logs, chat transcripts, questions that aren't corrections.

## 2. Decide whether each lesson earns a rule
Promote only if ALL hold:
- **Non-obvious**: the current model would get it wrong without being told. "Would a smarter model make this unnecessary?" → if yes, drop it.
- **Real**: it would have prevented an actual mistake — seen more than once, or once at real cost.
- **Specific**: an action with a trigger ("when X, do Y because Z"), a trap to avoid — not a description of how the code is organized (that goes stale; Claude can read the code).
- **Not already covered**: grep CLAUDE.md, rules/, skills/ for related wording; extend or fix the existing line instead of adding a near-duplicate, and never add one that contradicts another.

## 3. Pick the cheapest mechanism that enforces it (try in this order)
1. **Linter / formatter / type-checker config** in the project — if a tool can enforce it, don't spend prose on it.
2. **Hook or permission rule** (`hooks/` + `settings.json`) — for anything that must hold every time ("always X", "never Y"). Prose can be ignored; hooks can't.
3. **Skill** (`skills/<name>/SKILL.md`) — for a procedure or domain playbook needed only sometimes.
4. **Path-scoped rule** (`rules/<topic>.md` with `paths:`) — for conventions tied to certain files.
5. **Always-on rule or CLAUDE.md line** — last resort; it is paid for in every session. Ask "is this worth loading into every session?", not "is this true?".
Write it calmly and specifically, with the reason; no ALL-CAPS walls (they make everything shout, so nothing stands out). One line, one example at most.

## 4. Propose (REQUIRED human approval)
- Show each proposed change as a diff: destination file, the inbox lines it covers, and which test in step 2 it passes.
- Wait for approval. Let the user edit, drop, or redirect any item. Never write config unattended.

## 5. Apply
- Make the approved edits. Keep `CLAUDE.md` under ~100 visible lines and the always-on set (CLAUDE.md + rules without `paths:`) around 12 KB; when over, move detail into a path-scoped rule or skill.
- Remove only the promoted (or explicitly rejected) lines from the inbox.
- Commit and push with plain `git commit` / `git push` (no token env vars). Message `type(scope): description`; in the body, record the date and the incident that motivated each rule.

## 6. Prune pass (`--prune`, or when asked)
- First ask the user to run `/doctor` and `/skill-doctor` and share the output (context cost, never-used skills, oversized files). Optionally run the `claude-api` skill's prompt-audit on CLAUDE.md.
- Check CLAUDE.md, rules/, skills/, agents/ for the six instruction-file smells:
  lint leakage (rules a tool should enforce) · context bloat (always-on content needed rarely) · skill leakage (procedures in CLAUDE.md/rules) · conflicting instructions · init fossilization (stale facts, old model workarounds, dead paths) · blind references (links/pointers without "read this when …").
- Also remove: workarounds for older models, rules nothing has violated since the last model upgrade, duplicated content, agents/skills that overlap or are never used.
- Propose removals and merges as a diff, get approval, apply, then commit and push.
