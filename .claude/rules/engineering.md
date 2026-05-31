---
description: "Software engineering and delivery practices"
---

# Engineering Practices

## Code Quality
- Name for intent: searchable, pronounceable nouns for data, verbs for functions; no abbreviations or single letters outside loops.
- Keep functions small and single-purpose; if you need "and" to describe it, split it.
- Use early returns/guard clauses to flatten nesting; avoid `else` after a return.
- Prefer pure functions: same input → same output, no hidden side effects; isolate I/O at the edges.
- Prefer composition over inheritance; reach for inheritance only for genuine "is-a" substitutability (Liskov).
- Apply SOLID as guidance, not dogma; don't abstract until a second concrete case exists.
- Follow YAGNI/KISS: build for today's known requirements, not imagined ones.
- DRY real duplication of knowledge; tolerate incidental repetition over the wrong abstraction.
- Don't optimize before measuring; make it correct and clear first, fast only where profiled.

## Version Control
- Commit messages follow Conventional Commits: `type(scope): description` (feat, fix, docs, refactor, test, chore).
- Mark breaking changes with `!` or a `BREAKING CHANGE:` footer; drive SemVer from commit types.
- Make atomic commits: one logical change, independently revertable, building green on its own.
- Use trunk-based development: integrate to `main` daily behind branches that live hours-to-days, not weeks.
- Keep partially-built work hidden behind feature flags so trunk is always releasable.
- Open small, focused PRs (~200 lines or one self-contained change); split large work into stacked PRs.

## Code Review
- Run lint, format, type-check, and tests in CI; a human reviews only after automated checks pass.
- Approve when the change definitively improves overall code health, even if imperfect; don't block on perfection.
- Prefix non-blocking suggestions with "Nit:"; reserve blocking comments for correctness, security, and design.
- Review promptly in small slices; critique the code, not the author; explain the why and link to standards.

## CI/CD
- Order pipeline stages fast-to-slow (lint → types → unit → build → integration) and fail fast.
- Keep pre-commit hooks fast and lint-staged (format/lint changed files only); leave full suites to CI.
- Make builds reproducible: pinned dependencies, lockfiles, containerized build env.
- Automate dependency updates (Dependabot/Renovate) and fail the build on high-severity CVEs.

## Architecture & Ops
- Follow the twelve-factor app: config in env, stateless processes, disposable fast startup, graceful shutdown.
- Decouple deploy from release with feature flags; ship dark, roll out progressively, roll back by flipping a value.
- Record significant decisions as ADRs (context, decision, consequences); supersede rather than edit accepted ones.
- Evolve schemas with expand-contract: add new, dual-write/backfill, migrate readers, then drop old.
- Make write operations idempotent (idempotency keys) and degrade gracefully when dependencies fail.

## Observability
- Instrument with OpenTelemetry as the vendor-neutral standard for traces, metrics, and logs.
- Emit structured, machine-parseable logs; propagate correlation/trace IDs across every service hop.
- Prefer wide, high-cardinality structured events over scattered logs/metrics for debugging unknowns.
- Never log secrets, tokens, or PII; redact at the logging boundary.
- Define SLOs with error budgets; track DORA: deploy frequency, lead time, change failure rate, MTTR.

## Documentation
- Treat docs as code: live in the repo, reviewed in PRs, versioned with the code they describe.
- Maintain a README with purpose, setup, run, and test commands as the entry point.
- Let clear names and types document behavior; reserve comments for the "why," not the "what."
- Update or delete docs and comments in the same change as the code, so they never rot.
