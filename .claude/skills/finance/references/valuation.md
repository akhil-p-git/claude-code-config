# DCF valuation and comps cross-check

A valuation is a structured argument about the future, not a fact. Show the drivers, the sources, and the
ranges; never present a single number as "the value" or as a recommendation.

## Step 0 — Inputs (no silent defaults)
Every input is sourced with a date, supplied by me (`[USER]`), or marked `[ASSUMPTION]` with a reason. If an
input is missing, ask; do not default beta to 1.0, shares to 1, or terminal value to 0.

| Input | Source |
|---|---|
| Historical financials (3–5 years + LTM) | filings via `sec-edgar.md`; tie-outs from `financial-statements.md` |
| Share price and date | a named vendor and timestamp |
| Diluted shares | latest cover-page count + dilutive securities from the equity note, by the treasury stock method (in-the-money options and RSUs; converts if in the money). Iterate if dilution depends on the implied price |
| Risk-free rate | 10-year Treasury yield on the valuation date (FRED `DGS10`), in the cash flows' currency |
| Equity risk premium | a cited, dated source (e.g. Damodaran's monthly implied ERP); state which |
| Beta | regression (2–5 years, weekly or monthly, vs a broad index; report the standard error) or bottom-up: unlever peers βU = βL / (1 + (1 − t)·D/E), relever at the target structure |
| Cost of debt | yield to maturity on traded debt, or a rating-implied spread over the risk-free rate; after-tax at the marginal rate |
| Weights | market values at the target or long-run structure; gross debt. A net-cash company gets a debt weight ≥ 0, never negative; excess cash goes in the bridge |

## Step 1 — Free cash flow to the firm
FCFF = EBIT·(1 − t) + D&A − capex − ΔNWC.
- Forecast drivers, not line items: revenue growth, operating margin, sales-to-capital (or capex and NWC as %
  of revenue), tax rate. Fade growth and margins toward a steady state by the final year.
- Operating expenses are a % of revenue (not of gross profit). Tax: effective rate near term, marginal rate in
  the terminal year; model NOL usage if material (post-2017 federal NOLs offset at most 80% of taxable income).
- SBC is a real cost. Either leave it in EBIT (preferred) or add it back and count the future dilution — never
  add it back and ignore dilution.
- Leases: be consistent. If lease liabilities are treated as debt in the bridge, remove lease cost from operating
  expenses; otherwise leave both alone.

## Step 2 — Discounting and terminal value
- Mid-year convention: explicit-year cash flow t is discounted at (1 + WACC)^(t − 0.5).
- Perpetuity growth: TV_N = FCFF_N+1 / (WACC − g). Keep g below WACC and no higher than long-run nominal growth
  (a common ceiling is the risk-free rate). Make reinvestment consistent with growth:
  FCFF_N+1 = NOPAT_N+1 × (1 − g / RONIC) (value-driver formula).
- Exit multiple: TV_N = EBITDA_N × multiple from current peers, not a peak-cycle multiple.
- Discounting TV under the mid-year convention: a perpetuity-growth TV built from mid-year flows is discounted
  at N − 0.5; an exit-multiple TV is a sale at the end of year N and is discounted at N.
- Cross-check: report the exit multiple implied by the perpetuity TV and the growth implied by the exit-multiple
  TV. A large gap means one set of assumptions is wrong.
- Show TV as a share of EV. A share of 60–80% is common for growing firms; a high share means the answer is
  mostly the terminal assumptions, so say so rather than tuning it into a "normal" band.

## Step 3 — Enterprise value to equity value
Equity value = EV − debt (including finance leases, and operating leases if Step 1 treated them as debt) −
preferred stock − noncontrolling interests − unfunded pension and other debt-like items (after tax where
deductible) + cash and short-term investments + non-operating assets (equity-method stakes, investments not
in FCFF). Per share = equity value ÷ diluted shares.

## Step 4 — Sensitivity, scenarios, reverse DCF
- Grids are odd-sized (5×5 or 7×7) and centered on the base case, so the center cell equals the model's output;
  check that it does. Standard pairs: WACC × g, WACC × exit multiple, revenue growth × terminal margin.
- Scenarios (bear/base/bull) change drivers, not the answer; show probability weights only if I ask.
- Reverse DCF: solve for the revenue growth or terminal margin that the current price implies. It is often the
  more useful output.

## Step 5 — Comps cross-check
Build the peer range with `comps.md` and show it beside the DCF range (football field). Explain any gap
rather than averaging it away.

## Step 6 — Spreadsheet deliverable (if requested)
Follow `excel-model-conventions.md` and the `xlsx` skill: blue inputs, black formulas, green cross-sheet links; formulas, not pasted values;
every hard-coded input commented with its source; `recalc.py` at zero errors; a Checks tab (balance sheet
balances, cash ties, center-cell = base output, g < WACC). Then run an audit pass: hardcodes inside formulas,
inconsistent formulas across a row, off-by-one ranges, unit mixes (thousands vs millions, % stored as 15 vs 0.15).

## Report
```markdown
# <Company> — DCF and comps, valuation date <date>
**Inputs:** table of every input with source/date or [USER]/[ASSUMPTION]
**FCFF forecast:** drivers by year; FCFF; reinvestment and ROIC check
**WACC:** components with sources; weights; result
**Terminal value:** method(s), implied cross-checks, TV % of EV
**Bridge:** EV → equity → per share (diluted shares and method)
**Sensitivities and reverse DCF:** grids; implied growth or margin at today's price
**Comps:** peer table (median, IQR, NM rows shown); implied range
**What would change the answer:** the 2–3 drivers that matter
_Educational analysis, not investment advice._
```

## Before calling it done
- [ ] No input without a source, `[USER]`, or `[ASSUMPTION]`; no silent defaults.
- [ ] g < WACC; TV discounted at N − 0.5 (perpetuity, mid-year) or N (exit multiple); implied multiple and growth shown.
- [ ] Bridge includes every claim and non-operating asset; diluted shares by treasury stock method.
- [ ] SBC and lease treatment consistent between FCFF and the bridge.
- [ ] Grid center equals the base output; comps built per `comps.md`.
