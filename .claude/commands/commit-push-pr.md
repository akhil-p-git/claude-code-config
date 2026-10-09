---
description: Verify, commit (Conventional Commits, explicit paths), push the branch, and open a PR whose body carries the evidence
argument-hint: "[title hint, or 'draft']"
disable-model-invocation: true
allowed-tools: Bash(git *), Bash(gh *), Read, Grep
---

Ship the current work as a pull request. Hint: $ARGUMENTS

State:
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Diff stat (staged and unstaged): !`git diff HEAD --stat 2>/dev/null || echo "(no commits yet)"`
- Commits ahead of the default branch: !`git log --oneline origin/HEAD..HEAD 2>/dev/null || echo "(no origin/HEAD; compute the base yourself)"`
- Existing PR: !`gh pr view --json url,state 2>/dev/null || echo "(no PR for this branch)"`

1. If the branch is main or master, create a descriptive branch first. Never push to the default branch.
2. Verify the final tree: run the project's full check (or `/ship-check`), unless it already ran in this session after the last edit, in which case cite that run. If anything is red, stop and report it; don't commit around it.
3. Stage explicit paths, never `git add -A` or `git add .`. Leave out secrets, `.env*` files (except `.env.example`), build output, and unrelated changes, and list anything you left out. Split unrelated changes, including structural vs behavioral, into separate commits.
4. Write each commit as Conventional Commits: `type(scope): summary`, with a body that says why.
5. Show me the commits and the PR title and body in one message and wait for my OK; running this command is intent, not approval of work I haven't seen.
6. Push with `git push -u origin <branch>`. If the push is rejected, stop and tell me. Never force-push without my explicit go-ahead.
7. Create the PR with `gh pr create --body-file <file>` against the default branch (as a draft if I asked), or update the existing one. If the repo has a PR template, fill that in; otherwise use these `###` sections:
   - What and why: 2–4 lines, linking the spec or plan if there is one.
   - Changes: short bullets by area.
   - Evidence: the exact commands run and their results (tests, typecheck, lint, build), plus screenshots for UI changes.
   - Risk and rollback: what could break, how to revert, and any migrations or flags.
   - Follow-ups: deferred items (omit the section if there are none).
8. Print the PR URL. Don't merge.
