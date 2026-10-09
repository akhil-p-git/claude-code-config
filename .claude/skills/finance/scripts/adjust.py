#!/usr/bin/env python3
"""Back-adjust RAW daily prices from a corporate-actions table, optionally as known on a date.

Input CSV (ascending by date, one row per session) with columns:
  date      ISO date of the session
  close     unadjusted (as-traded) close
  dividend  cash dividend whose EX-date is this row, in post-split units (0 if none)
  split     split ratio new/old effective on this ex-date (2 = 2-for-1, 0.2 = 1-for-5; 1 if none)
  volume    optional unadjusted volume

Output CSV adds: factor (multiplier applied to this row), adj_close, adj_volume, and
total_return (exact: (close + dividend) / (previous close restated to post-split units) - 1).

Method (CRSP/Yahoo multiplicative back-adjustment): for each event on ex-date E, multiply every
row BEFORE E by 1/split and by 1 - dividend / (previous close restated to post-split units).
With --asof D only events with ex-date <= D are applied, which reproduces the adjusted series
as a vendor would have shown it on D -- the only adjusted series a backtest at D may use.

  python3 adjust.py --input raw.csv --output adj.csv [--asof 2024-06-30]
"""
from __future__ import annotations

import argparse
import csv
import sys


def back_adjust(rows: list[dict], asof: str | None = None) -> list[dict]:
    closes = [float(r["close"]) for r in rows]
    n = len(rows)
    event_factor = [1.0] * n  # factor contributed by the event on row i, applied to rows < i
    split_only = [1.0] * n
    for i in range(1, n):
        if asof is not None and rows[i]["date"] > asof:
            continue
        split = float(rows[i].get("split") or 1.0)
        dividend = float(rows[i].get("dividend") or 0.0)
        if split <= 0:
            raise SystemExit("ERROR: non-positive split ratio on %s" % rows[i]["date"])
        prev_close_post_split = closes[i - 1] / split
        div_factor = 1.0 - dividend / prev_close_post_split
        if not 0.0 < div_factor <= 1.0:
            raise SystemExit("ERROR: dividend %.4f >= previous close on %s" % (dividend, rows[i]["date"]))
        event_factor[i] = div_factor / split
        split_only[i] = 1.0 / split

    out: list[dict] = []
    factor_after = 1.0  # product of event factors strictly after row i
    split_after = 1.0
    for i in range(n - 1, -1, -1):
        row = dict(rows[i])
        row["factor"] = "%.10f" % factor_after
        row["adj_close"] = "%.6f" % (closes[i] * factor_after)
        if row.get("volume") not in (None, ""):
            row["adj_volume"] = "%.2f" % (float(row["volume"]) / split_after)
        out.append(row)
        factor_after *= event_factor[i]
        split_after *= split_only[i]
    out.reverse()

    for i in range(n):
        if i == 0:
            out[i]["total_return"] = ""
            continue
        split = float(rows[i].get("split") or 1.0)
        dividend = float(rows[i].get("dividend") or 0.0)
        out[i]["total_return"] = "%.10f" % ((closes[i] + dividend) / (closes[i - 1] / split) - 1.0)
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--asof", help="apply only events with ex-date <= this ISO date")
    args = parser.parse_args(argv)
    with open(args.input, newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        print("ERROR: empty input", file=sys.stderr)
        return 2
    dates = [r["date"] for r in rows]
    if dates != sorted(dates) or len(set(dates)) != len(dates):
        print("ERROR: dates must be strictly ascending and unique", file=sys.stderr)
        return 2
    out = back_adjust(rows, args.asof)
    with open(args.output, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(out[0].keys()))
        writer.writeheader()
        writer.writerows(out)
    events = sum(1 for r in rows if float(r.get("split") or 1) != 1 or float(r.get("dividend") or 0) != 0)
    print("RESULT: %d rows, %d corporate-action rows, asof=%s -> %s" % (len(out), events, args.asof or "all", args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
