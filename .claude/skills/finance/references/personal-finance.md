# Personal-finance scenarios

My data is private: keep it local, never send it to hosted tools or MCP servers, and redact account numbers in
any output. Every deliverable starts with "Prepared for my own planning; not tax, legal, or investment advice —
confirm with a CPA or CFP before acting."

## Rules
- **Tax-year parameters are fetched, never remembered.** Brackets, standard deduction, contribution limits,
  capital-gains thresholds, and phase-outs change every year and with legislation. Pull them from IRS sources
  for the exact tax year and cite them (for tax year 2026: Rev. Proc. 2025-32, which includes the One Big
  Beautiful Bill Act amendments; contribution limits come from the IRS's annual notice). If you can't fetch
  them, stop and say which numbers are missing.
- Statutory, non-indexed thresholds still get a citation (e.g. the 3.8% net investment income tax starts at
  $200,000 single / $250,000 married filing jointly, IRC §1411).
- **Decimal for every money amount**, rounded to cents with an explicit mode; float is fine for return
  simulations, never for balances or taxes.
- **State nominal vs real.** Use one basis per table; convert with a cited or user-supplied inflation rate.
- **Marginal vs effective.** Show both. Ordinary brackets apply to taxable income after deductions; long-term
  gains and qualified dividends stack on top of ordinary income for their own brackets. State taxes are separate.
- **Scenarios, not answers.** Every projection is a table across at least three assumption sets plus a
  sensitivity to the one or two inputs that matter most.
- Missing personal inputs (income, balances, rates, ages, filing status, state) are asked for, not assumed.

## Building blocks
- **Loans:** monthly rate = APR / 12 for US mortgages; payment = L·r / (1 − (1 + r)^−n). APY = (1 + APR/n)^n − 1.
  Make the final payment clear the rounding residue.
```python
from decimal import Decimal, ROUND_HALF_UP
CENT = Decimal("0.01")

def monthly_payment(principal: Decimal, apr: Decimal, months: int) -> Decimal:
    rate = apr / 12
    return (principal * rate / (1 - (1 + rate) ** -months)).quantize(CENT, ROUND_HALF_UP)

def schedule(principal: Decimal, apr: Decimal, months: int):
    rate, payment, balance = apr / 12, monthly_payment(principal, apr, months), principal
    for month in range(1, months + 1):
        interest = (balance * rate).quantize(CENT, ROUND_HALF_UP)
        principal_paid = payment - interest if month < months else balance   # last payment clears rounding
        balance -= principal_paid
        yield month, interest + principal_paid, interest, principal_paid, balance
# $400,000 at 6.5% for 360 months -> 2,528.27/month; final payment 2,530.88; total interest 510,179.81
```
- **Debt payoff:** simulate month by month with minimum payments on all debts and the surplus to the target
  debt. Avalanche (highest APR first) minimizes interest; snowball (smallest balance first) is a behavioral
  choice. Show months to payoff and total interest for both.
- **Refinance:** break-even months = closing costs ÷ monthly payment saving, but compare total remaining cost
  over the expected holding period, including the reset of the amortization clock.
- **Rent vs buy:** compare total cost over the holding period: mortgage interest, property tax, insurance,
  maintenance (state the %), HOA, transaction costs on both ends, opportunity cost of the down payment, and
  price appreciation as a scenario variable, not a given.
- **Retirement projection:** contributions (with employer match rules), fees, account types, and inflation;
  withdrawals in real terms. Monte Carlo uses a block bootstrap of historical real returns, or a fat-tailed
  model, never IID normal by default; report the success rate, the 10th-percentile path, and the worst
  drawdown, and show sequence-of-returns risk by retiring into a bad decade. The "4% rule" (Bengen 1994) is a
  historical US heuristic, not a guarantee.
- **Roth vs traditional:** compare after-tax outcomes using today's marginal rate vs an estimated retirement
  marginal rate, as a sensitivity across retirement rates. Note RMD rules and state taxes as factors.
- **Tax lots and wash sales:** track lots with dates and basis; a loss is disallowed if substantially identical
  securities are bought within 30 days before or after the sale (IRS Publication 550).

## Output
```markdown
# <Question> — scenarios as of <date>
Prepared for my own planning; not tax, legal, or investment advice — confirm with a CPA or CFP before acting.
**Inputs:** table — value, source ([USER] or a cited IRS/agency URL with tax year), nominal or real
**Scenarios:** low / base / high table with the decision-relevant outputs
**Sensitivity:** the 1–2 inputs that move the answer most
**Assumptions and limits:** what this ignores (state taxes, AMT, benefits phase-outs, behavior)
```

## Before calling it done
- [ ] Every tax parameter cites an IRS source for the right tax year.
- [ ] Money in Decimal; amortization schedule ends at exactly zero.
- [ ] Nominal/real basis stated per table; inflation source given.
- [ ] At least three scenarios and one sensitivity; no single-number answer.
- [ ] Nothing personal sent to external services; account numbers redacted.
