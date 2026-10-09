---
description: "Engineering preferences that differ from common defaults (loads when source files are touched)"
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,mts,cts,py,java,kt,cs,go,rs,rb,php,c,h,cpp,hpp,swift,sql,sh}"
---

# Engineering Preferences

- Commits are atomic: one logical change that builds green on its own. Never mix a refactor or reformat with a behavior change in the same commit.
- Keep PRs reviewable (~200 changed lines or one self-contained change); split bigger work into stacked PRs or ordered commits.
- Don't add an abstraction, config knob, or plugin point until a second real use exists. Three similar lines beat a premature helper.
- Don't optimize without a measurement; when you do, record the before/after numbers in the commit or PR.
- Make writes that can be retried idempotent (idempotency keys, upserts, dedupe on event IDs), and fail loudly rather than silently on unexpected states.
- Log structured events with a request/correlation ID; never log secrets, tokens, or personal data.
- Record decisions that are expensive to reverse as a short ADR (context, decision, consequences) in `docs/adr/`.
- Keep docs and comments true: update or delete the ones your change makes stale, in the same change.
