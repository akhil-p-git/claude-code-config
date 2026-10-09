---
name: write-plan
description: Write a reviewable implementation plan from an approved spec or a clear request — files, interfaces, vertical slices, and exact verification commands — then stop for approval. Use for multi-file changes once the WHAT is agreed, or when asked to plan.
argument-hint: "[spec path or task]"
disable-model-invocation: true
effort: high
---

# /write-plan — decisions, not code

Input: $ARGUMENTS. If it's a spec, read it in full; the plan argues from it.

## Before writing
- Ground every step in the actual repo: read the code the plan touches. For unfamiliar areas, research first with parallel Explore subagents (file:line findings, no opinions), or ask me to run `/research-codebase`.
- Resolve open questions now: look facts up, ask me for decisions. The finished plan has no TBDs.
- If the work spans independent subsystems, propose separate plans.

## The plan
Save as `docs/plans/YYYY-MM-DD-<slug>-plan.md` (or the repo's existing plans location). Write for a capable engineer who hasn't seen this repo. Record what they can't decide alone (which files, names and signatures, values, the checks that prove each step) and leave idiomatic code to them.

- **Goal** in one sentence · **Spec** path · **Approach** in 2–3 sentences, with the main alternative rejected and why.
- **Global constraints** — exact values and rules every phase must respect: versions, naming, limits, behavior that must not change.
- **Not doing** — the explicit out-of-scope list.
- **Review focus** — up to five inputs or failure modes the spec implies but no step's test would exercise. Give each a test in the phase that owns it.
- **Phases as vertical slices** — each phase delivers a thin, working, demoable path end to end (stub first, then real), not one layer at a time. Per phase:
  - Files to create or modify (line ranges when modifying), and tests.
  - Interfaces it consumes from earlier phases and produces for later ones: exact signatures, types, routes, schemas.
  - Steps with one checkable result each. Behavior changes start with a failing test or a reproducing command.
  - **Verify** — exact commands and the output that means pass (for example `pnpm vitest run src/auth` with all tests passing, or `curl -s localhost:3000/api/health` returning `{"ok":true}`), plus any manual check for me.
- **Progress** (checkboxes) and **Decision log**, left empty for execution to fill in.

## Self-review, then stop
Check that every spec requirement maps to a step, names and types match across phases, every Verify can actually fail, nothing from "Not doing" crept in, and the plan is shorter than the code it describes. If code blocks dominate, cut them to signatures and test assertions.

Then give me the path, the phase list, and the riskiest assumption, and stop. Approving the spec isn't approving this plan. Run this outside plan mode, since plan mode blocks writing to docs/plans/. Once I approve, suggest `/clear` and then `/execute-plan <path>`.
