---
name: execute-plan
description: Execute an approved implementation plan phase by phase — verify each step with real command output, keep progress and decisions in the plan file so work survives /clear and compaction, and finish with a fresh-context review. Use when the user approves a plan file or asks to implement one.
argument-hint: "<plan path>"
---

# /execute-plan — implement exactly, prove each step, leave a trail

Plan: $ARGUMENTS

## Setup
- Read the plan and its spec in full. If Progress has checked items, resume at the first unchecked one. Trust the plan's Progress, its Decision log, and `git log` over your memory of earlier sessions.
- Don't implement on main/master. Create a branch, or a worktree (EnterWorktree or `claude -w`) when other work is in flight. In a fresh worktree, install dependencies and bring over the env files it needs first. Worktree sessions can't edit files in the main checkout, so if the plan lives there, copy the plan and spec into the worktree and keep the copy updated; it then ships with the branch.
- Run the full check once for a baseline (tests, typecheck, lint, whatever the project uses). Log pre-existing failures in the Decision log so they aren't mistaken for yours later.
- Read every Interfaces block before Phase 1. If two phases disagree, rule on it now.

## Each phase
1. Work the steps in order. For behavior changes, watch the new test or reproducing command fail for the expected reason before writing the fix.
2. Run each Verify command and compare the real output with the plan's expected result. If it matches, move on. If the code is wrong, find the cause (`/diagnose` for anything non-obvious); never edit, skip, or loosen a test or threshold to get green. If the plan is wrong, make the smallest change that satisfies the spec and log a Ruling.
3. Commit at the end of the phase: Conventional Commits, with structural and behavioral changes in separate commits.
4. In the same step, update the plan: tick Progress and add `verified: <command> → <result>`. That line is the only proof a phase is done.
5. Send long output (test runs, builds, logs) to a file and read the tail, so it doesn't flood context.

## Rulings, not stalls
Decide ambiguities and plan defects yourself, with the spec as the authority. Log each as `Ruling: <what> — <why> — <cost if wrong>`. A deviation without a logged ruling is a decision made in secret.

Stop and ask only for:
- irreversible or destructive actions (deleting data, migrations on shared data, force-push);
- security-sensitive changes;
- side effects outside this branch (merge, push to shared branches, deploy, publish, sending messages);
- a plan so wrong that every path forward is a guess;
- the same step still failing after two different fixes.

## Context
At a phase boundary in a long session, update the plan and tell me it's a good point to `/clear` and rerun `/execute-plan <path>`. The plan carries the state.

## Finish
1. Run the full check on the final tree. Report every failure by name, including ones you didn't cause.
2. Run `/review-diff`. Fix critical and important findings in one pass, each with a test that fails first, then log the rest as deferred.
3. Report what shipped per phase with its verified commands, every Ruling, deferred findings, and any manual checks the plan lists for me. Then offer `/commit-push-pr`.

To run it unattended, use auto mode and set a goal whose proof gets printed in the conversation, since the /goal evaluator only reads the transcript. For example: `/goal grep -c '^- \[ \]' <plan> prints 0, <full check command> exits 0, and git diff --diff-filter=D --stat <base> lists no test files — or stop when one of the stop-and-ask cases above needs me, or after 40 turns`.
