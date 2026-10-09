# Financial statement analysis

Data comes from the filings (`sec-edgar.md`) or files I provide. Every number cites its filing (form, period,
accession or page). Work in one currency and scale, stated in every table header.

## Step 1 — Assemble
- 3–5 fiscal years plus the latest quarters and LTM (LTM = last FY + YTD current − YTD prior).
- Record fiscal year end, 52/53-week years, reporting currency and scale, GAAP or IFRS, and any restatement
  (10-K/A, recast segments, discontinued operations). Use restated comparatives for trend work and say so;
  use first-reported values for anything point-in-time.
- Pull the notes you will need: revenue disaggregation, segments, debt maturities, leases, SBC, income taxes,
  commitments and contingencies, subsequent events. Read Item 7 (MD&A) and Item 9A (controls).

## Step 2 — Integrity tie-outs (stop and report if any fail)
| Check | Rule |
|---|---|
| Balance sheet | Assets = Liabilities + temporary (mezzanine) equity + total equity, including noncontrolling interest |
| Cash | Cash-flow ending balance = balance-sheet "cash, cash equivalents, and restricted cash" (since ASU 2016-18 restricted cash is included, so it may differ from the cash line alone) |
| Net income | Cash flow starts from consolidated net income, including the noncontrolling share |
| Retained earnings | Beginning RE + NI attributable to the parent − dividends ± other items = ending RE. SBC is credited to APIC, not retained earnings |
| Cash flow | CFO + CFI + CFF + FX effect = Δ cash |
| EPS | Diluted EPS ≈ NI to common ÷ weighted diluted shares (within rounding) |
| Segments | Segment totals reconcile to consolidated figures |

## Step 3 — Common-size, growth, and ratios
Show each line as % of revenue (income statement) and % of total assets (balance sheet), plus YoY growth and
CAGR. State every ratio's definition in the table, because sources disagree.

| Ratio | Definition used here |
|---|---|
| Gross, EBIT, net margin | ÷ revenue |
| EBITDA | EBIT + D&A from the cash flow statement; say whether SBC is added back (it shouldn't be by default) |
| ROE | NI to common ÷ average common equity |
| ROIC | NOPAT ÷ average invested capital; NOPAT = EBIT × (1 − operating tax rate); invested capital = debt + leases + equity − excess cash (state the excess-cash rule) |
| DSO · DIO · DPO | average AR ÷ revenue × days · average inventory ÷ COGS × days · average AP ÷ COGS × days (days = 365 annual, 91.25 quarterly) |
| Cash conversion cycle | DSO + DIO − DPO |
| Net debt | debt + lease liabilities (say if included) − cash and liquid investments |
| Leverage · coverage | net debt ÷ EBITDA · EBIT ÷ interest expense |
| Liquidity | current ratio; quick ratio = (current assets − inventory) ÷ current liabilities |
| FCF | CFO − capital expenditures; also show FCF − SBC and FCF ÷ net income |
| Capital intensity | capex ÷ revenue; capex ÷ D&A |
| Dilution | SBC ÷ revenue; change in diluted shares net of buybacks |

Banks, insurers, and REITs need sector metrics (NIM, efficiency ratio, CET1, combined ratio, FFO/AFFO); gross
margin and EBITDA are meaningless there.

## Step 4 — Quality of earnings and red flags
Flag each with the evidence (numbers and filing reference):
- Accruals ratio = (NI − CFO) ÷ average total assets; persistently positive and large, or CFO ÷ NI below 1 for
  several years.
- Receivables or inventory growing faster than revenue; DSO or DIO creeping up; DPO stretching (supplier
  financing, factoring); a quarter-end working-capital swing that reverses the next quarter.
- Capitalized costs rising faster than revenue (software development, contract acquisition costs, interest);
  longer useful lives or lower reserves (bad debt, warranty, inventory) that boost margins.
- Non-recurring items that recur; non-GAAP adjustments that exclude SBC, restructuring every year, or growing
  "other" items; the gap between GAAP and adjusted EPS widening.
- Revenue recognition: deferred revenue or RPO falling while revenue rises; bill-and-hold; channel stuffing
  hints (receivables and returns reserves).
- Governance: restatements, late filings (NT 10-K), auditor changes, material weaknesses (Item 9A), going-concern
  language, related-party transactions, frequent segment re-cuts.
- Off-balance-sheet and contingent items: guarantees, VIEs, purchase obligations, litigation, pension deficits,
  tax uncertainties.
- Effective tax rate swinging without explanation; large deferred tax valuation-allowance moves.

Optional screens (not for financial firms; quote as screens, not verdicts):
- Altman Z (1968, public manufacturers) = 1.2·WC/TA + 1.4·RE/TA + 3.3·EBIT/TA + 0.6·MVE/TL + 1.0·Sales/TA;
  below 1.81 is the distress zone, above 2.99 the safe zone.
- Piotroski F (2000): nine binary signals — ROA > 0, CFO > 0, ΔROA > 0, CFO > NI, lower long-term leverage,
  higher current ratio, no new shares issued, higher gross margin, higher asset turnover.
- Beneish M (1999, eight-variable) = −4.84 + 0.92·DSRI + 0.528·GMI + 0.404·AQI + 0.892·SGI + 0.115·DEPI −
  0.172·SGAI + 4.679·TATA − 0.327·LVGI; above −1.78 suggests manipulation risk (coefficients and threshold
  checked against secondary sources only; some use −2.22).

## Step 5 — Report
```markdown
# <Company> (<ticker>) — financial statement analysis, FY<..>–FY<..> + LTM to <date>
**Basis:** <GAAP/IFRS>, <currency, scale>, restated comparatives <yes/no>, sources <filings with accessions>
**Integrity checks:** <pass/fail per check>
**Summary (5 bullets):** growth, margins, cash conversion, balance sheet, the main risk
**Tables:** common-size IS/BS; ratios (definitions column); cash flow and FCF bridge
**Quality of earnings:** <flag → evidence → why it matters>
**Questions for management / next diligence steps:** <...>
_Educational analysis, not investment advice._
```

## Before calling it done
- [ ] Every tie-out in Step 2 passes or is explained.
- [ ] Ratio definitions printed with the table; units and periods consistent (no LTM over FY mixing).
- [ ] Two or three headline numbers checked against the filing document itself.
- [ ] Red flags cite numbers and filing locations; no flag rests on a single period without saying so.
