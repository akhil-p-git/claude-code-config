---
description: "Promote auto-captured lessons into CLAUDE.md / rules (human-approved); --prune to tidy"
argument-hint: "[--prune]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Grep", "Glob"]
# Enforces the CLAUDE.md rule "promotion and pruning are always human-approved".
# This command rewrites memory and pushes to git, so the model must never invoke
# it on its own — only an explicit `/reflect` from the user may run it.
disable-model-invocation: true
---

# /reflect — promote lessons into the config

You are curating the self-improvement loop. The raw inbox is `~/.claude/lessons-inbox.md`.
Arguments: `$ARGUMENTS` — if it contains `--prune`, also run the Prune pass (step 5).

## 1. Gather
- Read `~/.claude/lessons-inbox.md`. If it's missing or has no `- [timestamp]` entries, say there's nothing to promote and stop (unless `--prune` was passed).
- Skim the current session for corrections that may not have been auto-captured.

## 2. Cluster & generalize
- Group related entries into recurring patterns. Drop one-off, task-specific gripes — only promote rules that will generalize to future work.
- For each pattern, draft ONE terse, imperative rule:
  - Start with NEVER / ALWAYS / a verb. Be specific and verifiable ("use X, not Y"), never aspirational. One line; one example max; no platitudes.
- Choose the right home for each rule (do NOT default to CLAUDE.md):
  - Universal, every-session → `~/.claude/CLAUDE.md`
  - Language/topic, path-scoped → the matching `~/.claude/rules/*.md` (respect its `paths:` frontmatter)
  - A repeatable procedure → a new/existing command or skill
  - Must-happen-deterministically → propose a hook, don't just write prose

## 3. Propose (REQUIRED human approval)
- Show a concise preview: each proposed rule, its destination file, and which inbox lines it covers.
- Ask for approval. Let the user edit, drop, or redirect any item. NEVER write memory unattended.

## 4. Apply
- On approval, make the edits. Keep every file lean — if `CLAUDE.md` would exceed ~100 lines, put the detail in a rule instead.
- Remove only the promoted lines from `lessons-inbox.md` (leave un-promoted ones).
- Commit & push the config repo using the git-auth bypass from `CLAUDE.md`, message `type(scope): description` (e.g. `chore(rules): promote lessons on python testing`).

## 5. Prune pass (only with `--prune`, or when asked)
- Scan `CLAUDE.md` + `rules/*.md` for contradictions, stale/over-fit rules, duplication, and anything failing the test "would removing this cause a specific mistake?"
- Propose removals/merges (show a diff), get approval, apply, then commit & push.
- Goal: `CLAUDE.md` under ~100 lines and every rule sharp.
