# Market and macro data

Facts below were verified on 2026-10-08 against vendor docs, source code, or live probes. Vendors change terms
often: re-check limits and endpoints before building on them, and cite the date you checked.

## Pick a source
| Need | Source | Free tier | Gotchas |
|---|---|---|---|
| US fundamentals, filings, share counts | SEC EDGAR (`sec-edgar.md`) | no key; 10 req/s; declared User-Agent | facts repeat across filings; key on `filed` |
| Macro series | FRED API / ALFRED | key; 120 req/min | default returns **revised** history; observation `date` is the period **start**; `SP500` is price-only, ~10 years; ICE BofA series capped at 3 years from Apr 2026 |
| Daily prices for exploration | yfinance 1.7.0 (unofficial) | no key; undocumented throttling | `auto_adjust=True` by default (no `Adj Close`); `Close` is split-adjusted even with `auto_adjust=False`; `end` exclusive; delisted tickers vanish; personal use only |
| Daily/intraday US equities | Massive (Polygon.io renamed 2025-10-30; `api.massive.com`) | 5 calls/min, 2 years, EOD | `adjusted=true` is splits only; bars stamped at window start; no bar when nothing traded |
| EOD with raw + adjusted + actions in one call | Tiingo | 50/hour, 1,000/day, 500 symbols/month | values can change until ~8 PM ET; IEX intraday volume is a sliver of the market |
| Bars incl. full-volume SIP history | Alpaca Market Data | 200 calls/min; SIP history if `end` ≥ 15 min old | `adjustment=raw` default; IEX feed ≈ 2% of volume; `asof` remaps renamed tickers |
| Quick checks | Alpha Vantage | 25 requests/day | adjusted daily and full history are premium; throttling has historically come back as HTTP 200 with a `Note` key |
| Fundamentals API | FMP | 250 calls/day, 5 years | `/api/v3` legacy endpoints return 403 for keys after 2025-08-31; use `/stable/` |
| PIT fundamentals with delisted names | Sharadar (Nasdaq Data Link) | paid | use AR* dimensions (`datekey` = filing date); MR* is restated (look-ahead) |
| Survivorship-free prices and index membership | Norgate (Platinum/Diamond), CRSP via WRDS, QuantConnect datasets | paid / institutional | see the end of this file |

Dead or changed: IEX Cloud shut down 2024-08-31; Quandl WIKI prices discontinued in 2018; Stooq now needs an
API key behind a browser check (don't bypass it); pandas-datareader 0.11 removed its Yahoo, Stooq, IEX, Tiingo,
and Quandl readers; OpenBB moved to the `openbq-org` org in Sept 2026 (verify provenance and pin).

## Store raw, derive adjusted
Persist three tables and derive everything else:
- `prices_raw(symbol_id, session_date, open, high, low, close, volume, vendor, pulled_at)` — as traded.
- `corporate_actions(symbol_id, ex_date, kind, split_ratio, cash_amount, currency, source, pulled_at)`.
- `security_master(symbol_id, ticker, valid_from, valid_to, cik, figi, exchange, delisted_on)` — tickers are
  recycled and renamed; key on a stable id (FIGI, CIK + share class, vendor permanent id), never the ticker.

Back-adjust with the bundled script. `--asof` reproduces the adjusted series as it looked on that date, which
is the only adjusted series a backtest decision on that date may use:
```bash
python3 ~/.claude/skills/finance/scripts/adjust.py --input raw.csv --output adj.csv [--asof 2024-06-28]
# raw.csv columns: date, close, dividend (ex-date, post-split units), split (new/old), volume (optional)
```
It applies split factor 1/ratio and dividend factor 1 − D / (previous close in post-split units) to all
earlier rows (CRSP/Yahoo method) and writes the exact total return (close + D) / previous close − 1.
Verified against Yahoo's worked example (46.99 × 0.5 × 0.9968 = 23.42) and a same-day split plus dividend.

Rules:
- Returns come from total-return math or adjusted closes; level-based filters (price floors, dollar volume,
  round numbers, 52-week highs, share counts for sizing) come from raw values.
- Benchmarks match the return basis: a dividend-reinvesting strategy against a price index overstates alpha by
  about the dividend yield.
- yfinance has no raw close. If you must use it, request `auto_adjust=False, actions=True` and undo future splits.

```python
import yfinance as yf
px = yf.download("AAPL", start="2015-01-01", end="2026-01-01",  # end is exclusive
                 auto_adjust=False, actions=True, repair=True,  # repair needs `yfinance[repair]` (scipy)
                 multi_level_index=False, progress=False)
split = px["Stock Splits"].replace(0.0, 1.0)
px["Close_raw"] = px["Close"] * split[::-1].cumprod()[::-1].shift(-1, fill_value=1.0)
```

## Time and calendars
- Session date = the exchange-local date. Convert to America/New_York, then take the date; never take the
  date of a UTC timestamp (after 20:00 EDT it is already tomorrow in UTC).
- Bars labelled by start (Massive, Alpaca) are known at their end. pandas `resample` defaults to
  `label="left"`, `closed="left"` except for `ME`, `QE`, `YE`, and `W` (right). Use `label="right"` when you
  need the time a bar became known.
- Naive timestamps: `tz_localize("UTC").tz_convert("America/New_York")`. `tz_localize("America/New_York")` on
  UTC wall-clock values silently shifts data by 4–5 hours.
- NYSE: 09:30–16:00 ET; early closes at 13:00 ET (Jul 3, the day after Thanksgiving, and Dec 24 under the
  usual rules); ad-hoc closures happen (2025-01-09). The open is 13:30 UTC in summer and 14:30 UTC in winter;
  US and EU DST switch on different dates for ~3 weeks in March and ~1 week around Oct/Nov.
```python
import exchange_calendars as xcals
nyse = xcals.get_calendar("XNYS", start="1990-01-01")   # default window is only ~20 years back
sessions = nyse.sessions_in_range("2025-01-01", "2025-12-31")
assert not nyse.is_session("2025-01-09")
```
`pandas_market_calendars` wraps the same data; its `valid_days()` returns tz-aware UTC by default.

## Macro without look-ahead (FRED/ALFRED)
```python
import os
import pandas as pd
import requests

def fred_obs(series_id: str, **params) -> pd.DataFrame:
    p = {"series_id": series_id, "api_key": os.environ["FRED_API_KEY"], "file_type": "json", **params}
    r = requests.get("https://api.stlouisfed.org/fred/series/observations", params=p, timeout=30)
    r.raise_for_status()                              # 429 means more than 120 requests per minute
    df = pd.DataFrame(r.json()["observations"])
    df["value"] = pd.to_numeric(df["value"], errors="coerce")   # missing is "."
    return df                                         # keep realtime_* as strings: 9999-12-31 overflows datetime64[ns]

as_known = fred_obs("PAYEMS", realtime_start="2020-04-03", realtime_end="2020-04-03")
first_release = fred_obs("PAYEMS", realtime_start="1776-07-04", realtime_end="9999-12-31", output_type=4)
```
Lag features by release time (`realtime_start`), not by the observation date. Vintages exist only from when
ALFRED archived them; before that, document the proxy you used.

## Validate every pull
Duplicated (symbol, session) keys · sessions missing against the calendar · non-positive prices · OHLC
inconsistencies (high < max(open, close)) · jumps beyond ~5× recent volatility with no corporate action ·
repeated identical closes (stale data) · split-like jumps near integer ratios with no split recorded · currency
scale (GBp/GBP, ZAc/ZAR are 100×) · volume in shares vs lots · timezone of the stamp. Cross-check a sample of
closes against a second vendor and record the differences.

## Survivorship-free options for an individual
- Norgate Data: Platinum (from 1990) and Diamond (from 1950) include delisted securities and historical index
  constituents; 6- or 12-month subscriptions; Windows updater.
- Sharadar via Nasdaq Data Link: delisted companies kept; recycled tickers get suffixes (GM1).
- CRSP via WRDS: the academic standard (Morningstar acquired CRSP in Feb 2026; individual access unclear).
- QuantConnect: AlgoSeek US equities since 1998 including delisted names, usable in cloud backtests.
- Free lists of delisted tickers only: Alpha Vantage `LISTING_STATUS` (since 2010), Massive
  `/v3/reference/tickers?active=false&date=…` (2 years on the free tier).

## Before calling it done
- [ ] Source, endpoint, pull date, and adjustment basis recorded for every series.
- [ ] Raw and actions stored; adjusted series derived as-of; benchmark on the same return basis.
- [ ] Session dates exchange-local; calendar applied; bar-label convention handled.
- [ ] Validation checks run and their counts reported.
- [ ] Vendor terms allow the intended use (no redistribution of personal-use data).
