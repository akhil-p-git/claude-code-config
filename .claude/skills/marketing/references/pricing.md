# Pricing and packaging

Price is a positioning decision with a number attached. Decide the value metric, then packaging, then the number, then the page. A first price is a bet to learn from. Label every number as **Measured** (from data, with source) or **Estimated**.

## 1. Inputs
From the context doc: best-fit customer, who pays, the alternatives and what they cost (money and time). From the user: current plans and prices and any numbers (visitor→signup, signup→paid, average revenue per account, monthly churn, refunds), plus every variable cost per customer: LLM tokens, embeddings/retrieval, compute, storage, email/SMS, payment and billing fees, support time.

## 2. Value metric
The unit price scales with. Good metrics grow with the value the customer gets, let the customer predict the bill, are measurable by you, are hard to game, and track your main cost driver. Patrick Campbell's test: you can measure it and the customer agrees with the measurement; most products settle for a proxy.
| Candidate | Fits when | Watch out |
| --- | --- | --- |
| Seats | value grows with collaborators | punishes adoption; a weak proxy for AI work |
| Projects / sites / workspaces | value per unit of work | power users concentrate usage |
| Usage (runs, API calls, GB, minutes) | variable consumption; dev tools and APIs | bill anxiety → estimator, alerts, caps |
| Credits mapped to work | AI features with variable cost per task | opaque unless 1 credit ≈ a recognisable unit ("1 credit ≈ 1 summary") |
| Outcomes (resolved tickets, booked meetings) | the outcome is attributable and auditable | disputes; needs instrumentation |
| Flat | simple product, low usage variance | under-charges the top |
For AI products the common 2025–26 shape is a platform fee + included credits + overage (Kyle Poyar, Growth Unhinged, 2025 State of B2B Monetization: credit-based models up 126% year over year; he frames credits as a bridge to value-based pricing).

## 3. Cost floor (required whenever there's metered cost)
- Cost per unit of work = Σ(input tokens × input price + output tokens × output price) + retrieval/embeddings + compute + third-party calls. Measure p50 and p95 from logs or an eval run; re-measure after model or prompt changes.
- Gross margin per plan at expected and p95 usage must meet a target the user states (write down the assumption). If p95 users lose money: included quota + overage, hard caps on free plans, rate limits, a cheaper default model with an opt-in premium model, caching.
- Never sell "unlimited" on a metered cost; publish the fair-use number.

## 4. Packaging
- 2–3 tiers, each for a recognisable buyer (solo, team, business), not arbitrary feature splits. Design the middle tier first. Sort features into leaders (why people buy), fillers (nice extras), and killers (features that put off a segment and belong in another tier) — Madhavan Ramanujam, *Monetizing Innovation*.
- Fence by value-metric quantity first, then by what bigger buyers need: SSO/SAML, roles, audit log, SLA, invoicing, data residency.
- Free tier vs. trial: free tier when marginal cost is low and use spreads the product (shareable output, open source, SEO pages) or time-to-value is long; a 7–14-day trial when value shows quickly and each user costs real money; a reverse trial (full features, then downgrade to free) in between.
- Annual billing at about two months free; keep monthly.

## 5. Price point
- Floor: the next-best alternative's cost including the user's time. Ceiling: perceived value. Land between, closer to value when differentiation is strong.
- No data yet: choose the order of magnitude by buyer (~$10/month individual, ~$100/month team, ~$1,000/month business-critical) and start near a round number. Avoid the $5–9 B2B "frictionless" price: it attracts the least committed users and is hard to raise later (coreyhaines31/marketingskills `pricing`, MIT).
- Research sets ranges, not the final number: willingness-to-pay conversations at the concept stage (acceptable / expensive / prohibitive; trust only strong intent); Van Westendorp's four questions give an acceptable range (its "optimal price point" is a survey intersection, not a revenue maximum); Gabor-Granger for specific price points. The best evidence is a live price shown to new cohorts.

## 6. Pricing page
Plans and prices as HTML text (buyers ask AI assistants what tools cost; test by asking a browsing assistant for your plans). Mark the recommended plan; explain the value metric with an example ("about 300 summaries a month"); show overage prices and caps; a monthly/annual toggle showing both; FAQ on what counts as usage, what happens at the limit, cancellation and refunds, data export, invoices and VAT; payment processor and a security page link. Structured data only for facts visible on the page (`seo-geo.md`).

## 7. Changing prices
New customers first. Existing customers get advance notice, the reason (value shipped), and an option (lock in annual at the old price, time-boxed grandfathering). Roll out in waves, watch churn and support volume, keep an off-ramp. Never raise a renewal price silently.

## 8. Subscription compliance (flag for legal review when unsure)
- **ROSCA** (15 U.S.C. 8403) governs online subscriptions: "clearly and conspicuously disclose all material terms" before collecting billing details, get "express informed consent before charging", and provide "simple mechanisms for a consumer to stop recurring charges". The FTC's Sept 2025 Amazon settlement ($2.5B; Prime enrollment and cancellation) was brought under ROSCA.
- **FTC "click-to-cancel" rule**: vacated in full by the 8th Circuit on 2025-07-08. The FTC restarted rulemaking with an advance notice on 2026-03-11; no new proposed rule had been found as of 2026-10. Rely on ROSCA and state law, not the vacated rule.
- **California's auto-renewal law** (amended by AB 2863, in force 2025-07-01): separate express affirmative consent to the renewal terms, with records kept; free-to-paid conversions covered; an online save offer is allowed only next to a prominent direct "click to cancel" option; an annual reminder; notice 7–30 days before a price change takes effect.
- **EU consumers**: show prices including VAT; a 14-day withdrawal right applies to digital services unless validly waived; a price-reduction claim must reference the lowest price of the prior 30 days.

## Output
`docs/marketing/pricing.md`: recommendation (metric, tiers, prices, limits), unit-economics table (cost per unit p50/p95, margin per plan, Measured vs. Estimated), research and assumptions, page copy, rollout plan, and a plan-config skeleton for implementation (plan id, price ids, limits, overage).

## Gotchas
- Fake scarcity ("price goes up in 2 hours" when it doesn't) and countdowns that reset are named dark patterns; launch discounts need a real end date.
- A credit system without a published conversion to real work reads as a hidden price increase waiting to happen.
- Discounting the first year without stating the renewal price is the classic auto-renewal violation.

Sources (checked 2026-10-08): growthunhinged.com/p/2025-state-of-saas-pricing-changes · lennysnewsletter.com/p/saas-pricing-strategy (Campbell) · law.cornell.edu/uscode/text/15/8403 · ftc.gov Amazon settlement press release (2025-09-25) · Cooley alert 2025-07-11 (8th Circuit) · Greenberg Traurig alert 2026-03 (ANPRM) · KTS / Fenwick alerts on AB 2863. EU price-reduction rule from the Omnibus Directive (from memory; EUR-Lex not fetched).
