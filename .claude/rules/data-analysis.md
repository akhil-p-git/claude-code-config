---
description: "Data analysis and notebooks: profiling, correct aggregation, leakage, inference, reproducibility"
paths:
  - "**/*.ipynb"
  - "**/notebooks/**"
  - "**/analysis/**"
  - "**/eda/**"
  - "**/*.{qmd,Rmd}"
---

# Data analysis

## Before analyzing
- Pin the question: the metric's definition (numerator, denominator, filters, grain, window, timezone) and the
  decision it informs.
- Profile first: row counts, key uniqueness, null rates, min and max dates, duplicates, and units. Keep missing,
  zero, not-applicable, and censored values distinct; never `fillna(0)` silently.
- Treat raw data as read-only and write derived data to a separate path.

## Correctness
- Joins: assert the expected cardinality (`pd.merge(..., validate="many_to_one")`, Polars `join(validate=...)`)
  and compare row counts before and after.
- Aggregates: take ratios of sums, not means of ratios; weight averages by group size; compare complete periods only.
- Leakage: split by time or entity before fitting any scaler, imputer, encoder, feature selector, or model. Never
  use shuffled CV on time series. Check features for information recorded after the outcome.
- Inference: report the effect size with a confidence interval and n, not a p-value alone. Count every hypothesis
  you tested and pre-specify confirmatory ones; adjust with Holm (FWER) or Benjamini–Hochberg (FDR). Label
  post-hoc slices exploratory.
- Before concluding, check for Simpson's paradox across major segments, survivorship (who is missing), selection
  on the outcome, and regression to the mean. Use no causal language for observational correlations.

## Reproducibility
- Restart-and-run-all before sharing or committing a notebook. Keep parameters at the top, set seeds, and strip
  outputs from git (`nbstripout`) or use marimo `.py` notebooks.
- Record the data snapshot, query text, package versions (`uv.lock`), and run date alongside results.
- Charts: label units and source, start bar charts at zero, and don't put unrelated series on dual axes.
