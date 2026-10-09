#!/usr/bin/env python3
"""Backtest statistics report from a returns CSV (numpy + stdlib; formulas in bt_stats.py).

Input: a CSV with one row per period and a column of SIMPLE per-period strategy returns, net
of costs (e.g. 0.0012 = +0.12%). Optionally a T x N CSV holding the returns of EVERY variant
tried (one column per trial, same rows) for deflation and PBO.

  uv run --with numpy python3 bt_report.py --returns rets.csv --column ret --date-column date \
      --periods-per-year 252 --trials trials.csv --target-sr 1.0

Sharpe ratios are computed per period (native frequency) for PSR/DSR/MinTRL, with RAW kurtosis
(Normal = 3). Annualized figures are for display only. The last stdout lines are RESULT:/NEXT:.
Exit codes: 0 = report produced; 2 = bad input.
"""
from __future__ import annotations

import argparse
import csv
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bt_stats as bs  # noqa: E402


def read_columns(path: str, columns: list[str] | None) -> tuple[list[str], np.ndarray, list[str]]:
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        header = reader.fieldnames or []
    if not rows:
        raise SystemExit("ERROR: %s has no rows" % path)
    names = columns or [c for c in header if c and _is_numeric_column(rows, c)]
    missing = [c for c in names if c not in header]
    if missing:
        raise SystemExit("ERROR: columns %s not in %s (have %s)" % (missing, path, header))
    try:
        matrix = np.array([[float(r[c]) for c in names] for r in rows], dtype=float)
    except ValueError as err:
        raise SystemExit("ERROR: non-numeric or empty value in %s: %s" % (path, err)) from err
    return names, matrix, rows


def _is_numeric_column(rows: list[dict], column: str) -> bool:
    try:
        float(rows[0][column])
        return True
    except (TypeError, ValueError):
        return False


def moments(r: np.ndarray) -> tuple[float, float, float, float]:
    mean, std = r.mean(), r.std(ddof=1)
    centered = r - mean
    m2 = np.mean(centered**2)
    skew = float(np.mean(centered**3) / m2**1.5)
    raw_kurt = float(np.mean(centered**4) / m2**2)  # Pearson: Normal = 3
    return float(mean), float(std), skew, raw_kurt


def max_drawdown(r: np.ndarray) -> tuple[float, int, int]:
    equity = np.cumprod(1.0 + r)
    peaks = np.maximum.accumulate(np.concatenate([[1.0], equity]))[1:]
    drawdowns = equity / peaks - 1.0
    trough = int(np.argmin(drawdowns))
    peak = int(np.argmax(equity[: trough + 1])) if trough > 0 else 0
    if equity[peak] < 1.0:  # drawdown measured from the starting capital
        peak = -1
    return float(drawdowns[trough]), peak, trough


def expected_shortfall(r: np.ndarray, level: float) -> tuple[float, float]:
    """Historical VaR and ES at `level` (e.g. 0.975), reported as positive losses."""
    cutoff = np.quantile(r, 1.0 - level)
    tail = r[r <= cutoff]
    return float(-cutoff), float(-tail.mean())


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--returns", required=True)
    parser.add_argument("--column", help="return column (default: first numeric column)")
    parser.add_argument("--date-column")
    parser.add_argument("--periods-per-year", type=float, required=True, help="252 daily, 52 weekly, 12 monthly")
    parser.add_argument("--rf", type=float, default=0.0, help="per-period risk-free rate (default 0)")
    parser.add_argument("--target-sr", type=float, default=0.0, help="annualized benchmark SR* for PSR/MinTRL")
    parser.add_argument("--trials", help="CSV of per-period returns, one column per variant tried")
    parser.add_argument("--n-trials", type=int, help="number of trials if no --trials file (deflation needs --trials-sr-var too)")
    parser.add_argument("--trials-sr-var", type=float, help="variance of per-period SRs across trials")
    parser.add_argument("--pbo-splits", type=int, default=16, help="CSCV S (even); 16 recommended")
    args = parser.parse_args(argv)

    _, matrix, rows = read_columns(args.returns, [args.column] if args.column else None)
    r = matrix[:, 0]
    q = args.periods_per_year
    T = len(r)
    if T < 30:
        print("ERROR: %d observations; PSR/DSR asymptotics need well over 30" % T, file=sys.stderr)
        return 2
    excess = r - args.rf
    mean, std, skew, kurt = moments(excess)
    if std == 0:
        print("ERROR: zero variance returns", file=sys.stderr)
        return 2
    sr = mean / std
    rho1 = float(np.corrcoef(excess[:-1], excess[1:])[0, 1])
    sr_star = args.target_sr / math.sqrt(q)
    psr0 = bs.psr(sr, 0.0, T, skew, kurt)
    psr_star = bs.psr(sr, sr_star, T, skew, kurt)
    min_trl = bs.min_trl(sr, sr_star, skew, kurt) if sr > sr_star else float("inf")
    cagr = float(np.prod(1.0 + r) ** (q / T) - 1.0)
    mdd, peak, trough = max_drawdown(r)
    var95, es975 = expected_shortfall(r, 0.95)[0], expected_shortfall(r, 0.975)[1]
    sortino = bs.sortino(r, args.rf)
    dates = [row[args.date_column] for row in rows] if args.date_column else None

    def when(index: int) -> str:
        if index < 0:
            return "start"
        return dates[index] if dates else "row %d" % index

    lines = [
        ("Observations (T)", "%d (%.2f years at %g/yr)" % (T, T / q, q)),
        ("Mean / period; arithmetic annual", "%.6f; %.2f%%" % (mean, 100 * mean * q)),
        ("CAGR (geometric)", "%.2f%%" % (100 * cagr)),
        ("Volatility (annualized)", "%.2f%%" % (100 * std * math.sqrt(q))),
        ("Sharpe per period; x sqrt(q)", "%.4f; %.2f" % (sr, sr * math.sqrt(q))),
        ("Lag-1 autocorrelation", "%.3f%s" % (rho1, "  <-- significant: sqrt(q) annualization is biased" if abs(rho1) > 2 / math.sqrt(T) else "")),
        ("Sharpe annualized, AR(1)-corrected (Lo 2002)", "%.2f" % (sr * bs.eta_q_ar1(int(round(q)), rho1)) if abs(rho1) < 0.99 else "n/a"),
        ("Skewness; raw kurtosis (Normal=3)", "%.2f; %.2f" % (skew, kurt)),
        ("SE of SR per period (non-normal, Mertens)", "%.4f" % bs.sr_se_mertens(sr, T, skew, kurt)),
        ("PSR(SR*=0)", "%.3f" % psr0),
        ("PSR(SR*=%.2f annual)" % args.target_sr, "%.3f" % psr_star),
        ("MinTRL at 95%% vs SR*=%.2f" % args.target_sr, ("%.0f obs = %.2f yrs" % (min_trl, min_trl / q)) if math.isfinite(min_trl) else "n/a (SR <= SR*)"),
        ("Sortino (TDD over all periods) x sqrt(q)", "%.2f" % (sortino * math.sqrt(q))),
        ("Max drawdown (compounded)", "%.2f%% (peak %s -> trough %s)" % (100 * mdd, when(peak), when(trough))),
        ("Calmar (CAGR/|MDD|; horizon-dependent)", "%.2f" % (cagr / abs(mdd)) if mdd < 0 else "n/a"),
        ("Historical VaR 95% / ES 97.5% (per period)", "%.2f%% / %.2f%%" % (100 * var95, 100 * es975)),
    ]

    verdicts = []
    n_eff = var_sr = None
    if args.trials:
        _, trials, _ = read_columns(args.trials, None)
        if trials.shape[0] != T:
            print("ERROR: trials has %d rows, returns has %d" % (trials.shape[0], T), file=sys.stderr)
            return 2
        M = trials.shape[1]
        trial_sr = (trials.mean(axis=0) - args.rf) / trials.std(axis=0, ddof=1)
        var_sr = float(np.var(trial_sr, ddof=1))
        n_eff, rho_bar = bs.effective_n(np.corrcoef(trials, rowvar=False)) if M > 1 else (1.0, 1.0)
        lines.append(("Trials M; avg corr; effective N", "%d; %.2f; %.1f" % (M, rho_bar, n_eff)))
        if M >= 2 and T >= 2 * args.pbo_splits and args.pbo_splits % 2 == 0:
            pbo, _, pairs = bs.cscv_pbo(trials, S=args.pbo_splits)
            p_oos_loss = float(np.mean(pairs[:, 1] < 0))
            lines.append(("PBO (CSCV, S=%d)" % args.pbo_splits, "%.3f  (P[OOS SR < 0] of IS-best = %.2f)" % (pbo, p_oos_loss)))
            verdicts.append(("PBO <= 0.05", pbo <= 0.05))
    elif args.n_trials:
        n_eff, var_sr = float(args.n_trials), args.trials_sr_var
    if n_eff is not None and n_eff >= 2:
        nn = max(int(round(n_eff)), 2)
        hsr, haircut, _, _ = bs.haircut_sr_independent(sr * math.sqrt(q), T, q, nn)
        lines.append(("Haircut SR (Harvey-Liu, %d indep. tests)" % nn, "%.2f (haircut %.0f%%)" % (hsr, 100 * haircut)))
        years_needed, _ = bs.min_btl_years(nn, max(sr * math.sqrt(q), 1e-9))
        lines.append(("MinBTL for N trials at this SR", "%.1f yrs (have %.1f)" % (years_needed, T / q)))
        verdicts.append(("track length >= MinBTL", T / q >= years_needed))
        if var_sr is not None:
            dsr, sr0 = bs.dsr(sr, T, skew, kurt, var_sr, nn)
            lines.append(("Deflated SR (E[max] SR0 per period)", "%.3f (SR0=%.4f, %.2f annual)" % (dsr, sr0, sr0 * math.sqrt(q))))
            verdicts.append(("DSR >= 0.95", dsr >= 0.95))
    else:
        lines.append(("Deflation", "NOT COMPUTED - pass --trials (preferred) or --n-trials + --trials-sr-var"))
    verdicts.append(("PSR(0) >= 0.95", psr0 >= 0.95))
    verdicts.append(("T >= MinTRL", T >= min_trl))

    width = max(len(k) for k, _ in lines)
    print("| Metric | Value |\n|---|---|")
    for key, value in lines:
        print("| %s | %s |" % (key.ljust(width), value))
    failed = [name for name, ok in verdicts if not ok]
    print("RESULT: %s" % ("all gates passed: " + ", ".join(n for n, _ in verdicts) if not failed
                          else "FAILED gates: " + ", ".join(failed)))
    if failed:
        print("NEXT: treat the edge as unproven; report the failed gates verbatim. Do not tune further on this sample.")
    elif not args.trials and not args.n_trials:
        print("NEXT: supply the trial ledger (--trials) before calling the result significant.")
    else:
        print("NEXT: run cost x2 / lag+1 / parameter +-20% / subperiod probes before trusting it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
