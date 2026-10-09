---
name: review-diff
description: Fresh-context review of the current branch against its intent (spec, plan, or PR description), then triage each finding — fix, defer, ask, or dismiss with a reason. Use before declaring a multi-file change done, before opening a PR, or when asked to review against the plan. For a pure bug hunt, the built-in /code-review is the alternative.
argument-hint: "[base ref] [spec or plan path]"
effort: high
---

# /review-diff — a reviewer who wasn't there, and a triage that isn't a rubber stamp

Args: $ARGUMENTS

## 1. Pin the range and the intent
- Base: the ref given, else `git merge-base origin/HEAD HEAD` (fall back to main or master). Don't diff against a bare `origin/main`, which shows phantom deletions once main moves, or `HEAD~1`, which drops earlier commits.
- Record BASE and HEAD SHAs and whether there are uncommitted changes. Don't read the diff into this conversation; the reviewer reads it in its own context.
- Intent: the spec or plan given, the plan this branch implements, or the PR description. Without intent a reviewer can only judge the diff against itself. If none exists, write 3–5 lines of intent and confirm them with me.

## 2. Dispatch the reviewer
Dispatch the `code-reviewer` subagent (or a general-purpose one on opus, or fable if enabled). Give it only BASE..HEAD (it runs `git log`, `git diff --stat`, and `git diff -U10` itself, plus `git diff HEAD` for uncommitted work), the intent paths, the plan's Review focus list, and the project's check commands — not this conversation. Its brief:
- Stay read-only: don't modify files, the index, or branches.
- Report gaps that affect correctness or the stated requirements: missing or partial requirements, behavior that contradicts the spec, unrequested scope, bugs, security issues, tests that can't fail or don't exercise the behavior, and deleted or weakened tests. Judge behavior the spec is silent on by what a reasonable user would expect.
- For every finding, give file:line, what's wrong, the consequence, severity (critical, important, or minor), and confidence.
- Add a "declined to judge" list of anything it noticed but set aside, with the reason.
- Skip style preferences unless they hide a bug.

For an independent bug hunt, suggest I also run `/code-review`.

## 3. Triage (you, with the full context)
For each finding, read the cited code beyond the diff hunk and confirm the consequence is real. Then:
- **Fix** it if it's real and critical or important. Use a test that fails first, then rerun the suite.
- **Defer** it if it's real but minor or out of scope. Add one line to the plan's Decision log.
- **Ask** me if it needs a product or design decision.
- **Dismiss** it if it's refuted or unsubstantiated, and write the reason. Never drop a finding silently.

Handle each "declined to judge" line the same way.

## 4. Stop rule
Do one review and one fix pass, then a scoped re-check of just the fixes. If a third pass still finds non-trivial problems, the plan or spec is wrong. Stop and say what to rethink rather than patching again.

Report counts by outcome, the fixes with their tests, the deferred list, and the decisions I need to make.
