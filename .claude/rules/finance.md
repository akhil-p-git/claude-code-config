---
description: "Finance and quant: provenance of numbers, point-in-time data, backtest and risk-math invariants"
paths:
  - "**/finance/**"
  - "**/quant/**"
  - "**/trading/**"
  - "**/backtest*/**"
  - "**/portfolio/**"
  - "**/*{backtest,portfolio,valuation,dcf}*.{py,ipynb}"
  - "**/*.{beancount,ledger,journal}"
---

# Finance & quant

Procedures (backtest protocol, data vendors, EDGAR, valuation, risk reports, personal finance) live in the
`finance` skill. These are the invariants that hold whenever you touch finance code or data.

## Numbers
- Every figure you present was fetched (source + as-of date), computed by code you ran on fetched data, or given
  by me. Label anything else `[ASSUMPTION]`. Never type a price, ratio, or return from memory.
- Never fill a missing input with a "typical" value (beta 1.0, shares outstanding 1, terminal value 0 when
  WACC ≤ g, a 5% risk premium). Ask, or mark it `[UNSOURCED]` and say what it changes.
- Ledgers, invoices, tax, and cash balances use `Decimal`, quantized with an explicit rounding mode. Return and
  risk statistics may use float64, but money never round-trips through float.
- Carry units with every number: currency, scale (thousands vs millions), period (FY, CY, LTM), and per-period
  vs annualized.

## Time and point-in-time
- A value is usable only after it became knowable. SEC XBRL facts: `filed` strictly before the decision date
  (after-close filings carry that day's date). FRED: default "FRED mode" returns today's revised history, so use
  ALFRED vintages (`realtime_start`/`realtime_end`). Prices: after the bar closes.
- A signal computed from bar t's close trades at t+1 or later. Massive and Alpaca label bars by their start; a
  bar is known only at its end.
- Session dates are exchange-local (America/New_York for US). Use an exchange calendar (`exchange_calendars`
  XNYS) for holidays, 13:00 ET early closes, and ad-hoc closures. Keep timestamps tz-aware.
- Vendor-adjusted prices are rewritten after every split and dividend. Store raw prices plus a corporate-actions
  table; compute price floors, dollar volume, and share counts on raw values. Defaults differ: yfinance
  `auto_adjust=True` (no `Adj Close` column); Massive `adjusted=true` is splits only; Alpaca is `raw`.
- Universes are point-in-time and include delisted names. SEC, Yahoo, and today's index lists are current-only.

## Backtests
- Library defaults are optimistic. vectorbt fills at the same bar's close with zero fees and slippage; LEAN's
  default slippage model is zero; backtrader's `coc` fills at the signal bar's close. Set fills, fees, spread,
  slippage, and borrow explicitly and log them.
- Keep a trial ledger of every variant, including abandoned ones. Report Sharpe with T, the number of trials,
  PSR and DSR. Compute PSR/DSR on per-period Sharpe with raw kurtosis (Normal = 3). The holdout is used once.
- Before trusting or sharing a result, run the `finance` skill's backtest protocol and have `backtest-auditor`
  review it.

## Risk math
- Sortino's downside deviation is the RMS of min(0, r − target) over all periods, not the std of negative returns.
- Report VaR and Expected Shortfall as positive losses; prefer ES at 97.5%.
- Show CAGR next to any arithmetic mean. Annualize Sharpe by √q only when returns are not autocorrelated.
- Compare drawdowns only at equal horizon and sampling frequency. Benchmark total-return strategies against
  total-return indices (FRED `SP500` and Yahoo `^GSPC` are price-only).

## Output
- Educational analysis, not investment advice: say so once, briefly. Never place orders, move money, or call
  broker or trading tools without my explicit go-ahead for that specific action.
- Published performance (blog, deck, pitch) is labelled hypothetical or backtested, net of costs, over the full
  period, with no cherry-picked window. Registered advisers fall under SEC Rule 206(4)-1 (net alongside gross;
  1-, 5-, and 10-year periods).
- Reproducibility: pin the data snapshot (path and hash, or vendor and pull date), date range, code commit,
  lockfile, and seeds.
