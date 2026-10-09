---
description: "Node.js backend/API standards"
paths:
  - "**/server/**"
  - "**/backend/**"
  - "**/api/**"
  - "**/routes/**"
  - "**/controllers/**"
  - "**/middleware/**"
  - "**/services/**"
---

# Node.js Backend

- Validate every request (params, query, body, headers you rely on) with a Zod schema before use; reject with 400/422 and a problem+json body (see api-design rules).
- Parse and validate configuration once at startup (Zod over `process.env`) and fail fast on missing values; never read `process.env` ad hoc deep in the code.
- One central error handler that maps typed errors (`NotFoundError`, `ValidationError`, …) to status codes and never leaks stack traces. Express 5 forwards rejected promises from async handlers on its own — don't add `asyncHandler` wrappers there (Express 4 still needs them).
- Structured logging with pino (request-scoped child loggers, a correlation/request ID); never `console.log` in server code; never log secrets, tokens, or PII.
- Put timeouts on every outbound call and DB query; retry only idempotent operations, with backoff and jitter.
- Keep handlers thin: parse → call a service → map the result. Database access lives in a repository/data-access layer, always parameterized.
- Handle `SIGTERM`/`SIGINT`: stop accepting connections, drain in-flight requests, close pools, then exit.
