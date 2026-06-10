---
description: "Financial / quant analysis: precision, bias guards, disclaimers"
paths:
  - "**/finance/**"
  - "**/quant/**"
  - "**/trading/**"
  - "**/backtest/**"
  - "**/portfolio/**"
  - "**/*.ipynb"
---

# Financial & Quant Analysis

- **Not investment advice.** Every analysis is educational/informational; add a brief disclaimer and recommend a licensed professional for decisions.
- Use `decimal.Decimal` for money — never binary `float`. Quantize (`Decimal('0.00')`) with an explicit rounding mode.
- Never invent tickers, prices, returns, or ratios — pull from a real source and validate. Financial hallucinations look confident and specific.
- Look-ahead bias: use point-in-time data; never let future / end-of-day info leak into a decision made earlier.
- Survivorship bias: include delisted/bankrupt names; current-constituents-only datasets inflate returns.
- Backtests: model fees, slippage, and spread; validate out-of-sample / walk-forward, not just in-sample fit. Beware overfitting.
- Validate data on ingest: flag duplicate timestamps, gaps, and impossible jumps; cross-check against a second source.
- Adjust historical prices for splits/dividends; state whether figures are adjusted vs raw.
- Reproducibility: pin the data snapshot + date range + code + environment; treat output as a pure function of those.
- State data-source caveats (vendor, as-of date, known quality issues).

**Defaults:** `pandas`/`polars` + `numpy`; `statsmodels` for econometrics; `Decimal` for currency. `yfinance` is an unofficial Yahoo scraper — expect breakage, rate limits, and cross-market inaccuracy; cache results, validate against an official source, and don't rely on it for production or precise figures.
