# Trading comparables

Relative valuation answers "what does the market pay for similar cash flows today", not "what is this worth".
Use it next to a DCF (`valuation.md`), never instead of reading the businesses.

## Step 1 — Peer set
- Same business model, end markets, scale band, growth and margin profile, and geography; 5–10 names.
- Write the inclusion rule and list every exclusion with its reason. Better three true peers than eight loose ones.
- Flag conglomerates, recent M&A, pending deals, and distressed names; show them separately or exclude them.

## Step 2 — Inputs (one date for everything)
- Share price, diluted shares (treasury stock method from the latest filings), and the financials, all as of the
  same date and from named sources (`sec-edgar.md`, a dated market-data vendor). Forward estimates need a named
  consensus source and date; never fill them in yourself.
- Enterprise value with the full bridge: market cap + debt (and leases if your EBITDA excludes lease cost) +
  preferred + noncontrolling interests − cash and short-term investments − non-operating assets
  (equity-method stakes, investments).

## Step 3 — Consistency rules
- Numerator and denominator cover the same claims: if EV includes noncontrolling interests, EBITDA includes 100%
  of those subsidiaries; if equity-method stakes are subtracted from EV, their income is excluded from EBITDA.
- Same period basis for every company: calendarize different fiscal year-ends to CY or NTM by month-weighting
  (e.g. FYE March: CY2025 = 0.25 × FY2025 + 0.75 × FY2026).
- Same definitions: EBITDA before or after SBC (state it; don't mix), adjusted vs reported (use reported unless
  you adjust every peer the same way), diluted EPS.
- Same currency at one FX date.

## Step 4 — Multiples and statistics
- Core: EV/Revenue, EV/EBITDA, EV/EBIT, P/E; add sector metrics where they matter (EV/ARR and Rule of 40 for
  SaaS, P/TBV and ROE for banks, P/FFO for REITs — EBITDA is meaningless for banks).
- Negative or non-meaningful multiples (negative EBITDA, P/E over ~100×) display as "NM" and are excluded from
  statistics. Never coerce them to 0 (`IFERROR(…, 0)` drags medians down).
- Report median and interquartile range for each multiple; mean only as secondary. Show n for each statistic.
- Pair each multiple with its driver (EV/EBITDA vs EBITDA growth or ROIC) to explain dispersion before applying it.

## Step 5 — Apply
- Apply the peer IQR to the target's metric on the same basis (LTM with LTM, NTM with NTM) to get an EV range,
  then bridge to equity value per share with the target's own claims and diluted shares.
- Show the comps range beside the DCF range and any precedent-transaction range (football field). Explain any
  gap rather than averaging it away.

## Red flags
Mixed periods (LTM vs FY vs NTM) · stale prices · peers with pending deals · one outlier driving the median ·
differences above ~10% between sources for the same figure · different fiscal year-ends left uncalendarized.

## Output
```markdown
# <Target> — trading comps as of <date>
**Peer set:** included (rule) · excluded (reason)
**Table:** company · price date · mkt cap · EV (bridge) · revenue/EBITDA/EPS basis (LTM/NTM, source) · multiples · NM flags
**Statistics:** median, IQR, n per multiple
**Implied range for <target>:** EV → equity → per share
**Caveats:** comparability gaps, estimate sources, calendarization
_Educational analysis, not investment advice._
```

## Before calling it done
- [ ] One pricing date; diluted shares; full EV bridge for every company.
- [ ] Calendarized to a common period; definitions consistent; NM rows excluded from statistics, not zeroed.
- [ ] Every input cites a source and date; forward estimates name their consensus source.
