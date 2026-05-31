---
description: "HTTP/REST and GraphQL API design standards"
paths:
  - "**/api/**"
  - "**/routes/**"
  - "**/controllers/**"
  - "**/*.openapi.*"
  - "**/openapi/**"
---

# API Design (REST & GraphQL)

## REST Resources & Methods
- Model resources as nouns, plural collections: `/orders`, `/orders/{id}`, nested `/orders/{id}/items`. No verbs in paths.
- GET/HEAD/OPTIONS are safe; GET/PUT/DELETE/HEAD are idempotent; POST/PATCH are not. Never mutate on GET.
- PUT replaces the full resource (idempotent). PATCH applies a partial update (JSON Merge Patch RFC 7396 or JSON Patch RFC 6902).
- Status codes: 200, 201 (+`Location`), 202 (async), 204. Errors: 400 malformed, 401 unauthenticated, 403 unauthorized, 404, 409 conflict, 422 validation, 429 rate limited, 500. Never return 200 with an error body.

## Errors (RFC 9457)
- Return `application/problem+json` per RFC 9457 (obsoletes RFC 7807) for every error.
- Use members `type` (URI), `title`, `status`, `detail`, `instance`. Keep `type` stable; `title` constant per type; `detail` per-occurrence.
- Add extension members (e.g. `code`, `errors[]` with `pointer`/`detail`) for field validation; clients must ignore unknown members. Never leak stack traces.

## Versioning, Caching & CORS
- Version in the URI (`/v1/...`) for public APIs or via media type (`Accept: application/vnd.app.v2+json`). Pick one; never break v1 in place. Bump major only on breaking changes.
- Emit `ETag`; honor `If-None-Match` (304) and `If-Match` for optimistic concurrency (412 on mismatch). Set explicit `Cache-Control` (`no-store` for sensitive data, `private`).
- CORS: echo only allowlisted origins (never `*` with credentials), restrict methods/headers, set `Vary: Origin`.

## Pagination
- Use cursor/keyset pagination for large or mutating sets (`?limit=&cursor=`); avoid offset/`OFFSET` (drift + slow at depth).
- Return an opaque cursor + envelope: `{ "data": [...], "next_cursor": "...", "has_more": bool }`. Cap and document a max `limit`.

## Idempotency, Rate Limiting & Auth
- Accept `Idempotency-Key` (UUID) on POST/PATCH; store key+request-hash+response and replay the saved response on retry; 422 if the same key is reused with a different payload.
- On throttle return 429 with `Retry-After`; emit IETF `RateLimit` / `RateLimit-Policy` structured fields.
- Auth with OAuth 2.1: Authorization Code + PKCE for user clients (PKCE mandatory; Implicit/Password removed), Client Credentials for M2M. Bearer tokens in the `Authorization` header only, never query strings; require HTTPS.
- Validate every token server-side: signature, `iss`, `aud`, `exp`, and required scopes. Access tokens ~15m with rotating refresh tokens. Authorize ownership/role on every mutation.

## Contract-First & Webhooks
- Author an OpenAPI 3.1 spec before coding; validate requests AND responses against it in CI; generate clients/docs from it.
- Sign outbound webhooks with HMAC-SHA256 over the raw body plus a timestamp; reject deliveries older than ~5 min; compare in constant time (`timingSafeEqual`/`compare_digest`).
- Consumers must be idempotent: dedupe on the provider event ID. Ack fast (200/202) and queue work. Senders retry with exponential backoff + jitter, then dead-letter.

## GraphQL
- Design a typed schema with Relay-style Connections (`edges`/`node`/`pageInfo`/cursors) for lists; never expose DB columns or internal IDs directly.
- Solve N+1 with a per-request DataLoader (batch + cache); never reuse loaders across requests (cross-tenant leak).
- Enforce query depth (~7-10) and cost/complexity limits; use persisted/allow-listed queries in production; disable introspection on public endpoints.
- Prefer REST for cacheable CRUD, GraphQL for many clients needing varied shapes, gRPC for low-latency internal service-to-service.
