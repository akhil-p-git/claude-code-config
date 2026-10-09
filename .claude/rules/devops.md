---
description: "Containers, CI/CD, IaC, and deploy safety (Docker, Compose, GitHub Actions, Terraform/OpenTofu, Kubernetes, Helm, Vercel, Fly, Cloudflare)"
paths:
  - "**/{Dockerfile,Containerfile}*"
  - "**/*.{dockerfile,containerfile}"
  - "**/.dockerignore"
  - "**/{compose,docker-compose}*.{yml,yaml}"
  - "**/.github/{workflows,actions}/**"
  - "**/.github/dependabot.{yml,yaml}"
  - "**/action.{yml,yaml}"
  - "**/{renovate.json,renovate.json5,.renovaterc,.renovaterc.json}"
  - "**/*.{tf,tfvars,tofu,tftest.hcl}"
  - "**/terragrunt.hcl"
  - "**/{k8s,kubernetes,manifests,helm,charts}/**"
  - "**/{Chart,kustomization,skaffold}.{yml,yaml}"
  - "**/vercel.{json,toml,ts,mts,js,mjs,cjs}"
  - "**/{fly,netlify,railway}.toml"
  - "**/{wrangler.toml,wrangler.json,wrangler.jsonc,railway.json,render.yaml,Procfile,.gitlab-ci.yml}"
---

# DevOps, CI/CD & Infrastructure

## Irreversible and production actions
`hooks/guard-prod-actions.sh` blocks the irreversible ones (terraform/tofu `destroy` or `-auto-approve`, `drizzle-kit push --force`, `prisma migrate reset` / `--accept-data-loss` / `--force-reset`, `supabase db reset --linked`, `kubectl delete namespace|--all`, deleting Fly/Cloudflare/GitHub resources) and forces a prompt for deploys, promotions, rollbacks, publishes, releases, `apply`, remote migrations, secret changes, image pushes, `docker compose down -v`, and pushes. Never route around it (`sh -c`, full paths, env tricks) and never add a force flag to get past a prompt: stop at the plan or diff, show it, and hand the user the exact command (`! <cmd>`). Real 2026 agent incidents came from exactly these commands.
- Keep production credentials and database URLs out of local `.env*` files and agent sessions; production migrations run in the platform's release phase or CI, never from this machine.

## Containers
- Start Dockerfiles with `# syntax=docker/dockerfile:1` and `# check=error=true`; run `docker build --check .` and `hadolint` before building.
- Multi-stage builds; the final stage holds only the runtime and built artifacts. Order layers lockfile → install → source; `RUN --mount=type=cache` for package caches.
- Pin base images as `name:exact-tag@sha256:<digest>`, never `latest`; look digests up (`docker buildx imagetools inspect <ref>`), never invent one. Prefer explicit Debian 13 tags (`node:24-trixie-slim`; plain `node:24-slim` is bookworm). Node 24 is LTS until 26 takes over on 2026-10-28.
- Never pass secrets via `ARG`/`ENV`/`--build-arg`: use `RUN --mount=type=secret,id=x,env=X`. `NEXT_PUBLIC_*` values are inlined into the client bundle.
- Numeric non-root `USER uid:gid`; exec-form `CMD`; Node needs `--init`/`init: true`; handle SIGTERM within the stop timeout; add a `HEALTHCHECK` (or platform health check) that hits a real endpoint.
- `.dockerignore` covers `.git`, `node_modules`, `.next`, `.venv`, `.env*`, keys. Deploy and roll back by image digest, not tag.
- Compose: `compose.yaml` with top-level `name:`, no `version:`; `docker compose config -q`; `${VAR:?msg}` for required vars; `depends_on: {db: {condition: service_healthy}}` + a real healthcheck; dev ports on `127.0.0.1:` only (Docker's NAT bypasses ufw); `up -d --wait` in scripts.
- Postgres 18+ images: mount the volume at `/var/lib/postgresql`, not `.../data`. Major upgrades need `pg_upgrade` or dump/restore.

## GitHub Actions
- Pin every action (including `actions/*`) to a full commit SHA with a `# vX.Y.Z` comment. Resolve SHAs with `gh api repos/OWNER/REPO/commits/vX.Y.Z --jq .sha` or `pinact run`; never write one from memory. Use current majors: Node 20 is gone from runners (2026-09-23), so `@v4`-era actions in older examples (including plugin skills) are stale. setup-uv publishes no major tags since v8.
- Lint every workflow change with `actionlint` and `zizmor`. Dependabot doesn't alert on SHA-pinned actions, so zizmor's `known-vulnerable-actions` is the advisory check.
- Top-level `permissions: contents: read` (or `{}`), more per job only. OIDC (`id-token: write`) over long-lived cloud keys; in the cloud trust policy pin `aud` exactly and `sub` to one repo plus a branch or environment, copying the repo's real `sub` format (repos created after 2026-07-15 default to an ID-based format), and never widen `sub` to fix an `aud` error. `actions/checkout` with `persist-credentials: false`. Pin `runs-on: ubuntu-24.04` (ubuntu-latest moves to 26.04 Oct–Nov 2026).
- Never interpolate `${{ github.event.* }}`, step outputs, or secrets into `run:`; pass them through `env:`. Pass deploy tokens as env vars (`VERCEL_TOKEN`), never on argv. No `secrets: inherit`; no `toJSON(secrets)`.
- Avoid `pull_request_target` (GitHub disables it by default on public repos from 2026-11-02) and treat `workflow_run` artifacts as untrusted. Never check out PR head code in either.
- Every job gets `timeout-minutes`. CI: `concurrency` with `cancel-in-progress` for PRs. Deploy and release: `cancel-in-progress: false`, `cache-mode: none`, an `environment:` (reviewers if wanted), and no dependency caches.
- Installs are frozen (`pnpm install --frozen-lockfile`, `npm ci`, `uv sync --locked`); never `npm install <pkg>` or `pip install <pkg>` ad hoc in a step.
- Tags and releases created with `GITHUB_TOKEN` don't trigger other workflows: publish in the same workflow or use a GitHub App token. Prefer trusted publishing (npm, PyPI) over registry tokens.
- Hardened starting points (CI for pnpm and uv, workflow lint, Dependabot with a cooldown, container publish, Vercel deploy, release-please) live in `~/.claude/templates/github/`. Their pins were resolved 2026-10-08: run `pinact run --verify` before committing one.

## Terraform / OpenTofu
- Use the binary the repo uses (`tofu` vs `terraform`). Saved plans only: `plan -input=false -out=tfplan` → user reviews `show tfplan` → user applies. Plan files contain secrets in cleartext; never commit them.
- Before trusting a plan, confirm backend, workspace, and account. A plan that recreates existing infrastructure or destroys things you didn't touch means wrong or missing state: stop. Remote state with locking (S3 `use_lockfile = true`), never local state for shared infra.
- Never hand-edit state. Refactor with `moved`/`import`/`removed` blocks (`removed` destroys unless `lifecycle { destroy = false }`). Keep `prevent_destroy` and provider deletion protection on stateful resources, and backups that survive deleting the resource.
- Ephemeral values / write-only arguments keep secrets out of state (`sensitive` only hides output). Pin `required_version`, providers (`~>`), modules; commit `.terraform.lock.hcl`. `terraform test` defaults to `command = apply`: use `plan` + mocks unless approved.

## Kubernetes / Helm
- Always pass explicit `--context` and `-n`. Validate before applying: `kubeconform -strict`, `kubectl diff --server-side`, `kubectl apply --server-side --dry-run=server`.
- Images by digest; restricted Pod Security (non-root, drop ALL, no privilege escalation, seccomp RuntimeDefault); requests on every container; readiness gates traffic, liveness never checks dependencies; never commit `kind: Secret`.
- Helm 4 renamed `--atomic` → `--rollback-on-failure` and `--force` → `--force-replace`; preview with `helm diff upgrade` or `--dry-run=server`.

## Deploys
- Every deploy states its rollback path before it starts and is verified after (the `/deploy` skill). Rollback restores code, not data: if this deploy changes schema or stored formats, the previous version must still work against them (expand/contract, two-phase), or there is no rollback.
- Vercel: stage a production build with `vercel deploy --prod --skip-domain`, verify that URL, then `vercel promote` it (instant, same artifact). Promoting a preview-built deployment creates a new production build instead.
