# SEC EDGAR

Verified 2026-10-08 against sec.gov docs and live responses for AAPL.

## Setup
- No API key. Every request needs a declared User-Agent with a real name and contact email, or EDGAR answers
  HTTP 403 "Undeclared Automated Tool". Put it in `SEC_USER_AGENT` (for example `Jane Doe jane@example.org`);
  never hard-code it.
- Limit: 10 requests/second per user across all machines. Over the limit, EDGAR blocks the IP until you have
  stayed under the threshold for 10 minutes. Stop on a throttling 403/429; don't retry in a loop.
- data.sec.gov has no CORS, so call it from a backend or script, not a browser.
- Prefer bulk files for many companies: `companyfacts.zip` and `submissions.zip` are rebuilt nightly.

## Quick use (bundled script, stdlib only)
```bash
S=~/.claude/skills/finance/scripts/edgar_facts.py
python3 $S --ticker AAPL --list-tags revenue                         # discover tags
python3 $S --ticker AAPL --span 3M --derive-q4 \
  --tag RevenueFromContractWithCustomerExcludingAssessedTax,Revenues,SalesRevenueNet   # quarterly, first-reported
python3 $S --ticker AAPL --tag Assets --span instant --mode asof --asof 2024-01-02     # known before that date
python3 $S --cik 320193 --tag EarningsPerShareDiluted --unit USD/shares --span 12M --format json
```
Output columns: tag, start, end, span, val, filed, form, fy, fp, accn, frame. The last stderr line is
`RESULT: …`. Values are in full units (dollars, not thousands).

## Endpoints
| Purpose | URL |
|---|---|
| Ticker → CIK | `https://www.sec.gov/files/company_tickers_exchange.json` (fields `cik, name, ticker, exchange`; CIK is an int, pad to 10 digits) |
| Filing history | `https://data.sec.gov/submissions/CIK##########.json` (columnar `filings.recent`; older pages in `filings.files[]`) |
| All facts for a company | `https://data.sec.gov/api/xbrl/companyfacts/CIK##########.json` |
| One tag for a company | `https://data.sec.gov/api/xbrl/companyconcept/CIK##########/us-gaap/<Tag>.json` |
| One tag across companies | `https://data.sec.gov/api/xbrl/frames/us-gaap/<Tag>/USD/CY2024Q4I.json` |
| Filing index / header | `https://www.sec.gov/Archives/edgar/data/<cik>/<accession-no-dashes>/<accession>-index.htm` |
| Full-text search | `https://efts.sec.gov/LATEST/search-index?q="material weakness"&forms=10-K&dateRange=custom&startdt=…&enddt=…` |

## Fact semantics (the traps)
- **The same fact repeats across filings.** AAPL's FY2023 revenue (383,285,000,000) appears in the FY2023,
  FY2024, and FY2025 10-Ks. Dedupe on (start, end): first-reported = earliest `filed`; as-of = latest `filed`
  strictly before the decision date.
- **`fy`, `fp`, and `form` describe the filing, not the fact.** A Q2 10-Q holds both the 3-month and the 6-month
  year-to-date values, and a 10-K holds quarterly facts. Classify by `end − start` (3M/6M/9M/12M) or `instant`.
- **Fiscal Q4 is rarely a discrete fact.** Q4 = FY − 9M YTD with the same start, knowable only from the 10-K's
  `filed` date (`--derive-q4`; AAPL FY2023 Q4 = 89,498,000,000).
- **Frames return the latest restated value** and calendarize approximately (CY#### = 365 ± 30 days,
  CY####Q# = 91 ± 30, a trailing `I` = instant). Good for "as of today" cross-sections, look-ahead in backtests.
- **Instant vs duration.** Balance-sheet items and share counts are instants (no `start`).
- **Units.** `USD`, `shares`, `USD/shares`, `pure`; foreign filers report other currencies. Frame URLs write
  `USD-per-shares`.
- **Custom extension tags and segment/dimension detail are not in the JSON APIs.** Use the Financial Statement
  and Notes data sets or the filing's XBRL for those.
- **`dei` is sparse.** `EntityCommonStockSharesOutstanding` is dated near the filing (cover page), not period end.
- **Tags drift.** Revenue moved from `SalesRevenueNet`/`Revenues` to
  `RevenueFromContractWithCustomerExcludingAssessedTax` around ASC 606 (2018). Use fallback chains and record
  which tag supplied each value.
- **Timing.** Most filings accepted after 17:30 ET are dated the next business day (Forms 3/4/5 until 22:00); an 8-K accepted at 16:30 ET keeps
  that day's `filed` date but arrived after the close. Daily backtests: use facts with `filed < decision date`.
  Intraday: use `<ACCEPTANCE-DATETIME>` (ET) from `<accession>-index-headers.html`. The submissions JSON
  `acceptanceDateTime` ends in `Z` but was observed to equal ET wall-clock + 8h (EDT) / + 10h (EST), not UTC.

## Common us-gaap tags (verified present for AAPL)
| Item | Tag(s), fallback order |
|---|---|
| Revenue | `RevenueFromContractWithCustomerExcludingAssessedTax`, `Revenues`, `SalesRevenueNet` |
| Cost of revenue · gross profit | `CostOfGoodsAndServicesSold` (or `CostOfRevenue`) · `GrossProfit` |
| Operating income · net income | `OperatingIncomeLoss` · `NetIncomeLoss` |
| R&D · SG&A · interest · tax | `ResearchAndDevelopmentExpense` · `SellingGeneralAndAdministrativeExpense` · `InterestExpense` · `IncomeTaxExpenseBenefit` |
| Diluted EPS · diluted shares | `EarningsPerShareDiluted` (USD/shares) · `WeightedAverageNumberOfDilutedSharesOutstanding` (shares) |
| Cash · receivables · inventory · payables | `CashAndCashEquivalentsAtCarryingValue` · `AccountsReceivableNetCurrent` · `InventoryNet` · `AccountsPayableCurrent` |
| Assets · liabilities · equity | `Assets` · `Liabilities` · `StockholdersEquity` (check `LiabilitiesAndStockholdersEquity` = `Assets`) |
| Debt | `LongTermDebtCurrent`, `LongTermDebtNoncurrent`, `CommercialPaper` |
| Cash flow | `NetCashProvidedByUsedInOperatingActivities`, `PaymentsToAcquirePropertyPlantAndEquipment`, `ShareBasedCompensation`, `DepreciationDepletionAndAmortization`, `PaymentsForRepurchaseOfCommonStock`, `PaymentsOfDividends` |

Not every filer uses these. Run `--list-tags` first, and expect gaps for banks, insurers, REITs, and IFRS filers
(`ifrs-full` taxonomy).

## Bulk and research datasets
- **Financial Statement Data Sets** (quarterly, face financials only since a Dec 2024 reprocessing) and
  **Financial Statement and Notes** (monthly, includes notes, custom tags, and dimensions). Both are "as filed"
  and carry `filed` and `accepted`, so they work as point-in-time sources. NUM `ddate` is rounded to month-end.
- **EDGAR full-text search** covers filings since 2001, returns 100 hits per page, and stops at 10,000 results;
  slice queries by date range or form. Assume the same fair-access rules.
- **edgartools** (MIT, `dgunning/edgartools`) is a maintained Python library over the same APIs; set
  `EDGAR_IDENTITY` the same way.

## Before calling it done
- [ ] User-Agent declared via env; request rate under 10/s; no retry storm on 403.
- [ ] Facts deduplicated, classified by duration, and selected first-reported or as-of, with the choice stated.
- [ ] Each value cites accession, form, and `filed` date; the tag used is recorded.
- [ ] Two or three key figures tie to the filing document itself (open the `-index.htm` and check).
- [ ] Units and scale stated; currency checked for foreign filers.
