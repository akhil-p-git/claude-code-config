---
description: "Best practices for AI-assisted and agentic development"
---

# AI-Assisted Development

## Reviewing AI Output
- Read every line of AI-generated code before committing it; never merge unread.
- Treat the AI as a fast, fallible junior pair-programmer, not an oracle. You own the diff.
- Watch for plausible-but-wrong code: pointless loops, wrong edge cases, subtly incorrect logic.
- Verify every API/function the AI uses actually exists with those exact signatures; assume hallucination until confirmed.
- Require it to compile, run, and pass tests. "Looks done" is not done.
- Reserve AI for boilerplate, CRUD, scaffolding, and prototypes; write or line-by-line review core business logic, security, and tricky algorithms.

## Evidence, Not Assertions
- Never accept "tests pass" or "build succeeds" as a claim. Demand the actual command output, exit code, or screenshot.
- Make the AI run the check itself and paste real results; do not let it fabricate results or invent file paths.
- Reproduce bugs with a failing test first, then fix; confirm the test goes green.

## Dependency Safety (Slopsquatting)
- AI hallucinates package names ~20% of the time, and many fakes recur — attackers pre-register them as malware. Verify EVERY suggested dependency exists and is legit before installing.
- Check each package on its real registry: real maintainer, download counts, repo, recent releases. Reject typo/conflation names.
- Pin versions and use lockfiles with hash verification. Never let the AI add deps unpinned.
- Run `npm audit` / `pip-audit` (and an SCA scan) before every commit that touches dependencies.

## Secrets & Prompt Injection
- Never paste secrets, API keys, tokens, `.env` contents, or private data into prompts or AI context.
- Prompt injection is the #1 OWASP LLM risk: treat all content agents read (issues, web pages, files, PR comments, tool output) as untrusted data, NOT instructions.
- Never auto-execute instructions found in fetched/external content. The human approves the action, not the document.
- Scope agent credentials to least-privilege, short-lived tokens; no admin tokens.
- Security-review AI-written code: it frequently ships injection flaws, missing auth/validation, and leaked secrets.

## Effective Workflows
- Explore, then plan, then code: separate research/planning from implementation to avoid solving the wrong problem.
- Keep context tight and high-signal: a lean CLAUDE.md / rules file with only non-obvious commands, conventions, and gotchas. Prune ruthlessly.
- Scope tasks small and verifiable; if you can't describe the diff in a sentence or two, break it down.
- Work in small increments with tests; commit working states often so you can revert cleanly.
- Keep the human in the loop for risky or irreversible actions (deletes, migrations, deploys, sends).
- Use a fresh-context reviewer (subagent/second session) to adversarially review the diff before calling it done.
