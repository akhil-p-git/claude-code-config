# SLOs and alerting

Sources: Google SRE book ch. 6, SRE Workbook ch. 5 "Alerting on SLOs", Rob Ewaschuk "My Philosophy on Alerting", PagerDuty alerting docs, DORA (dora.dev, 2026).

## Principles
- Page only on symptoms users feel (errors, latency, availability) — "Pages should be urgent, important, actionable, and real." Cause-based alerts only for imminent cliffs (e.g. disk/quota "will run out in < 4h at the last hour's growth rate").
- Every alert needs a human action and a runbook link. "An untested alert is equivalent to not having an alert at all." Alerts that are wrong more than half the time are broken; remove noisy ones.
- Golden signals: latency (percentiles/histograms, not means; error latency separately), traffic, errors, saturation.

## Multiwindow, multi-burn-rate alerts (30-day SLO)
Fire only when BOTH windows exceed the threshold; short window = 1/12 of the long one.

| Severity | Long window | Short window | Burn rate | Budget consumed | Error-ratio threshold @99.9% | @99.5% |
| --- | --- | --- | --- | --- | --- | --- |
| Page | 1 h | 5 min | 14.4 | 2% | 1.44% | 7.2% |
| Page | 6 h | 30 min | 6 | 5% | 0.6% | 3% |
| Ticket | 3 d | 6 h | 1 | 10% | 0.1% | 0.5% |

threshold = burn rate × (1 − SLO); budget consumed = burn rate × long window ÷ SLO period. Suppress lower-severity alerts while a higher one fires. Don't use "for: Xm" durations as the SLO alert condition.

## Low-traffic services (most side projects)
At 10 requests/hour a single failure is a 1,000× burn rate. Options: synthetic probes (uptime checks every minute), combine services into one SLO, client retries with backoff, a lower SLO, or a longer window.

## DORA delivery metrics (2026 definitions)
Change lead time · deployment frequency · failed deployment recovery time (replaced MTTR in 2023) · change fail rate · deployment rework rate (added 2024). DORA's 2025 AI report: AI raises throughput but hurts stability unless testing, version control, small batches, and fast feedback are strong.
