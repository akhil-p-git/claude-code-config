---
name: tech-docs
description: "Write, restructure, or update repository documentation using the Diátaxis framework: README, tutorial, how-to guide, reference, explanation, architecture decision record (ADR), changelog, and troubleshooting pages. Classifies each page by what the reader needs, fills a matching template from facts verified in the code, runs every command and example, and tests the page with a fresh-context reader. Use when asked to write or review docs, a README, an ADR, a CHANGELOG, API or CLI reference, or a getting-started guide, or when a code change leaves docs out of date."
argument-hint: "[readme | tutorial | how-to | reference | explanation | adr | changelog | troubleshooting | review <path>]"
---

# Technical docs

Good docs answer one reader's need per page, with facts taken from the code and commands that were actually run. This skill covers repository docs (Markdown/MDX in the repo), not Claude Docs or Google Docs documents. The `docs-writer` agent should load it (`skills: [tech-docs]`) so delegated and in-thread docs follow one method; marketing and landing-page copy belongs to the `copy-editor` agent.

## 1. Classify the page (Diátaxis compass)

Ask two questions: does the reader need to do something or understand something, and are they learning or working?

| Reader | Learning (study) | Working (task at hand) |
|---|---|---|
| Doing (action) | Tutorial: a lesson that gets a beginner to a working result | How-to guide: steps to reach one real goal, for someone already competent |
| Understanding (cognition) | Explanation: why it works this way, trade-offs, history | Reference: exact, complete, neutral description of the machinery |

Other page types map onto these: a README is a landing page that routes readers to the four kinds; an ADR is an explanation of one decision; a CHANGELOG is reference; troubleshooting is a how-to per symptom.

One page does one job. When a draft mixes types, split it and link the parts. Common mixes: a tutorial carrying option tables (move them to reference), a how-to explaining history (move it to explanation), reference telling readers what they should do (move it to a how-to).

## 2. Gather facts from the code

- Read the manifest (`package.json`, `pyproject.toml`), scripts, `.env.example`, config schemas, CLI `--help` output, route handlers, existing docs, and recent commits.
- Never invent a command, flag, environment variable, URL, port, version, default, or limit. Each one must come from the code, the config, or output you ran. If it's missing, ask, or leave a visible `TODO(docs):` naming what's needed.
- Write down the audience and what they already know in one line before drafting.

## 3. Draft from the template

Templates live in `templates/`: [README](templates/README.md), [tutorial](templates/tutorial.md), [how-to](templates/how-to.md), [reference](templates/reference.md), [explanation](templates/explanation.md), [ADR](templates/adr.md), [changelog](templates/changelog.md), [troubleshooting](templates/troubleshooting.md). Delete the guidance comments when you fill one in.

Rules for every page:
- The title is shaped like the reader's goal or question, in sentence case: "Deploy to Vercel", "How to rotate API keys", "About the caching model". Not "Deployment" or "Caching".
- The opening says what the page covers and who it's for, in at most two sentences. Don't pre-announce ("In this guide, we will explore…").
- Write in second person, active voice, present tense. Put conditions before instructions: "To run tests in watch mode, run `pnpm test --watch`."
- Steps are numbered, one action each, in the imperative, followed by what the reader should see when that helps them confirm progress.
- Code blocks have a language tag, can be pasted as-is, stay under about 25 lines, and get a sentence of prose explaining them. Placeholders look like `your_api_key` and are named in the text.
- Use exact values with units (`64 KB`, `200 ms`) and ISO dates.
- Link text names the destination; never "here". Use relative links inside the repo.
- Bold is for UI labels only. Paths, commands, identifiers, and environment variables go in `code`.
- No marketing words (easy, simply, just, powerful, seamless), no "Conclusion" section, no FAQ of invented questions. Follow `rules/writing.md`.

## 4. Verify

1. Run every command and code sample, from a fresh clone or worktree when the page covers setup (`git worktree add`, then the documented install). Paste only real output. Record anything you couldn't run (needs credentials, production access) and say so in the report.
2. Check that every relative link and anchor resolves.
3. Re-read the prose against `~/.claude/rules/writing.md` (AI tells, vague claims, padding) and fix what you find; leave quoted examples alone.

## 5. Test with a fresh reader

For a new README, tutorial, or how-to, spawn a general-purpose subagent with only the page text (not the repo, not this conversation). Give it five questions a real reader would bring, then ask: what is ambiguous, what does the page assume you already know, and where would you get stuck following it? Fix what it gets wrong. Repeat once if the fixes were substantial. If you can't spawn a subagent (for example, when running as the `docs-writer` agent), list the questions a first-time reader would ask and make sure the page answers each one. For a tutorial, a stronger test is to have the subagent follow the steps in a scratch worktree and report the first step that fails.

## 6. Keep docs in sync

- After a code change, grep the docs for changed symbols, flags, environment variables, and routes. Edit only the affected passages, keep the page's tone, and keep headings and anchors; if a heading must change, keep the old anchor with `<a id="old-anchor"></a>`.
- If more than about 40% of a page would change, stop and propose a rewrite instead of patching.
- Record user-visible changes in `CHANGELOG.md` under `## [Unreleased]`.

## 7. ADRs

- Write one when a decision is expensive to reverse or a future reader will ask why it's like this: framework, data store, auth model, API style, hosting, a major dependency.
- File it as `docs/adr/NNNN-short-title.md` (the location `rules/engineering.md` uses; follow the repo if it already keeps ADRs elsewhere, such as `docs/decisions/`). Numbers are never reused. Status moves from proposed to accepted; to change a decision, write a new ADR that supersedes the old one and link both ways. Don't rewrite an accepted ADR beyond its status and links.
- Use [templates/adr.md](templates/adr.md): context, options considered, outcome with the reason, consequences good and bad, and how compliance will be confirmed.

## Report

One line per page with its type and why; files written; commands executed and their results; reader-test findings and fixes; open TODOs. Say plainly what you didn't verify.

Sources: diataxis.fr; Google developer documentation style guide; Microsoft Writing Style Guide; vercel-labs/writing-guidelines; makeareadme.com; standard-readme; MADR 4 and Nygard's ADR format; Keep a Changelog; anthropics/skills doc-coauthoring (reader testing); VoltAgent docs-drift-editor (no invented commands, blast-radius limit).
