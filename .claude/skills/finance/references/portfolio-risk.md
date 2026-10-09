# Portfolio performance and risk report

## Step 1 — Inputs
- Holdings or lots (quantity, cost basis, acquisition date), transactions, and external cash flows (deposits,
  withdrawals, fees, taxes withheld), with dates.
- Prices on a total-return basis and FX rates for one base currency (`market-data.md`). Name the risk-free
  series (e.g. FRED `DTB3`, converted per period as (1 + y)^(1/q) − 1) and a total-return benchmark that
  matches the mandate.
- Reconcile first: end-of-period positions from transactions must equal the broker statement, and cash must tie.
  Report breaks before computing anything.

## Step 2 — Returns
- **Time-weighted (TWR):** value the portfolio just before every external flow; sub-period return =
  V_before_flow(i) / V_after_flow(i−1) − 1; chain-link Π(1 + r_i) − 1. Measures the strategy, independent of
  the timing of my deposits.
- **Money-weighted (MWR):** the IRR of dated flows (XIRR), with the starting value as an outflow and the ending
  value as an inflow. Measures my experience, including timing.
- **Modified Dietz** (approximation when only period-end values exist):
  (V1 − V0 − ΣCF) / (V0 + Σ w_i·CF_i), with w_i = fraction of the period remaining after flow i.
- State gross or net of fees and taxes. Annualize only periods longer than a year:
  (1 + R)^(1/years) − 1.

## Step 3 — Risk metrics (definitions printed with the table)
Run the bundled script on the daily or monthly TWR series for the return-series statistics:
```bash
uv run --no-project --with numpy python3 ~/.claude/skills/finance/scripts/bt_report.py \
  --returns twr.csv --column ret --date-column date --periods-per-year 252
```
Then add the benchmark-relative and holdings-based metrics:
| Metric | Definition |
|---|---|
| Volatility | stdev of periodic returns × √q (only if returns are not autocorrelated; otherwise say so) |
| Sharpe · Sortino | mean excess return ÷ stdev · mean excess over target ÷ RMS of min(0, r − target) over all periods |
| Max drawdown | worst peak-to-trough of compounded value; report peak, trough, recovery dates, and duration |
| VaR · ES | historical, at 95% and 97.5%, as positive losses for a stated horizon; √h horizon scaling assumes IID returns |
| Beta · correlation | cov(excess r_p, excess r_b) ÷ var(excess r_b), with a confidence interval; rolling 36-month view |
| Tracking error · IR | stdev(r_p − r_b) × √q · annualized active return ÷ tracking error |
| Capture ratios | compounded portfolio return ÷ compounded benchmark return over the benchmark's up (down) periods |
| Concentration | top-10 weight; HHI = Σw²; effective number of holdings = 1 / Σw² |
| Exposure | by asset class, sector, country, currency, and factor; gross and net leverage |
| Liquidity | days to exit each position at 10–20% of 30-day ADV (state the participation rate) |

Compare drawdowns and Calmar only over equal horizons and sampling frequencies.

## Step 4 — Attribution
- **Brinson-Fachler (single period, by sector or asset class):** allocation = (w_p − w_b)(R_b,i − R_b);
  selection = w_b·(R_p,i − R_b,i); interaction = (w_p − w_b)(R_p,i − R_b,i). Effects sum to R_p − R_b. Linking
  across periods needs a smoothing method (Carino or Menchero); name it.
- **Factor attribution:** regress excess returns on factor returns (e.g. Fama-French five factors plus momentum
  from the Ken French Data Library) with Newey-West standard errors. Report loadings, alpha with its t-stat,
  and R². Treat alpha with t < 3 as unproven (Harvey, Liu & Zhu 2016).

## Step 5 — Stress tests and forward-looking risk
- Historical windows: replay asset or factor returns from named episodes (2008-09 to 2009-03, 2020-02-19 to
  2020-03-23, 2022 rate shock) on current weights.
- Hypothetical shocks: equities −20%, rates +100 bp, USD +10%, credit spreads +200 bp; state the mapping used.
- Simulations: block bootstrap of historical returns (keeps fat tails and volatility clustering) rather than
  IID normal draws; report percentiles of terminal value and drawdown. A simulation is not a forecast.

## Step 6 — Report
```markdown
# Portfolio report — <period>, base currency <..>, as of <date>
**Reconciliation:** positions and cash tie to <statement> (breaks: <..>)
**Returns:** TWR <..>, MWR <..>, benchmark <name, total return> <..>; gross/net of fees
**Risk:** table from Step 3 with definitions; rolling charts if useful
**Attribution:** Brinson-Fachler table; factor regression
**Concentration, liquidity, exposures:** <..>
**Stress tests:** scenario → P&L
**Observations:** factual, no trade instructions; rebalancing drift vs target if a target exists
_Educational analysis, not investment advice._
```

## Before calling it done
- [ ] Positions and cash reconcile to the source statement.
- [ ] TWR and MWR both shown and labeled; fees and taxes basis stated.
- [ ] Benchmark is total return and matches the mandate; risk-free series named.
- [ ] Metric definitions printed; VaR/ES horizon and sign convention stated.
- [ ] No buy/sell instructions; any rebalancing note is descriptive.
