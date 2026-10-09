---
name: product
description: Product management for the user's apps — PRDs and feature requirements, customer interview guides and synthesis (Mom Test, Jobs-to-be-Done), analytics tracking plans and event specs, and experiment (A/B test) design and readouts. Use when deciding what to build and how to measure it, rather than marketing it or writing the code.
argument-hint: "[prd|interviews|tracking|experiment] <feature, question, or data>"
---

# Product

Read the product context first if it exists: `.agents/product-marketing.md` (fallbacks `docs/product-marketing.md`, `.claude/product-marketing.md`). If it doesn't, `~/.claude/skills/marketing/references/product-context.md` describes how to draft one.

## Route to the playbook (read it in full before working)
| Task | Read |
| --- | --- |
| PRD, feature requirements, user stories, acceptance criteria | `references/prd.md` |
| Interview guides, screening, synthesizing interviews/reviews/support tickets, JTBD | `references/interviews.md` |
| Tracking plan, event naming, instrumentation spec, consent for analytics | `references/tracking-plan.md` |
| A/B test design, sample size, readouts, low-traffic alternatives | `references/experiments.md` |
For an engineering spec and implementation plan, use `/spec` then `/write-plan`; a PRD says *what and why* for users, a spec says *what the system shall do*.

## Guardrails
- Separate evidence from inference everywhere: verbatim quotes and measured numbers are evidence; patterns and recommendations are labeled as yours, with confidence. Never invent quotes, participants, or metrics.
- Every requirement and success metric must be checkable — "works correctly" or "users love it" are not acceptance criteria.
- Mark gaps inline as **Assumption** or **Open question** rather than smoothing them over; a PRD with hidden assumptions is worse than one with listed ones.
- Analytics must respect consent law (EU/UK) and never send PII to third parties without a stated purpose and basis.
- Before calling a PRD or synthesis done, have a fresh-context subagent read only the document and list the questions a reader would still have; answer them in the doc.

## Output
Write to `docs/product/<slug>.md` (or the repo's existing location) and summarize decisions, open questions, and next steps in chat.
