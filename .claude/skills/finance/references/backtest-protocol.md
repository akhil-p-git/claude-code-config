# Backtest protocol

A backtest is a hypothesis test that is easy to fool. Assume the result is overfit until the steps below say
otherwise. Never present a backtest as a prediction or a recommendation.

## Refusals (even when asked directly)
- No "best parameter set" picked by argmax. Report the stable region and how many cells were searched.
- No Sharpe ratio without T, the trial count N, PSR(0) and DSR. No backtest without costs.
- No second look at the holdout. Once it has been used, it is in-sample.
- No conclusions from fewer than ~30 effective observations, and no t-statistics computed over trades
  (overlapping trades are not independent).
- No full-Kelly sizing and no realized max drawdown used as a risk budget.
- "No significant edge" is an acceptable, reportable outcome.

## Step 0 — Pre-register (before any result exists)
Write `research/<name>/PREREG.md` and commit it. Later changes go in an `## Amendments` list with a date and
reason, and each one adds to N.
- Hypothesis and the economic reason it should work (who loses money to you, and why they keep doing it).
- Universe and its point-in-time source; period; bar frequency.
- Signal definition, decision time, and execution rule (default: decide on bar t's close, fill at t+1 open).
- Cost model: commission, half-spread, slippage or impact, borrow fee, financing.
- The finite parameter grid you will search.
- Validation design and the sealed holdout window.
- Pass gates: PSR(0) ≥ 0.95, DSR ≥ 0.95, PBO ≤ 0.05, still profitable at 2× costs, same sign in both halves of
  the sample, and t ≥ 3 if this is a new factor (Harvey, Liu & Zhu 2016).

## Step 1 — Point-in-time data (see `market-data.md`, `sec-edgar.md`)
- Universe as of each date, including delisted, bankrupt, and acquired names. Apply actual delisting returns;
  never drop them.
- Raw prices plus a corporate-actions table; adjust as-of with `scripts/adjust.py`. Filters such as price > $5 or
  dollar volume use raw values.
- Fundamentals keyed on filing time (`filed`, or acceptance time in ET), not period end. If you only have
  period-end stamps, lag them by at least 3 months (Luo et al. 2014) and say so.
- Macro data from ALFRED vintages (FRED default mode is revised history).
- Validate every pull: duplicate timestamps, gaps against the exchange calendar, stale repeated prices,
  zero or negative prices, jumps over 5× typical volatility without a corporate action, and currency units (GBp
  vs GBP is 100×). Keep missing bar, zero volume, halt, and holiday distinct.

## Step 2 — Engine semantics
Write a timeline table: for each input, when it becomes known and when it is first used. Then set every default
explicitly, because library defaults are optimistic:

| Library | Default fill | Default costs | Fix |
|---|---|---|---|
| vectorbt `Portfolio.from_signals` | `price=np.inf` = **same bar's close** | `fees=0`, `slippage=0` | shift entries/exits one bar (`.vbt.fshift(1)`) or pass next-bar open; set `fees`/`slippage` |
| backtrader | next bar's open | broker commission 0 unless set | keep `coc`/`coo` off; set commission and slippage |
| QuantConnect LEAN | per fill model | `NullSlippageModel` (zero slippage); fee model from the brokerage model | set a slippage model |
| zipline-reloaded | next bar | `FixedBasisPointsSlippage(5 bps, 10% volume)`, `PerShare($0.001)` | override for your venue |

Status: backtrader's last push was 2024-08 (GPL-3.0, effectively unmaintained); zipline-reloaded is in light
maintenance; vectorbt (Apache-2.0 with Commons Clause), LEAN, nautilus_trader, and bt are active (checked
2026-10-08).

Also model: shorting availability and borrow cost; a participation cap (for example ≤ 5–10% of ADV); position
and leverage limits; what happens when a stop and a target both trigger inside one bar; cash drag; dividends
paid on shorts.

## Step 3 — Trial ledger
Save the per-period returns of every variant you run, including abandoned ones, as columns of one CSV on a
shared date index (`research/<name>/trials.csv`), plus a `trials.jsonl` line per run (config hash, data window,
date, commit). Never delete a row. N and the dispersion of trial Sharpe ratios feed the deflation in Step 5.

## Step 4 — Validation design
- **Walk-forward:** fit only on the past and re-run parameter or region selection inside each fold. It is one
  path and easy to overfit (López de Prado 2018).
- **ML with overlapping labels:** purged k-fold with an embargo of h ≈ 0.01·T bars. Purge training rows whose
  label interval overlaps any test label; embargo rows right after the test fold. Never shuffle.
- **CPCV:** N groups, k test groups: C(N, k) splits and φ = (k/N)·C(N, k) backtest paths (N = 6, k = 2 → 15
  splits, 5 paths). Report the distribution of OOS Sharpe ratios, not one path.
- **PBO (CSCV):** on the T×N trial matrix with S = 16 blocks (C(16,8) = 12,870 splits). Use T about twice the
  sample you selected on; reject if PBO > 0.05. Never optimize on PBO.
- **Parameter choice:** map the whole grid and choose a plateau (a region whose neighbours are also good), not
  the peak. Report the region.
- **Holdout:** sealed until the end, opened once. A holdout under ~1,000 observations is weak evidence.

## Step 5 — Statistics (run the script; quote its output)
```bash
uv run --no-project --with numpy python3 ~/.claude/skills/finance/scripts/bt_report.py \
  --returns research/<name>/selected.csv --column ret --date-column date \
  --periods-per-year 252 --trials research/<name>/trials.csv --target-sr 0.5
```
`selected.csv` holds the chosen variant's per-period net returns. Without a trial matrix, pass
`--n-trials N --trials-sr-var V` (V = variance of the trials' per-period Sharpe ratios).

How to read it:
- Sharpe for PSR, DSR, and MinTRL is **per period** with **raw** kurtosis. pandas `.kurt()` and scipy
  `kurtosis()` return excess kurtosis by default, so add 3 if you compute these yourself.
- PSR(0) ≥ 0.95 means SR > 0 at 95% confidence after skew and fat tails. MinTRL is the number of observations
  needed for that.
- DSR deflates for the number of effective independent trials N̂ = ρ̄ + (1 − ρ̄)·M. Hiding trials inflates it.
- MinBTL ≈ (E[max of N] / SR)², bounded by 2·ln N / SR² years: five years of data supports at most about 45
  independent configurations at an annual Sharpe of 1 (Bailey et al. 2014).
- Haircut Sharpe (Harvey & Liu 2015) is non-linear: large for SR < 0.4, at most about 25% for SR > 1.
- Annualizing by √q overstates Sharpe when returns are positively autocorrelated (by up to 65% for smoothed
  hedge-fund returns, Lo 2002). The script prints an AR(1)-corrected figure.

## Step 6 — Robustness probes (report every one, pass or fail)
Costs ×2 · execution one bar later · each parameter ±20% · first half vs second half · each calendar year left
out · without the 5 best days or trades · a random-entry or sign-flip null distribution · capacity at your
participation cap · a different but comparable universe.

## Step 7 — Report
```markdown
# <Strategy> — backtest report (<EXPLORATORY | CONFIRMATORY>), <date>
**Claim:** <one sentence> · **Pre-registration:** <path@commit>, amendments: <n>
**Data:** <sources, pull dates, PIT handling, delisted names included?> · **Period / frequency:** <...>
**Execution and costs:** <fill rule, commission, spread, slippage, borrow, participation cap>
**Trials:** M = <..>, effective N = <..>, how counted: <...>
| Metric | Strategy | Benchmark (total return) |
|---|---|---|
| CAGR / volatility | | |
| Sharpe per period / annualized / AR(1)-corrected | | |
| PSR(0) · DSR · PBO · MinTRL | | n/a |
| Max drawdown (dates) · ES 97.5% | | |
| Turnover · average holding period · exposure | | |
**Robustness:** <table: probe → result>
**What would falsify this:** <...>
**Reproduce:** `<commands>` · commit <sha> · data <path/hash> · `uv.lock`
_Educational analysis, not investment advice._
```

## Before calling it done
- [ ] PREREG committed before results; amendments logged and counted in N.
- [ ] Timeline table shows no input used before it was known; fills at t+1 or later.
- [ ] Costs, slippage, and borrow set explicitly and stated in the report.
- [ ] Universe includes delisted names; prices adjusted as-of; benchmark is total return.
- [ ] `bt_report.py` run on the final selection with the full trial ledger; figures quoted from its output.
- [ ] Every Step 6 probe reported.
- [ ] `backtest-auditor` reviewed it, and its findings are fixed or listed as known issues.

## Sources
Bailey & López de Prado 2012 (PSR, MinTRL), 2014 (DSR) · Bailey, Borwein, López de Prado & Zhu 2014 (MinBTL,
Notices AMS), 2017 (PBO/CSCV, J. Comp. Finance) · López de Prado 2018 (AFML; "10 Reasons Most ML Funds Fail",
JPM) · Harvey, Liu & Zhu 2016 (RFS) · Harvey & Liu 2015 ("Backtesting", JPM) · Lo 2002 (FAJ) · Luo et al. 2014
("Seven Sins of Quantitative Investing", Deutsche Bank) · McLean & Pontiff 2016 (post-publication decay: −26%
OOS, −58% post-publication) · Novy-Marx & Velikov 2016 (costs; turnover above 50%/month rarely survives).
