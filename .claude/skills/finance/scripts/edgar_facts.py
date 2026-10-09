#!/usr/bin/env python3
"""Point-in-time XBRL facts from SEC EDGAR (stdlib only, Python 3.10+).

Fetches data.sec.gov companyfacts for a ticker or CIK and prints one row per economic
period for a tag, deduplicated either as FIRST reported (what the market saw) or as
KNOWN AS OF a decision date (latest value filed strictly before that date).

SEC fair-access rules: declare a User-Agent with a real name and contact email via the
SEC_USER_AGENT env var (e.g. "Jane Doe Research jane@example.org"); stay under 10
requests/second per user across all processes. Undeclared clients get HTTP 403.

Examples:
  SEC_USER_AGENT="Jane Doe jane@example.org" python3 edgar_facts.py --ticker AAPL \
      --tag RevenueFromContractWithCustomerExcludingAssessedTax,Revenues,SalesRevenueNet --span 3M --derive-q4
  python3 edgar_facts.py --facts-file aapl_companyfacts.json --tag Assets --span instant \
      --mode asof --asof 2024-01-01
  python3 edgar_facts.py --facts-file aapl_companyfacts.json --list-tags revenue
"""
from __future__ import annotations

import argparse
import csv
import gzip
import json
import os
import random
import sys
import threading
import time
import urllib.error
import urllib.request
import zlib
from dataclasses import asdict, dataclass
from datetime import date

TICKERS_URL = "https://www.sec.gov/files/company_tickers_exchange.json"
FACTS_URL = "https://data.sec.gov/api/xbrl/companyfacts/CIK{cik10}.json"

# Duration buckets in days; ranges tolerate 52/53-week fiscal years.
SPANS = (("3M", 80, 100), ("6M", 170, 190), ("9M", 260, 285), ("12M", 350, 380))


class MinIntervalLimiter:
    """At most `rate` calls/s in this process. The SEC cap (10/s) is per user across all
    machines, so split the budget if several processes fetch concurrently."""

    def __init__(self, rate: float = 8.0) -> None:
        self._interval = 1.0 / rate
        self._lock = threading.Lock()
        self._next = time.monotonic()

    def wait(self) -> None:
        with self._lock:
            slot = max(time.monotonic(), self._next)
            self._next = slot + self._interval
        delay = slot - time.monotonic()
        if delay > 0:
            time.sleep(delay)


_LIMITER = MinIntervalLimiter()


def sec_get_json(url: str, max_tries: int = 4, timeout: float = 30.0) -> dict:
    user_agent = os.environ.get("SEC_USER_AGENT", "").strip()
    if "@" not in user_agent:
        raise SystemExit("ERROR: set SEC_USER_AGENT='Your Name your@email' (SEC requires a declared contact)")
    headers = {"User-Agent": user_agent, "Accept-Encoding": "gzip, deflate"}
    for attempt in range(1, max_tries + 1):
        _LIMITER.wait()
        request = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                body = response.read()
                encoding = response.headers.get("Content-Encoding", "")
        except urllib.error.HTTPError as err:
            text = err.read().decode("utf-8", "replace")
            if err.code == 403 and "Undeclared Automated Tool" in text:
                raise SystemExit("ERROR: SEC rejected the User-Agent; use a real name and email") from err
            if err.code in (403, 429):
                raise SystemExit(
                    "ERROR: SEC throttled this IP (HTTP %d). Stop all requests for 10 minutes, "
                    "then resume below 10 req/s." % err.code) from err
            if err.code in (500, 502, 503, 504) and attempt < max_tries:
                time.sleep(2 ** attempt + random.random())
                continue
            raise SystemExit("ERROR: HTTP %d for %s" % (err.code, url)) from err
        if encoding == "gzip":
            body = gzip.decompress(body)
        elif encoding == "deflate":
            body = zlib.decompress(body)
        return json.loads(body)
    raise SystemExit("ERROR: retries exhausted for %s" % url)


def load_json_file(path: str) -> dict:
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def normalize_ticker(ticker: str) -> str:
    return ticker.strip().upper().replace(".", "-")  # SEC uses BRK-B, not BRK.B or BRKB


def ticker_to_cik10(ticker: str, tickers_file: str | None) -> str:
    table = load_json_file(tickers_file) if tickers_file else sec_get_json(TICKERS_URL)
    fields = table["fields"]
    wanted = normalize_ticker(ticker)
    for row in table["data"]:
        record = dict(zip(fields, row))
        if str(record["ticker"]).upper() == wanted:
            return "%010d" % int(record["cik"])
    raise SystemExit("ERROR: ticker %s not in SEC map (current listings only; delisted names "
                     "are absent -- look the CIK up in EDGAR full-text search)" % wanted)


@dataclass
class Fact:
    tag: str
    start: str | None
    end: str
    span: str
    val: float
    filed: str
    form: str
    fy: int | None
    fp: str | None
    accn: str
    frame: str | None


def classify_span(start: str | None, end: str) -> str:
    if not start:
        return "instant"
    days = (date.fromisoformat(end) - date.fromisoformat(start)).days
    for label, low, high in SPANS:
        if low <= days <= high:
            return label
    return "other"


def extract_facts(companyfacts: dict, tags: list[str], taxonomy: str, unit: str) -> list[Fact]:
    """Rows for the first tag in `tags` that exists, plus later tags filling periods it lacks
    (tag drift, e.g. SalesRevenueNet -> RevenueFromContractWithCustomer... after ASC 606)."""
    by_taxonomy = companyfacts.get("facts", {}).get(taxonomy, {})
    rows: list[Fact] = []
    covered: set[tuple[str | None, str]] = set()
    for tag in tags:
        units = by_taxonomy.get(tag, {}).get("units", {})
        tag_rows = []
        for raw in units.get(unit, []):
            key = (raw.get("start"), raw["end"])
            if key in covered:
                continue
            tag_rows.append(Fact(
                tag=tag, start=raw.get("start"), end=raw["end"],
                span=classify_span(raw.get("start"), raw["end"]), val=raw["val"],
                filed=raw["filed"], form=raw.get("form", ""), fy=raw.get("fy"), fp=raw.get("fp"),
                accn=raw["accn"], frame=raw.get("frame")))
        covered.update((fact.start, fact.end) for fact in tag_rows)
        rows.extend(tag_rows)
    return rows


def first_reported(rows: list[Fact]) -> list[Fact]:
    """Earliest filing per (start, end): the value as first disclosed, ignoring restatements."""
    best: dict[tuple[str | None, str], Fact] = {}
    for fact in sorted(rows, key=lambda f: (f.filed, f.accn)):
        best.setdefault((fact.start, fact.end), fact)
    return sorted(best.values(), key=lambda f: (f.end, f.start or ""))


def known_as_of(rows: list[Fact], decision_date: str) -> list[Fact]:
    """Latest value filed STRICTLY before decision_date. `filed` has no time of day and
    after-close filings carry that day's date, so same-day facts are excluded."""
    best: dict[tuple[str | None, str], Fact] = {}
    for fact in sorted(rows, key=lambda f: (f.filed, f.accn)):
        if fact.filed < decision_date:
            best[(fact.start, fact.end)] = fact
    return sorted(best.values(), key=lambda f: (f.end, f.start or ""))


def derive_fiscal_q4(rows: list[Fact]) -> list[Fact]:
    """Fiscal Q4 is rarely tagged as a discrete fact: Q4 = FY (12M) - 9M YTD with the same
    start date. The derived value is knowable only from the 10-K's filing date."""
    nine_month = {f.start: f for f in rows if f.span == "9M"}
    derived = []
    for annual in (f for f in rows if f.span == "12M"):
        ytd = nine_month.get(annual.start)
        if ytd is None:
            continue
        q4_start = date.fromordinal(date.fromisoformat(ytd.end).toordinal() + 1).isoformat()
        derived.append(Fact(
            tag=annual.tag + "[FY-9M]", start=q4_start, end=annual.end, span="3M",
            val=annual.val - ytd.val, filed=max(annual.filed, ytd.filed), form=annual.form,
            fy=annual.fy, fp="Q4(derived)", accn=annual.accn, frame=None))
    return derived


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--ticker")
    source.add_argument("--cik", help="numeric CIK (zero-padding optional)")
    source.add_argument("--facts-file", help="local companyfacts JSON (offline/testing)")
    parser.add_argument("--tickers-file", help="local company_tickers_exchange.json")
    parser.add_argument("--tag", help="comma-separated fallback chain of XBRL tags")
    parser.add_argument("--taxonomy", default="us-gaap")
    parser.add_argument("--unit", default="USD", help="USD, shares, USD/shares, pure, ...")
    parser.add_argument("--span", default="all", choices=["all", "instant", "3M", "6M", "9M", "12M"])
    parser.add_argument("--mode", default="first", choices=["first", "asof", "all"])
    parser.add_argument("--asof", help="decision date YYYY-MM-DD for --mode asof")
    parser.add_argument("--derive-q4", action="store_true", help="add fiscal Q4 = FY - 9M YTD rows")
    parser.add_argument("--list-tags", metavar="SUBSTRING", help="list tags containing SUBSTRING and exit")
    parser.add_argument("--format", default="csv", choices=["csv", "json"])
    args = parser.parse_args(argv)

    if args.facts_file:
        companyfacts = load_json_file(args.facts_file)
    else:
        cik10 = "%010d" % int(args.cik) if args.cik else ticker_to_cik10(args.ticker, args.tickers_file)
        companyfacts = sec_get_json(FACTS_URL.format(cik10=cik10))

    if args.list_tags is not None:
        needle = args.list_tags.lower()
        for tag, body in sorted(companyfacts.get("facts", {}).get(args.taxonomy, {}).items()):
            if needle in tag.lower():
                print("%s\t%s\t%s" % (tag, ",".join(body.get("units", {})), body.get("label", "")))
        return 0
    if not args.tag:
        parser.error("--tag is required unless --list-tags is given")
    if args.mode == "asof" and not args.asof:
        parser.error("--mode asof needs --asof YYYY-MM-DD")

    rows = extract_facts(companyfacts, [t.strip() for t in args.tag.split(",") if t.strip()],
                         args.taxonomy, args.unit)
    if not rows:
        print("ERROR: no facts for tag(s) %s in unit %s; try --list-tags" % (args.tag, args.unit), file=sys.stderr)
        return 2
    if args.mode == "first":
        rows = first_reported(rows)
    elif args.mode == "asof":
        rows = known_as_of(rows, args.asof)
    if args.derive_q4:
        rows = sorted(rows + derive_fiscal_q4(rows), key=lambda f: (f.end, f.start or ""))
    if args.span != "all":
        rows = [f for f in rows if f.span == args.span]

    records = [asdict(f) for f in rows]
    if args.format == "json":
        json.dump(records, sys.stdout, indent=1)
        print()
    else:
        writer = csv.DictWriter(sys.stdout, fieldnames=list(Fact.__dataclass_fields__))
        writer.writeheader()
        writer.writerows(records)
    print("RESULT: %d rows (%s, mode=%s, entity=%s)" % (len(records), args.tag, args.mode,
          companyfacts.get("entityName", "?")), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
