---
status: proposed  # proposed | accepted | rejected | deprecated | superseded by ADR-NNNN
date: YYYY-MM-DD
decision-makers: <names>
---

<!-- ADR (MADR 4 minimal + Confirmation). One decision, one to two pages, full sentences.
     File as docs/adr/NNNN-short-title.md. Never renumber; supersede instead of editing an accepted ADR. -->
# <Short title naming the problem and the chosen solution>

## Context and problem statement

<Two or three sentences on the forces at play and the question being decided. Link the issue or discussion.>

## Decision drivers

- <quality, constraint, or force, e.g. "must run on Vercel Functions without a long-lived connection">

## Considered options

- <Option A>
- <Option B>
- <Option C>

## Decision outcome

Chosen option: "<Option A>", because <the reason, tied to the drivers>.

### Consequences

- Good, because <positive consequence>.
- Bad, because <negative consequence, stated honestly>.

### Confirmation

<How we'll know the decision is being followed: a test, a lint rule, a review checklist item, a metric.>

## Pros and cons of the options

### <Option B>

- Good, because <argument>.
- Bad, because <argument>.

## More information

<Links to benchmarks, prototypes, related ADRs; when to revisit this decision.>
