---
name: research-codebase
description: Map how an area of the codebase works today — where things live, how data flows, which patterns and tests exist — using parallel read-only subagents, and save a cited research doc. Use before planning changes in unfamiliar or large code, or when asked how something works.
argument-hint: "<question or area>"
disable-model-invocation: true
---

# /research-codebase — document what exists, not what should change

Question: $ARGUMENTS

Produce a map of the system as it is today: what exists, where, and how the parts interact, with file:line references. Don't propose changes, critique, or diagnose unless I ask. Opinions in research quietly steer the plan that follows.

1. Read any files I named in full, yourself, before delegating.
2. Split the question into 2–5 independent lookups and run them as parallel Explore subagents. A typical split: where the relevant code lives; how the main flow runs end to end; the closest existing pattern to copy; which tests and fixtures cover it; the config, env, and infrastructure it depends on. Give each one a narrow question and ask for file:line evidence.
3. When they return, read the lines behind the claims that matter most yourself. Re-dispatch where findings conflict.
4. Write `docs/plans/YYYY-MM-DD-<slug>-research.md` (or the repo's existing notes location) with: a header (date, `git rev-parse --short HEAD`, branch, question); Summary, answer first; Findings by component with file:line; Patterns and conventions to follow; Tests that cover it; Open questions the code couldn't settle.
5. Reply with the summary, the path, and the open questions. Follow-up questions append a dated section to the same doc.

Research describes one commit. If the doc is older than the code it describes, re-verify before relying on it.
