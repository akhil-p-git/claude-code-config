---
description: "Data acquisition: scraping, APIs, validation, storage"
paths:
  - "**/scrape/**"
  - "**/scraping/**"
  - "**/scraper*.py"
  - "**/crawl*.py"
  - "**/etl/**"
  - "**/ingest/**"
  - "**/pipelines/**"
  - "**/*.ipynb"
---

# Data Acquisition

- Prefer an official/public API over scraping; APIs are stable, versioned, and faster.
- Respect `robots.txt` (`urllib.robotparser`) and the site's ToS; send a descriptive User-Agent.
- Rate-limit politely (start ~1 req/s, slower for small sites); add jittered delays; scrape off-peak.
- Retry transient failures (429/503) with exponential backoff + jitter: `wait = 2**attempt + random()`.
- Cache every response; never re-fetch what you already have. Dedupe via a seen-URLs set. Make runs idempotent.
- Handle pagination explicitly (page params / "load more" / infinite scroll); loop until no new data or a hard bound.
- Two-layer storage: keep raw responses immutable and unmodified; clean into a SEPARATE processed layer.
- Validate parsed data against an explicit schema (Pydantic per-record, Pandera for DataFrames); fail loud when a site's layout changes.
- Write results incrementally so a crash doesn't lose progress.
- API keys/secrets from env or a secrets manager only — never hardcoded, never committed.
- Reproducibility: pin date ranges/params as arguments; log run metadata (url, status, count, duration) as JSON.

**Defaults:** `httpx` (async, controlled concurrency) or `requests`; `playwright` for JS-rendered pages; `pydantic`/`pandera` for validation; `polars` + `duckdb` for fast local processing; store raw as Parquet/JSON.
