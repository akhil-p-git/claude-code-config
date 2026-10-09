# Spreadsheet financial models: conventions and audit

For building or editing the file itself, follow the `xlsx` skill (openpyxl, `recalc.py`, formula-function
limits). This reference adds the modeling discipline and the audit checklist. An existing model's own
conventions override everything here.

## Build rules
- **Layout:** Inputs → Calculations → Outputs, on separate tabs or clearly separated blocks; a Checks tab;
  time flows left to right with one consistent column per period; actuals and forecasts in the same rows with
  a visible boundary.
- **One formula per row** (FAST Standard: Flexible, Appropriate, Structured, Transparent): the same formula
  across every period of a row. A lone edited cell mid-row is the commonest silent error.
- **No constants inside formulas** (`=B5*1.05` is wrong; reference a labeled input). Every hard-coded input is
  blue and carries a comment with its source and date, or `[ASSUMPTION]` with the reason.
- **Colors:** blue inputs, black formulas, green links to other sheets, red links to other files, yellow fill for
  key assumptions the user should review.
- **Formats:** units in every header (`Revenue ($mm)`); negatives in parentheses; zeros as `-`; percentages stored
  as fractions; multiples as `0.0x`; years as text.
- **Prefer simple functions:** `SUMIFS`, `INDEX`/`MATCH`, `IFERROR` only where an error is expected and its
  replacement is meaningful (never `IFERROR(x, 0)` on a valuation multiple). Avoid `OFFSET` and `INDIRECT`
  (volatile, untraceable).
- **Circularity:** only when intended (interest on average debt ↔ cash), behind an iteration on/off switch
  with a circuit-breaker input; otherwise compute interest on opening balances.
- **Signs:** one convention, stated (e.g. cash outflows negative on the cash flow statement), applied everywhere.
- **Scenarios:** a case selector cell feeding an INDEX/CHOOSE consolidation column; projections reference the
  consolidated column, not nested IFs scattered through the model.
- **Sensitivity grids:** odd-sized, centered on the base case, each cell a full recalculation (not Excel Data
  Tables if the file will be recalculated by LibreOffice); check that the center equals the base output.

## Checks tab (each returns 0 or TRUE, and one master check sums them)
Balance sheet balances every period · cash flow ending cash = balance-sheet cash every period · retained
earnings roll-forward (prior + NI − dividends ± other; SBC goes to APIC) · debt schedule ties to the balance
sheet · D&A and capex tie between the PP&E schedule and the cash flow · sum of segments = consolidated ·
sensitivity center = base case · terminal growth < discount rate.

## Audit checklist (report first; fix only on request)
| Check | What to look for |
|---|---|
| Errors | `#REF!`, `#VALUE!`, `#DIV/0!`, `#NAME?`, `#N/A` (run `recalc.py`; zero errors required) |
| Hardcodes | constants inside formulas; pasted values where a formula belongs (a "formula row" with one typed number) |
| Consistency | a formula that differs from its row neighbours; ranges that miss the first or last row |
| Links | broken cross-sheet references; links to external files that will not travel |
| Units | thousands mixed with millions; % stored as 15 instead of 0.15; currency mismatches |
| Hidden content | hidden rows, columns, or sheets with overrides |
| Integrity | every Checks-tab test, per period |
| Logic | growth > 100% unexplained; margins outside the industry range; hockey-stick out-years; model breaks at 0% growth or negative EBITDA |
| Model-specific | DCF: wrong discount period (mid-year vs end), TV not discounted, book-value WACC weights, levered cash flows in an unlevered DCF. LBO: cash sweep vs debt paydown, PIK accrual, LTM vs NTM exit EBITDA, fees in day-1 equity. 3-statement: working-capital signs, depreciation vs PP&E schedule |

Severity: **Critical** (wrong output: imbalance, broken formula, cash doesn't tie) · **Warning** (hardcodes,
inconsistent formulas, edge-case failures) · **Info** (format and layout). Report as a table:
`# · Sheet · Cell/Range · Severity · Issue · Suggested fix`, preceded by one line: model type, overall verdict,
counts by severity.

Sources: xlsx skill (Anthropic); `audit-xls` and `3-statement-model` skills in anthropics/financial-services
(Apache-2.0); FAST Standard (fast-standard.org, version 02c, July 2019).
