"""Reference implementations of backtest-overfitting statistics (stdlib + numpy).

All Sharpe ratios are PER-PERIOD (native frequency, not annualized) unless stated.
Kurtosis g4 is RAW kurtosis (Normal = 3), NOT excess kurtosis.
"""
from math import sqrt, e, log, comb
from statistics import NormalDist
from itertools import combinations
import numpy as np

_N = NormalDist()
EULER_GAMMA = 0.5772156649015329


def sr_se_lo(sr, T):
    """Lo (2002) Eq. 9: SE of SR under IID-Normal returns."""
    return sqrt((1 + 0.5 * sr**2) / T)


def sr_se_mertens(sr, T, g3, g4):
    """Mertens (2002) via Bailey & Lopez de Prado (2012) Eq. 8 (n-1 = Bessel)."""
    return sqrt((1 - g3 * sr + (g4 - 1) / 4 * sr**2) / (T - 1))


def psr(sr, sr_star, T, g3=0.0, g4=3.0):
    """Probabilistic Sharpe Ratio, BLdP (2012) Eq. 11."""
    return _N.cdf((sr - sr_star) * sqrt(T - 1) / sqrt(1 - g3 * sr + (g4 - 1) / 4 * sr**2))


def min_trl(sr, sr_star, g3=0.0, g4=3.0, prob=0.95):
    """Minimum Track Record Length in OBSERVATIONS, BLdP (2012) Eq. 13."""
    return 1 + (1 - g3 * sr + (g4 - 1) / 4 * sr**2) * (_N.inv_cdf(prob) / (sr - sr_star))**2


def expected_max_z(n_trials):
    """E[max of N iid N(0,1)] approximation (BBLZ 2014 Prop. 1; BLdP 2014 Eq. 5)."""
    g = EULER_GAMMA
    return (1 - g) * _N.inv_cdf(1 - 1 / n_trials) + g * _N.inv_cdf(1 - 1 / (n_trials * e))


def dsr(sr, T, g3, g4, var_trials_sr, n_trials):
    """Deflated Sharpe Ratio, BLdP (2014) Eq. 2. var_trials_sr in the SAME frequency as sr."""
    sr0 = sqrt(var_trials_sr) * expected_max_z(n_trials)
    return psr(sr, sr0, T, g3, g4), sr0


def effective_n(corr_matrix):
    """BLdP (2014) Eqs. 8-9: N_hat = rho_bar + (1 - rho_bar) * M."""
    C = np.asarray(corr_matrix, dtype=float)
    M = C.shape[0]
    rho_bar = (C.sum() - M) / (M * (M - 1))
    return rho_bar + (1 - rho_bar) * M, rho_bar


def min_btl_years(n_trials, target_max_sr_annual=1.0):
    """BBLZ (2014) Theorem 2: MinBTL (years) and the 2 ln N / E[max]^2 upper bound."""
    return (expected_max_z(n_trials) / target_max_sr_annual)**2, 2 * log(n_trials) / target_max_sr_annual**2


def eta_q(q, rhos):
    """Lo (2002) Eq. 20: SR(q) = eta(q) * SR; rhos[k-1] = k-th autocorrelation, k=1..q-1."""
    return q / sqrt(q + 2 * sum((q - k) * rhos[k - 1] for k in range(1, q)))


def eta_q_ar1(q, rho):
    """Lo (2002) Eq. 22 (AR(1) returns)."""
    return sqrt(q) * (1 + 2 * rho / (1 - rho) * (1 - (1 - rho**q) / (q * (1 - rho))))**-0.5


def adjust_pvalues(p, method):
    """Bonferroni / Holm / BHY adjusted p-values as written in Harvey & Liu (2015)."""
    p = np.asarray(p, dtype=float)
    M = len(p)
    order = np.argsort(p)
    ps = p[order]
    adj = np.empty(M)
    if method == "bonferroni":
        adj = np.minimum(M * ps, 1.0)
    elif method == "holm":
        running = 0.0
        for i in range(M):  # i is 0-based; (M - j + 1) with 1-based j == M - j0
            running = max(running, (M - i) * ps[i])
            adj[i] = min(running, 1.0)
    elif method == "bhy":
        c = sum(1.0 / j for j in range(1, M + 1))
        adj[M - 1] = ps[M - 1]
        for i in range(M - 2, -1, -1):  # 1-based rank = i + 1
            adj[i] = min(adj[i + 1], M * c / (i + 1) * ps[i])
    else:
        raise ValueError(method)
    out = np.empty(M)
    out[order] = adj
    return out


def haircut_sr_independent(sr_annual, T, periods_per_year, n_tests):
    """Harvey & Liu (2015) Eqs. 3-5, independent tests; NORMAL approx to t_{T-1} (ok for T >~ 100)."""
    sr = sr_annual / sqrt(periods_per_year)
    p_s = 2 * (1 - _N.cdf(sr * sqrt(T)))
    p_m = 1 - (1 - p_s)**n_tests
    hsr = _N.inv_cdf(1 - p_m / 2) / sqrt(T) * sqrt(periods_per_year)
    return hsr, 1 - hsr / sr_annual, p_s, p_m


def cscv_pbo(pnl, S=16, metric=None):
    """BBLZ (2017) CSCV. pnl: (T x N) matrix of per-period P&L, one column per trial.
    Returns PBO (share of logits <= 0), logits, and (IS, OOS) metric pairs of the IS-best trial."""
    pnl = np.asarray(pnl, dtype=float)
    if metric is None:
        metric = lambda x: x.mean(axis=0) / x.std(axis=0, ddof=1)  # per-period Sharpe
    T, N = pnl.shape
    assert S % 2 == 0, "S must be even"
    blocks = np.array_split(np.arange(T - T % S), S)  # equal-size row blocks (drop remainder)
    logits, pairs = [], []
    for train_ids in combinations(range(S), S // 2):
        tr = np.concatenate([blocks[s] for s in train_ids])
        te = np.concatenate([blocks[s] for s in range(S) if s not in train_ids])
        r_is, r_oos = metric(pnl[tr]), metric(pnl[te])
        n_star = int(np.argmax(r_is))
        rank_oos = (r_oos < r_oos[n_star]).sum() + 1  # 1 = worst ... N = best
        w = rank_oos / (N + 1)
        logits.append(log(w / (1 - w)))
        pairs.append((r_is[n_star], r_oos[n_star]))
    logits = np.array(logits)
    return float((logits <= 0).mean()), logits, np.array(pairs)


def target_downside_deviation(returns, target=0.0):
    """Sortino TDD: RMS of min(0, x - target) over ALL N observations (zeros kept)."""
    r = np.asarray(returns, dtype=float)
    return sqrt(np.mean(np.minimum(0.0, r - target)**2))


def sortino(returns, target=0.0):
    r = np.asarray(returns, dtype=float)
    return (r.mean() - target) / target_downside_deviation(r, target)


def expected_mdd_zero_drift(sigma, T_years):
    """Magdon-Ismail & Atiya (2004): E[MDD] = sqrt(pi/2) sigma sqrt(T) = 1.2533 sigma sqrt(T)."""
    return 1.2533 * sigma * sqrt(T_years)


def expected_mdd_pos_drift_asymptotic(mu, sigma, T_years):
    """Magdon-Ismail & Atiya (2004), mu > 0, large T: (sigma^2/mu)(0.63519 + 0.5 ln T + ln(mu/sigma))."""
    return sigma**2 / mu * (0.63519 + 0.5 * log(T_years) + log(mu / sigma))


def mppm(excess_returns, rf, dt_years, rho=3.0):
    """Goetzmann-Ingersoll-Spiegel-Welch (2007) manipulation-proof performance measure.
    excess_returns x_t, rf r_ft per period; Theta = ln(mean(((1+rf+x)/(1+rf))^(1-rho)))/((1-rho)dt)."""
    x = np.asarray(excess_returns, dtype=float)
    rf = np.broadcast_to(np.asarray(rf, dtype=float), x.shape)
    return log(np.mean(((1 + rf + x) / (1 + rf))**(1 - rho))) / ((1 - rho) * dt_years)


if __name__ == "__main__":
    # --- paper examples ---
    d, sr0 = dsr(2.5 / sqrt(250), 1250, -3, 10, 0.5 / 250, 100)
    print("DSR example (BLdP 2014): SR0=%.4f DSR=%.4f  [paper: 0.1132, 0.9004]" % (sr0, d))
    print("MinTRL months (BLdP 2012): %.3f  [paper: 59.895]" % min_trl(2 / sqrt(12), 1 / sqrt(12), -0.72, 5.78))
    print("PSR(0) 24m: normal %.3f, non-normal %.3f [paper 0.982, 0.913]" % (psr(0.458, 0, 24), psr(0.458, 0, 24, -2.448, 10.164)))
    print("MinBTL N=45: %.2f yrs (bound %.2f) [paper: ~5 yrs]" % min_btl_years(45))
    print("eta(12) AR1 rho=0.2: %.2f [Lo Table 2: 2.88]" % eta_q_ar1(12, 0.2))
    p = [0.005, 0.009, 0.0128, 0.0135, 0.045, 0.06]
    for m in ("bonferroni", "holm", "bhy"):
        print(m, np.round(adjust_pvalues(p, m), 4))
    print("HL haircut example: HSR=%.3f haircut=%.1f%% pS=%.4f pM=%.3f [paper: 0.32, ~60%%, 0.0008, 0.15]" % tuple(
        (lambda h: (h[0], 100 * h[1], h[2], h[3]))(haircut_sr_independent(0.75, 240, 12, 200))))
    print("Sortino example: %.3f [Red Rock: 4.417]" % sortino([.17, .15, .23, -.05, .12, .9e-1, .13, -.04]))
    x = np.array([-.1, .05, .17, -.02])  # GISW WP example, treated as excess returns
    print("MPPM (GISW WP 4-period example, dt=1): rho=2 %.4f, rho=3 %.4f  [WP text says 1.036 / 1.109 -- NOT reproducible]"
          % (mppm(x, .01, 1.0, 2.0), mppm(x, .01, 1.0, 3.0)))
    rng = np.random.default_rng(0)
    pbo, lg, pr = cscv_pbo(rng.normal(0, 1, size=(1600, 50)), S=16)
    print("CSCV on pure noise (expect ~0.5): PBO=%.3f, n_logits=%d [C(16,8)=%d]" % (pbo, len(lg), comb(16, 8)))
    sig = rng.normal(0, 1, size=(1600, 50)); sig[:, 0] += 0.15
    pbo2, _, _ = cscv_pbo(sig, S=16)
    print("CSCV with one genuinely skilled trial (expect ~0): PBO=%.3f" % pbo2)
