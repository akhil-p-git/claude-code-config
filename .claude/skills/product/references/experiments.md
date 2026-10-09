# Experiments

Run experiments to make decisions. Most side projects lack the traffic to A/B test conversion; use the cheapest method that could change the decision.

## 1. Pick the method
| Question | Method |
| --- | --- |
| Does anyone want this? | interviews (`interviews.md`); fake door (button → "coming soon — want early access?"); a waitlist with a real ask; a concierge/manual MVP |
| Which message lands? | 5-second tests; headline variants in organic posts or a small ad spend; a subject-line split on a large list |
| Does this change move conversion? | A/B test only if the sample is reachable in ~2–4 weeks; otherwise before/after over whole weeks, or a staged rollout with a holdout |
| Does feature X retain users? | cohort comparison by adoption (correlation only), then a holdout to test causation |

## 2. Hypothesis and decision rule (write it before building)
"Because [evidence], we believe [change] for [segment] will move [primary metric] from [baseline] to [target] within [duration]. Guardrails: [refunds, support tickets, latency, cost per user]. Ship if [rule]; revert if [rule]."
One primary metric, tied to a funnel stage and measured server-side where possible.

## 3. Sample size and duration
- n per arm ≈ 16·p(1−p)/δ² (α = 0.05 two-sided, 80% power; Lehr's approximation). Example: baseline 3%, detecting a +20% relative lift (δ = 0.006) needs about 12,900 users per arm.
- Fix n and duration up front, in whole weeks. Don't stop on a peek unless the tool runs a sequential test designed for it.
- Randomize by user, not session, and keep assignment sticky across devices where possible.
- Check sample-ratio mismatch: if the observed split deviates from the planned one with chi-square p < 0.001, the setup is broken; fix it before reading results.

## 4. Readout
Effect size with a confidence interval (not just "significant"), guardrail movement, pre-registered segments only, and a novelty check (the last week alone). Log every experiment, including nulls, in `docs/product/experiments.md`: hypothesis, dates, n per arm, result, decision, lesson.

## 5. Tools
Vercel Flags + Flags SDK (`vercel:flags-sdk` skill), PostHog experiments, GrowthBook, Statsig. Removing the flag is part of done.

## Gotchas
- Testing five variants at once on low traffic guarantees noise; test one change with a big expected effect.
- A fake door must say plainly that the feature isn't available yet; don't collect payment for something that doesn't exist.
- Price tests: show each visitor one consistent price (sticky assignment) and honor what they saw; inconsistent prices erode trust and can raise consumer-law issues.
- "We'll learn something either way" is not a decision rule; write the ship/revert thresholds first.
