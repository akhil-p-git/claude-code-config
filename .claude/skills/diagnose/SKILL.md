---
name: diagnose
description: Root-cause a hard bug, flaky test, or performance regression — build a fast reproducing check first, then test ranked hypotheses one variable at a time, then fix with a regression test. Use when the cause isn't obvious after a first look, after a fix attempt failed, or when the user says debug, diagnose, or "why is this broken".
argument-hint: "[symptom, error, or failing test]"
---

# /diagnose — no fix without a reproducing check

Symptom: $ARGUMENTS

## 1. Build the feedback loop (most of the work)
Get one command that reproduces the exact symptom the user reported and can go red on this bug. Run it and show the output, with secrets redacted. Options, roughly in order:
- a failing test at the closest seam;
- a curl or HTTP script against the dev server;
- a CLI run diffed against known-good output;
- a Playwright script asserting on DOM, console, or network;
- replaying a captured payload or log;
- a throwaway harness around the failing function;
- a fuzz or property loop for "sometimes wrong";
- `git bisect run` with a check script, when it used to work;
- an old-vs-new differential run.

Make the loop fast and deterministic: pin time, seed randomness, isolate the filesystem and network. For flaky bugs, raise the reproduction rate (loop it, add stress) until it's debuggable. If you can't build a loop, say what you tried and ask me for access, a captured artifact (HAR, logs), or permission to add temporary instrumentation. Don't theorize without a loop.

## 2. Minimise
Shrink the repro until every remaining input, call, and config is load-bearing. Confirm it's the reported failure, not a neighbor.

## 3. Hypothesise, then test
Check recent changes (`git log -p` on the area, dependency bumps, env and config diffs) and compare against a similar path that works. Write 3–5 ranked hypotheses, each falsifiable: "if X is the cause, changing Y makes it disappear." Show me the list, then start on the top one; I may redirect you.

Test one variable at a time. Prefer a debugger or REPL, or a few targeted logs at the boundaries that separate hypotheses. Tag temporary logs (for example `[DBG-7f3a]`) so cleanup is one grep. For performance problems, measure a baseline first, then bisect.

## 4. Fix at the root
Turn the minimal repro into a regression test at a seam where the real bug pattern occurs. Watch it fail, fix the cause rather than the symptom, watch it pass, then rerun the original loop and the full suite. If no seam can hold the test, report that as a design finding.

If a fix fails twice, stop. The problem is likely the design or a wrong assumption. Tell me what each attempt revealed and where your model of the code was wrong before trying again.

## 5. Clean up
Remove tagged logs and throwaway harnesses, and put the confirmed root cause in the commit message.
