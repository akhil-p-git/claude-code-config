---
description: "Application security standards (OWASP Top 10 2025-aligned)"
---

# Security Standards

## Access Control (OWASP A01:2025)
- Deny by default; grant access only via explicit allow rules.
- Enforce authorization server-side on every request; never trust client-supplied roles/flags.
- Prevent IDOR: verify the authenticated user owns or may access the specific record before any read/write.
- Use opaque/random identifiers, not sequential IDs, for user-facing resources.
- SSRF (now folded into A01): validate outbound URLs against an allowlist; block internal IPs, link-local, and cloud metadata endpoints.

## Injection & XSS (A05:2025)
- Use parameterized queries / prepared statements always; never string-concatenate SQL, shell, or LDAP.
- Validate input with schema validators (Zod for TS, Pydantic for Python); reject, don't fix, malformed input.
- Output-encode by context (HTML, attribute, JS, URL); rely on framework auto-escaping.
- Never use `dangerouslySetInnerHTML`/`v-html`; if unavoidable, sanitize with DOMPurify first.
- Avoid `eval`, `exec`, dynamic `Function`, and templating from user input.

## Authentication (A07:2025)
- Prefer passkeys/WebAuthn (FIDO2) as the primary, phishing-resistant method.
- Use OAuth 2.1 with PKCE for all clients; require exact redirect-URI matching; ban Implicit and Password grants.
- Hash passwords with argon2id (or bcrypt cost ≥12); enforce MFA for privileged accounts.
- Store JWTs in `HttpOnly`+`Secure`+`SameSite=Strict` cookies, never localStorage.
- Keep access tokens short-lived (5-15m); rotate single-use refresh tokens; verify `alg`, `iss`, `aud`, `exp` server-side and reject `alg:none`.

## Secrets Management
- Never hardcode or commit secrets; load from env/vault; add `.env`, `*.key`, `*.pem`, `secrets/` to `.gitignore`.
- Run gitleaks or trufflehog as a pre-commit hook to block secret commits.
- Rotate any exposed credential immediately; assume leaked = compromised.
- Scope keys to least privilege; never log secrets, tokens, or PII.

## Software Supply Chain (A03:2025)
- Commit lockfiles; enable integrity hashes; pin and verify dependency versions.
- Run `npm audit`/`pip-audit`/`osv-scanner` in CI; gate on Dependabot/Renovate updates.
- Verify every AI-suggested package exists and is legitimate before installing — beware slopsquatting (hallucinated names) and typosquatting; check publisher and registration date.
- Prefer packages with npm provenance/SLSA attestation; secure CI/CD pipelines and build tools.

## Security Headers & CSRF
- Ship a strict CSP Level 3: nonce/hash + `strict-dynamic`, `object-src 'none'`, no `unsafe-inline`/`unsafe-eval`.
- Set `Strict-Transport-Security` (HSTS, preload), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and a restrictive `Permissions-Policy`.
- Use `helmet()` for Express; serve all traffic over HTTPS.
- Defend CSRF with `SameSite` cookies plus anti-CSRF tokens on state-changing requests.
- Configure CORS with explicit origins (no wildcard with credentials).

## Misconfiguration, Logging & Errors (A02/A09/A10:2025)
- Harden defaults: disable directory listing, debug modes, and stack traces in production.
- Rate-limit auth and expensive endpoints; throttle by IP and account.
- Log security events (authz failures, logins) with alerting; never log secrets/PII.
- Handle exceptional conditions explicitly: fail closed, validate all error paths, never "fail open" on auth.

## Before Every Commit
- Check staged files: `git diff --cached --name-only`; verify no `.env`, `.key`, `.pem`, or credential files staged.
- Run the dependency audit and secret scanner; resolve high-severity findings before pushing.
