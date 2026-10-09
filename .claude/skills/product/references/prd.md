# Product briefs: pitch, PRD, PR/FAQ

A PRD decides *what and why* for users; `/spec` then states what the system shall do, and the `architect` agent designs it. Pick the lightest artifact that fits:
| Situation | Artifact |
| --- | --- |
| Small bet (≤ 2 weeks), problem clear | Pitch (Shape Up) |
| Feature with users, metrics, and a rollout | PRD |
| New product or big bet; test the story before building | PR/FAQ (Working Backwards) |
| Bug, refactor, or a change with one obvious solution | none — go straight to `/spec` or just fix it |

## 1. Evidence first
Write the problem as one specific story (who, when, what they did, what it cost) and attach the evidence: interview quotes (`interviews.md`), support tickets, issue threads, analytics (`tracking-plan.md`), churn reasons. No evidence → label it **Hypothesis** and propose the cheapest test that could change the decision (interview round, fake door, concierge MVP; `experiments.md`) before writing requirements.
Clarify in one round when key facts are missing: 3–5 numbered questions with lettered options and your recommended answer, so the user can reply "1A, 2C, 3B".

## 2. Pitch (Shape Up)
1. **Problem**: a single specific story showing why the status quo fails.
2. **Appetite**: the time you're willing to spend (2 days, 1 week, 6 weeks) — a constraint on the solution, not an estimate.
3. **Solution**: core elements only, as a breadboard (places → affordances → connections) or a fat-marker sketch in words; no pixel-level UI.
4. **Rabbit holes**: risky details resolved up front.
5. **No-gos**: what's excluded to fit the appetite.

## 3. PRD (aim for ≤ 2 pages)
- **Problem and evidence**: who has it, how often, the cost of not solving it.
- **Outcomes, not outputs**: 1–3 goals, each with metric, target, measurement method, and evaluation date. Leading (adoption, activation, task success, time-to-value) and lagging (retention, revenue, support volume).
- **Non-goals**, each with a one-line reason.
- **Users and jobs**: "When I …, I want to …, so I can …"; the current workaround; the trigger.
- **Solution sketch and key flows**, including empty, loading, error, permission, and limit states.
- **User stories** (`US-001 …`), each with checkable acceptance criteria in Given/When/Then form, including at least one negative case. "Works correctly" or "is intuitive" isn't a criterion.
- **Priorities**: P0 (can't ship without), P1 (fast follow), P2 (design for later, don't build).
- **Non-functional**: performance budget, accessibility (WCAG 2.2 AA), privacy and data handling, abuse and rate limits, cost per request for AI features (`marketing` skill → `pricing.md` cost floor).
- **Analytics**: events added or changed (names from the tracking plan) and where the outcome will be read.
- **Rollout**: flag, cohort, migration, docs, announcement tier (major / medium / minor → `marketing` skill: `launch.md`, `content-social.md`).
- **Risks**: riskiest assumption first, with the cheapest way to test it. **Open questions** with an owner, marked blocking or non-blocking.
Scope rule: anything added displaces something of equal size or extends the appetite, explicitly.

## 4. PR/FAQ (Working Backwards)
Press release, ≤ 1 page: heading (product named so the target customer understands it); subheading (who + benefit, one sentence; never "everyone"); summary with a realistic launch date; the problem from the customer's view; the solution, including what customers use today and why this is better; one quote from the maker and one from a hypothetical customer; how to get started. External FAQ: price, how it works, support, where to get it. Internal FAQ: alternatives, why better/cheaper/faster, market size, unit economics, dependencies, legal and privacy, and "the top three reasons this product will not succeed". A first draft should take hours, not days.

## 5. Prioritizing a backlog
RICE (reach × impact × confidence ÷ effort) or ICE. Write confidence as evidence, not feeling: High = seen in data or 3+ independent interviews; Medium = 1–2 sources; Low = opinion. Fix one bottleneck at a time: score items against the leakiest funnel stage (acquisition → activation → retention → revenue → referral) first. Re-score after each discovery round.

## Output and hand-off
`docs/product/<YYYY-MM-DD>-<slug>.md`, then `/spec <path>` → `/write-plan` → implementation.

## Gotchas
- Solution-shaped problem statements ("users need a dashboard") hide the real job; rewrite them as what the user is trying to get done.
- A goal phrased as a ship date or feature ("launch X") means outcomes weren't defined; stop and define them.
- Don't let a PRD absorb engineering decisions (data model, endpoints); those belong in `/spec` and the architect's design.
- Interview quotes in a PRD must be verbatim with their source; never paraphrase a user into saying what the feature needs.

Sources: basecamp.com/shapeup/1.5-chapter-06 (pitch ingredients) · workingbackwards.com/resources/working-backwards-pr-faq · anthropics/knowledge-work-plugins product-management/write-spec (Apache-2.0) · snarktank/ralph skills/prd (lettered questions, US-### stories; MIT).
