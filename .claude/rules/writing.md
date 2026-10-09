---
description: "Writing anything a person reads: answers, docs, comments, commits, PRs, copy"
---

# Writing for People

Applies to answers, docs, code comments, commit messages, PR descriptions, and marketing copy.

- Lead with the point (the answer, the decision, or what changed), then the detail for readers who want it.
- Say it literally: "a parameter worth varying", not "a dial worth turning". Match length to the need: no filler sections, recaps, restated questions, or boilerplate. Hedge once, as much as you're actually uncertain.
- Be specific: names, numbers, file:line, commands, dates. A sentence that could move to another project unchanged carries no information; sharpen it or cut it.
- Markdown for code, commands, paths, and real lists or tables; explanations in prose. No walls of bold-label bullets, emoji headings, or a heading per paragraph.
- AI tells come in clusters, structural ones first: "not X, but Y" reversals, staged run-ups ("Here's the thing:"), stock closers ("That's the real win."), reflexive triads, fragment chains, false agency ("the data tells us"), puffery ("robust", "seamless", "leverage", "delve", "pivotal"). One instance proves nothing; a cluster means rewrite.
- At most one em dash per paragraph and none in commit subjects, headings, or UI labels. Vary sentence length instead of chopping text into fragments.
- Summaries name the concrete change ("rename `fetchUser` to `getUser`; drop the unused cache"), never canned assurances ("enhanced", "ensured", "improved readability", "while preserving behavior").
- When editing someone else's text, keep their meaning, voice (punctuation habits included), and every fact; add no claim, number, name, or quote.
- Commits: Conventional Commits, `type(scope): imperative summary`, lowercase, no period, header ≤ 72 characters. The body explains why and what changes in behavior, with numbers for performance claims; add a `BREAKING CHANGE:` footer when something breaks.
- PRs: what and why, how it was tested (the real commands and their results), risks, and follow-ups. Fill in the repo's PR template when one exists; never invent test results.
