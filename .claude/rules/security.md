---
description: "Application security standards (OWASP 2025-aligned); loads when code or infra files are touched"
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,mts,cts,py,java,kt,cs,go,rs,rb,php,c,h,cpp,sql,sh}"
  - "**/{Dockerfile,Containerfile,compose.yaml,compose.yml,docker-compose.yml}"
  - "**/.github/workflows/*.{yml,yaml}"
  - "**/*.tf"
---

# Security

AI-written code most often ships missing authorization, injection, leaked secrets, and invented dependencies. Check those first.

## Access control
- Authorize on the server for every request and every object: verify the caller may act on *this* record or tenant (IDOR), not just that they are logged in. Next.js Server Actions and route handlers are public endpoints — authenticate and authorize inside each one; middleware/`proxy.ts` alone is not enough.
- Deny by default; never trust client-supplied roles, prices, or IDs.
- Outbound requests to user-supplied URLs (SSRF): allowlist hosts; block private, link-local, and cloud-metadata addresses; don't follow redirects blindly.

## Injection and output
- Parameterize every query (SQL, NoSQL, ORM raw); never build SQL, shell commands, paths, or LDAP filters from strings. Use argument arrays for subprocesses, never `shell=True`/string `exec`.
- Validate input at the boundary with a schema (Zod, Pydantic) and reject what doesn't fit. Resolve file paths and confirm they stay inside the intended directory.
- Rely on framework escaping; `dangerouslySetInnerHTML`/`v-html` only with sanitized (DOMPurify) input. No `eval`, `new Function`, `pickle`/`yaml.load` on untrusted data.

## Auth, sessions, secrets
- Passwords: argon2id (or bcrypt cost ≥ 12). Tokens: short-lived access + rotating refresh; verify signature, `alg`, `iss`, `aud`, `exp` server-side; session tokens in `HttpOnly; Secure; SameSite` cookies, not localStorage. Compare secrets in constant time.
- Secrets come from env or a secret store; never hardcode, log, or commit them, and never put them in `NEXT_PUBLIC_*` or client bundles. A secret that reached git history is compromised: rotate it.
- Verify webhook signatures (HMAC over the raw body + timestamp window) before parsing.

## Dependencies
- Before adding a package, confirm on the registry that it exists, is the one you meant (typosquats and AI-hallucinated names are registered as malware), is maintained, and has no install-script surprises. Pin via the lockfile; run `npm audit` / `pip-audit` when dependencies change.
- Prefer a release cooldown so brand-new (possibly hijacked) versions aren't installed: npm ≥ 11.10 `min-release-age=7` (days) in `.npmrc`, pnpm `minimumReleaseAge: 10080` (minutes) in `pnpm-workspace.yaml`.

## LLM and agent features (OWASP LLM Top 10 2025, Agentic Top 10 2026)
- Never let one model context hold private data, untrusted content, and an outbound channel at once (the "lethal trifecta"); if a feature needs all three, require human approval for each consequential action.
- Treat every model input you didn't write (user text, web pages, email, documents, RAG chunks, tool results) as hostile, and every model output as untrusted input to SQL, shell, HTML/markdown, redirects, file paths, and tools. Validate structured output with Zod/Pydantic.
- Enforce authorization in code, never in the system prompt; keep secrets and other users' data out of prompts and shared caches.
- Give tools least privilege: read-only by default, per-user credentials, schema-validated arguments, confirmation for destructive or irreversible actions. Filter retrieval by the caller's tenant and permissions before the model sees anything.
- Cap cost on public LLM endpoints: per-user rate and spend limits, max tokens, max tool-loop steps, timeouts.
- Pin model IDs, MCP servers, and tool versions; treat tool descriptions from third-party MCP servers as untrusted.

## Config and errors
- Fail closed: an error in an auth or permission check denies. No stack traces, debug mode, or verbose errors in production responses.
- Security headers on web apps: strict CSP (nonces/hashes, no `unsafe-inline`), HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy`. CORS: explicit origins, never `*` with credentials.
- Rate-limit authentication and expensive endpoints.
