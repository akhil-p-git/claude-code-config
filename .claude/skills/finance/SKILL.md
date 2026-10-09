---
name: finance
description: Finance, quant, and data-analysis playbooks — backtests and strategy research (point-in-time data, costs, trial ledger, PSR/DSR/PBO via bundled tested scripts), market and macro data (prices, splits, dividends, calendars, FRED vintages), SEC EDGAR fundamentals, financial-statement analysis, DCF and trading comps, spreadsheet model conventions and audits, portfolio risk reports, personal-finance and tax scenarios, and exploratory data analysis reports. Use for any request about a stock, fund, strategy, Sharpe ratio, portfolio, valuation, 10-K/10-Q, financial model, market data pull, budget/retirement/tax projection, or exploring a new dataset. Educational, not investment advice.
---

# Finance hub

Read the one reference that matches the task before doing anything else; read a second only if the task spans
both. Read `~/.claude/rules/finance.md` too unless it's already loaded (it's path-scoped); its invariants
always apply.

| Task | Read |
|---|---|
| Design, run, or judge a backtest, walk-forward, factor or signal study; "is this Sharpe real?" | `references/backtest-protocol.md` |
| Pull prices, dividends, splits, index or macro data; pick a vendor; adjusted-price, timezone, or missing-bar bugs | `references/market-data.md` |
| Fundamentals or filings from SEC EDGAR (XBRL facts, 10-K/10-Q/8-K, share counts, filing dates) | `references/sec-edgar.md` |
| Analyze a company's statements: tie-outs, ratios, quality of earnings, red flags | `references/financial-statements.md` |
| DCF, WACC, terminal value, EV-to-equity bridge, reverse DCF | `references/valuation.md` |
| Trading comparables, peer multiples, football field | `references/comps.md` |
| Build, edit, or audit a spreadsheet model (DCF, LBO, 3-statement, budget) | `references/excel-model-conventions.md` (+ the `xlsx` skill) |
| Portfolio returns (TWR/MWR), risk metrics, attribution, stress tests | `references/portfolio-risk.md` |
| Budget, debt payoff, mortgage, retirement, Monte Carlo, tax-year scenarios | `references/personal-finance.md` |
| Explore or profile a new dataset and write an EDA report | `references/eda.md` |

## Bundled scripts (tested 2026-10-08; `uv run --no-project --with numpy python3 …`, which leaves the project's env and lockfile alone, or `python3` where numpy is installed)
- `scripts/bt_report.py` — backtest statistics from a returns CSV (+ optional trial matrix): CAGR, Sharpe per
  period and AR(1)-corrected annual, PSR, MinTRL, DSR, PBO (CSCV), haircut Sharpe, MinBTL, Sortino, max
  drawdown, VaR/ES; ends with `RESULT:`/`NEXT:` lines. Formulas in `scripts/bt_stats.py` reproduce the published
  examples (Bailey & López de Prado, Harvey & Liu, Lo).
- `scripts/edgar_facts.py` — stdlib EDGAR client: declared User-Agent, rate limit, ticker→CIK, first-reported
  or as-of XBRL facts, tag fallback chains, derived fiscal Q4.
- `scripts/adjust.py` — CRSP/Yahoo-style back-adjustment of raw prices from a corporate-actions table, optionally
  as known on a date, plus exact total returns.

Run scripts; don't read them into context. Quote figures from their output, never retype them.

## Output contract (every finance deliverable)
1. Question and scope — entity, period, currency and units, as-of date.
2. Data — each source with URL or file, pull date, and point-in-time handling.
3. Method — assumptions marked `[ASSUMPTION]` with a reason, or `[USER]` if I supplied them.
4. Results — tables produced by code you ran; each key number traceable to a script output or cited filing.
5. Sensitivity and failure modes — what would change the conclusion.
6. Reproduce — commands, commit, data snapshot.
7. One line: _Educational analysis, not investment advice._

## Refusals (even when asked directly)
- No "the best parameter set is X" from an argmax; report the stable region and the trial count.
- No Sharpe ratio without T, the number of trials, and PSR/DSR; no backtest without costs; no reuse of a holdout.
- No price target, buy/sell call, or position size presented as a recommendation to act on.
- No order placement, transfers, or broker/trading tool calls without my explicit approval of that action.
