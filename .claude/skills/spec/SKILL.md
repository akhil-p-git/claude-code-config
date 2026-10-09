---
name: spec
description: Turn a feature idea into an agreed, written spec before any planning or code. Sizes the request first (spike / bounded / architectural), interviews in dependency-ordered rounds with recommended answers, then writes a self-contained spec with observable acceptance checks. Use for new features, subsystems, or requests whose intent or scope is unclear.
argument-hint: "[idea, ticket text, or path to notes]"
disable-model-invocation: true
---

# /spec — agree on WHAT and WHY before HOW

Input: $ARGUMENTS (if empty, ask what we're building and why).

## 1. Size it first, out loud
Read enough to classify (README, CLAUDE.md, the code the request touches, recent commits), then say which path you're taking so I can override:
- **Spike** — a feasibility question. State the question and the cheapest probe in 2–3 sentences, get a nod, answer it. Anything built is throwaway.
- **Bounded** — a change to a flow that already exists in this repo. Ask only the questions that matter, give a short design in chat (approach, files, how we'll verify), then stop until I say yes. No spec file.
- **Architectural** — new subsystem or project, an interface/schema others depend on, or unclear intent. Run the full process below.

When unsure, take the heavier path. If hidden complexity appears later, say so and step up; never step down silently. If the request bundles independent subsystems, propose a split and spec only the first.

## 2. Interview in rounds (architectural path)
- Facts are your job: get them from code, docs, git history, or Explore subagents. Decisions are mine.
- Keep a decision tree. Each round, ask every question whose prerequisites are already settled — numbered, each with your recommended answer, worded so "yes" accepts it. Questions that depend on unanswered ones wait for a later round.
- Cover purpose and success first (what changes for the user, how we'll know it worked), then constraints, edge cases, failure modes, and what must not change.
- Stop when no open decisions remain. Reflect the shared understanding back, separating what I said from your assumptions, and get my confirmation.

## 3. Write the spec
Save as `docs/plans/YYYY-MM-DD-<slug>-spec.md` (or the repo's existing specs location). Sections:
- **Problem & outcome** — the user-visible problem and what success looks like, measurable where possible.
- **Requirements** — numbered, as `WHEN <condition> THE SYSTEM SHALL <behavior>`.
- **Unchanged behavior** — `WHEN <condition> THE SYSTEM SHALL CONTINUE TO <behavior>` for adjacent behavior that must keep working.
- **Acceptance checks** — how each requirement will be demonstrated: a test, a command with its expected output, or a UI step. Include at least one end-to-end check.
- **Out of scope** and **Assumptions** (label any I didn't confirm).
- **Decisions** — key choices, the alternatives rejected, and why.

No file paths or code; those belong in the plan. No TBDs: an open question means the interview isn't finished. Before showing me, check for placeholders, contradictions, requirements that could be read two ways, and acceptance checks that couldn't actually fail.

## 4. Hand off
Give me the path and ask me to review it. Agreeing on the idea is not approving the spec, so wait. Once approved, suggest `/write-plan <spec path>`, ideally after `/clear`.
