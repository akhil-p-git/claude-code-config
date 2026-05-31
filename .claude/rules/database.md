---
description: "Database and data-layer standards"
paths:
  - "**/migrations/**"
  - "**/models/**"
  - "**/repositories/**"
  - "**/prisma/**"
  - "**/*.sql"
  - "**/schema.*"
---

# Database & Data Layer

## Schema Design
- Normalize to 3NF first; denormalize only with a measured read-path reason and a plan to keep copies in sync.
- Pick the narrowest correct type: `text` over `varchar(n)` unless a real limit exists, `numeric` for money (never float), `boolean` not int flags, native `enum`/lookup table for fixed sets.
- Default to `NOT NULL`; add `CHECK`, `UNIQUE`, and `FOREIGN KEY`s with explicit `ON DELETE` behavior. Enforce invariants in the DB, not just app code.
- Use UUIDv7 (Postgres 18 `uuidv7()`) or `bigint GENERATED ALWAYS AS IDENTITY` for PKs. Prefer UUIDv7 when IDs are client-generated, distributed, or exposed externally: it is time-ordered so it keeps B-tree index locality. Never use `serial`.
- Store all timestamps as `timestamptz` in UTC; convert to local time only at display.
- Soft delete (`deleted_at`) only when audit/recovery is required; pair it with partial unique indexes (`... WHERE deleted_at IS NULL`). Otherwise hard-delete.

## Indexing
- Index every foreign key column (Postgres does not auto-index them) and columns frequently in `WHERE`/`JOIN`/`ORDER BY`/`GROUP BY`.
- Composite index column order: leading columns match equality predicates; put equality columns before range columns. The index serves only its leftmost-prefix.
- Use covering indexes via `INCLUDE` for index-only scans; use partial indexes for queries that always filter on a subset.
- Don't over-index: every index taxes writes. Aim for ~5-10 deliberate indexes per table; drop unused ones.
- Build/drop indexes on live tables with `CREATE INDEX CONCURRENTLY`. Validate plans with `EXPLAIN (ANALYZE, BUFFERS)`.

## Query Performance
- Never `SELECT *`; list only needed columns (enables index-only scans, smaller payloads, stable contracts).
- Eliminate N+1: eager-load via JOIN, `IN (...)` batch fetch, or a DataLoader. Inspect ORM-generated SQL on hot paths.
- Paginate large sets with keyset (cursor) pagination — `WHERE (sort_col, id) > ($1, $2) ORDER BY sort_col, id LIMIT n` — not `OFFSET`. Index must match the sort tuple.
- Batch inserts/updates into multi-row statements or `COPY`; avoid row-by-row loops.
- Avoid implicit casts on indexed columns — they disable index use. Match parameter types to column types.

## Query Safety
- ALWAYS use parameterized queries / prepared statements. NEVER string-concatenate or interpolate user input into SQL.
- Keep transactions short; never hold one open across network calls or user think-time. Long transactions block vacuum and bloat the DB.
- Choose isolation deliberately: default `READ COMMITTED`; use `REPEATABLE READ`/`SERIALIZABLE` for multi-statement invariants and retry on serialization failures.
- Use least-privilege DB roles: the app role gets only DML on its tables, never `SUPERUSER`/DDL. Separate migration and runtime roles.
- Front the DB with a pooler (PgBouncer/Supavisor) in transaction mode; don't rely on cross-transaction session state.

## Migrations
- Version every migration in source control, review it like code, and provide a reversible down path. Test on a production-like copy first.
- Never run destructive DDL (`DROP`, type narrowing) without a verified backup and a rollback plan.
- Zero-downtime via expand-contract: (1) expand — add nullable columns/new tables, deploy code writing both; (2) backfill in batches as a separate step; (3) contract — drop the old once all code uses the new. Keep each step backward-compatible.
- Add columns as nullable, backfill, then add `NOT NULL`/constraints with `VALIDATE`; set `statement_timeout`/`lock_timeout` on migrations.

## ORM Discipline (Prisma / Drizzle / SQLAlchemy)
- Read the generated SQL for any hot or list query; ORMs hide N+1, full scans, and over-fetching.
- Avoid implicit lazy loading on relations in request paths; load explicitly.
- Let the ORM generate migrations but review the emitted SQL before committing — watch for unintended table rewrites or drops.
- Drop to raw/typed SQL (Prisma TypedSQL, Drizzle `sql`, SQLAlchemy `text`) for complex joins/window functions/CTEs — still parameterized.

## Operations
- Take automated backups AND rehearse restores on a schedule; an untested backup is not a backup. Know your RPO/RTO.
- Cache hot reads in Redis with explicit invalidation (write-through or delete-on-write) and a TTL safety net.
- Monitor slow queries (`pg_stat_statements`), index hit ratio, replication lag, and connection saturation; alert on regressions.
