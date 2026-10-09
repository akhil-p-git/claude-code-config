---
description: "Containers, CI/CD, IaC, and deploy safety (Docker, Compose, GitHub Actions, Terraform, Kubernetes, Helm, Vercel)"
paths:
  - "**/Dockerfile*"
  - "**/*.dockerfile"
  - "**/.dockerignore"
  - "**/compose*.y*ml"
  - "**/docker-compose*.y*ml"
  - "**/.github/workflows/**"
  - "**/.github/actions/**"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tftest.hcl"
  - "**/k8s/**"
  - "**/kubernetes/**"
  - "**/manifests/**"
  - "**/helm/**"
  - "**/charts/**"
  - "**/Chart.yaml"
  - "**/vercel.json"
  - "**/fly.toml"
  - "**/wrangler.toml"
  - "**/railway.json"
---

# DevOps, CI/CD & Infrastructure

## Never without explicit approval for that run
`terraform|tofu apply/destroy` (or any `-auto-approve`), `kubectl delete/drain/scale` or `helm uninstall` on a shared cluster, `docker compose down -v` / `docker volume rm|prune` / `docker system prune --volumes` (they delete database volumes), production deploys or promotions, and any data-loss flag used to get past a prompt (`drizzle-kit push --force`, `prisma migrate reset --force`, `prisma db push --accept-data-loss`). Real incidents in 2025–26 — including Claude Code wiping a production database with `drizzle-kit push --force` and running `terraform destroy` after a state mix-up — all came from exactly these. Stop at the plan/diff and show it.

## Containers
- Start Dockerfiles with `# syntax=docker/dockerfile:1` and `# check=error=true`; run `docker build --check .` and `hadolint` before building.
- Multi-stage builds; the final stage holds only the runtime and built artifacts. Order layers lockfile → install → source; use `RUN --mount=type=cache` for package caches.
- Pin base images as `name:exact-tag@sha256:<digest>`; never `latest`. Look digests up (`docker buildx imagetools inspect <ref>`) — never invent one. Prefer explicit Debian 13 tags (`node:24-trixie-slim`; plain `node:24-slim` is bookworm).
- Never pass secrets via `ARG`/`ENV`/`--build-arg` (they persist in history and provenance): use `RUN --mount=type=secret,id=x,env=X` + `docker build --secret id=x,env=X`. `NEXT_PUBLIC_*` values are inlined into the bundle — never secrets.
- Run as a numeric non-root `USER uid:gid` (`COPY --link --chown` must be numeric too). Exec-form `CMD`/`ENTRYPOINT`; Node needs `--init`/`init: true` (it isn't PID-1 safe); handle SIGTERM within the stop timeout.
- Ship a `.dockerignore` covering `.git`, `node_modules`, `.next`, `.venv`, `.env*`, keys.
- Compose: `compose.yaml` with top-level `name:`, no `version:`; validate with `docker compose config -q`; required vars as `${VAR:?msg}`; wait with `depends_on: {db: {condition: service_healthy}}` + a real healthcheck; publish dev ports on `127.0.0.1:` only (Docker's NAT bypasses ufw); secrets via top-level `secrets:` + `*_FILE` vars.
- Postgres 18+ images: mount the volume at `/var/lib/postgresql`, not `/var/lib/postgresql/data` (the container exits otherwise). Major-version upgrades need `pg_upgrade` or dump/restore.

## GitHub Actions
- Pin third-party actions to a full commit SHA with a `# vX.Y.Z` comment (tags can be hijacked — trivy-action was, in March 2026). Lint workflows with `actionlint` and `zizmor`.
- Default `permissions: contents: read` at the top; grant more per job. Prefer OIDC (`id-token: write`) to long-lived cloud keys; `actions/checkout` with `persist-credentials: false`.
- Never interpolate untrusted `${{ github.event.* }}` (titles, bodies, branch names) into `run:` — pass through `env:`. Never check out PR head code in `pull_request_target`.
- Set `timeout-minutes` and `concurrency` (cancel superseded PR runs, never in-flight deploys). No dependency caching in release/publish jobs.
- Tags and releases created with `GITHUB_TOKEN` don't trigger other workflows — publish in the same job or use a GitHub App token.

## Terraform / OpenTofu
- Use the binary the repo uses (`tofu` vs `terraform`) and don't mix syntax. Saved plans only: `plan -input=false -out=tfplan` → I review `show tfplan` → `apply tfplan`. Plan files contain secrets in cleartext; never commit them.
- Before trusting a plan, confirm backend, workspace, and cloud account. A plan that recreates existing infrastructure or destroys things you didn't touch means wrong/missing state: stop.
- Never hand-edit state. Refactor with `moved` / `import` / `removed` blocks (a `removed` block destroys the resource unless `lifecycle { destroy = false }`). Keep `prevent_destroy` on stateful resources; never remove a guard to get a plan through.
- `sensitive = true` only hides output — use ephemeral values / write-only arguments to keep secrets out of state. Pin `required_version`, providers (`~>`), and modules; commit `.terraform.lock.hcl`.
- `terraform test` runs default to `command = apply` (real infrastructure); use `command = plan` with mocks unless I approve.

## Kubernetes / Helm
- Always pass explicit `--context` and `-n`. Validate before applying: `kubeconform -strict`, `kubectl diff --server-side`, `kubectl apply --server-side --dry-run=server`.
- Images by digest; restricted Pod Security (non-root, drop ALL caps, no privilege escalation, seccomp RuntimeDefault); requests on every container; readiness for traffic, liveness never checks external dependencies; never commit `kind: Secret` manifests.
- Helm 4 renamed flags (`--atomic` → `--rollback-on-failure`, `--force` → `--force-replace`) and doesn't wait unless `--wait`; preview upgrades with `helm diff upgrade` or `--dry-run=server`.

## Deploys (Vercel and others)
- Preview deploys are fine; production deploys, promotions, rollbacks, domain/DNS and env-var changes need my go-ahead. Inspect deployment state and logs before changing configuration.
- Every deploy needs a stated rollback path (previous deployment, flag off, revert) before it starts, and a post-deploy check (health endpoint, smoke test, error logs) after.
