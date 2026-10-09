---
name: deploy
description: Deploy the current project with pre-flight checks, a rollback path recorded (and checked against the schema) before deploying, a staged production deploy where the platform supports it, and post-deploy verification. Auto-detects Vercel, Fly.io, Cloudflare (wrangler), Railway, Render, Docker Compose hosts, or a CI deploy workflow. Run only when the user invokes /deploy.
argument-hint: "[preview|production] [notes]"
disable-model-invocation: true
---

# Deploy

Arguments: `$ARGUMENTS`. Default target is **preview**. Production needs the word "production" from the user in this conversation and a final confirmation of the summary in step 4. `hooks/guard-prod-actions.sh` also prompts on every production command; that prompt is the user's decision point, so never route around it.

## 1. Detect how this project deploys
| Signal | Deploy path |
| --- | --- |
| `.github/workflows/*` that deploys on push/merge/tag, or the Vercel Git integration on the production branch | The pipeline is the source of truth: deploying = merging/pushing/tagging (with approval), then `gh run watch <id> --exit-status`. Don't bypass it with a manual deploy or add a CLI deploy that duplicates it. |
| `vercel.{json,toml,ts}` or `.vercel/project.json` | Vercel: use the vercel plugin's guidance (`vercel:deployments-cicd`, `vercel:vercel-cli`) for exact commands. Preview = `vercel deploy`. Production = stage a production build with `vercel deploy --prod --skip-domain`, verify that URL, then `vercel promote <url>`; or Rolling Releases if the project has them configured. |
| `fly.toml` | `fly deploy` (`[deploy] strategy`: canary/bluegreen need health checks and no volumes); migrations belong in `release_command` (runs once on the new image; a failure aborts the deploy). History `fly releases`; logs `fly logs`. |
| `wrangler.{jsonc,json,toml}` | `wrangler deploy`, or gradual: `wrangler versions upload` → `wrangler versions deploy` at a small percentage → 100%. `wrangler tail` for logs; `wrangler rollback`. |
| `railway.json` / `railway.toml` | `railway up`; `railway logs`. |
| `render.yaml` | Render deploys from git; trigger by pushing/merging or the deploy hook. |
| `compose.yaml` / Dockerfile + a remote host | Build and push an image tagged with the git SHA (never `latest`), record its digest, then on the host deploy that digest (`docker compose pull && docker compose up -d --wait`). |
If nothing matches, ask how the project is deployed. Don't guess.

## 2. Pre-flight (each must pass, or the user explicitly waives it)
- Clean tree, on the intended branch, pushed; deploying exactly the commit that was reviewed and is green in CI.
- Canonical checks green: lint, typecheck, tests, build (the `ship-check` skill, or the project's commands).
- Environment variables: list what the code needs (`.env.example`, config schema) and confirm each exists in the target environment (`vercel env ls`, `fly secrets list`, `wrangler secret list`, …), names only, never values. `NEXT_PUBLIC_*` values are baked in at build time.
- Database migrations: anything pending? Apply backward-compatible (expand) steps before the code that needs them, through the platform's release phase or CI, never from this machine against production. Destructive (contract) steps only after the new code is live, separately, and with approval. Never use data-loss flags.
- Record the rollback path now: the current production deployment ID/URL/image digest and the exact rollback command for this platform (Vercel instant rollback / `vercel rollback`, `fly deploy --image <previous>`, `wrangler rollback`, or revert + redeploy). Then ask: will that previous version still work against the schema and data this deploy leaves behind? If not, split the change (read new + write old first, write new later) or tell the user there is no clean rollback.
- Rollback triggers, decided now and not during the watch: e.g. error rate above the pre-deploy baseline (state the number), a critical flow failing, p95 latency doubling.
- Risky behavior changes go behind a feature flag where the project has them.

## 3. Deploy
Run the platform command non-interactively; capture the deployment URL/ID and the build log location. A failed build is a stop: show the first real error, don't retry with force flags.

## 4. Verify (before calling it done)
"Deployed" needs three proofs; exit code 0, "queued", or a passing dry run are not success:
1. The platform reports a terminal SUCCESS/READY state for **the exact deployment ID you created** (not a newer concurrent one). A timeout or dropped stream means the outcome is unknown: poll that deployment before retrying.
2. The live URL serves the new build: a version/health endpoint returns the commit SHA you shipped, or a marker unique to this change.
3. A bounded log scan after the switch (state the time window and line count you read), with no new errors.
Then:
- Health endpoint and the 2–3 most important routes: real HTTP status and a content check (`curl -sS -o /dev/null -w '%{http_code}'`, plus grep the body for an expected marker). A shallow `/ping` that skips the database proves little. Protected Vercel deployments return 401 to plain curl: use `vercel curl` or the `x-vercel-protection-bypass` header (`vercel:access-protected-vercel-deployment`).
- For UI changes, load the page and look (the `run` skill or a browser).
- Watch runtime logs/errors for at least 10 minutes after a production deploy and until real traffic has reached the new version (low-traffic apps: re-run the smoke checks at the end); compare the error rate with the window before the deploy.
- Staged production (Vercel `--skip-domain`, a Cloudflare partial percentage, a canary): verify the staged target first, then show a summary (what's deployed, checks run with results, rollback command) and get confirmation before promoting or moving traffic to 100%.

## 5. If verification fails
Stop. Show the evidence, propose the recorded rollback, and run it only with the user's go-ahead (unless they pre-authorized automatic rollback for this deploy). If users are affected, switch to the `incident` skill.

## 6. Report
URL and deployment ID, the commit/digest now serving, checks run with real results, migrations applied, rollback command, and anything left manual, under **Blocked on me / Changed / Found**.

## Gotchas
- Vercel previews are auto-`noindex`; production promotion is a separate, deliberate step. `vercel promote` is instant and keeps the artifact only for a deployment *built for production* (staged with `--prod --skip-domain`); promoting a preview-built deployment creates a new production build with production env vars. Env var changes take effect only on the next deployment.
- `vercel deploy --prebuilt` loses Vercel system env vars at build time, and Next.js Skew Protection with `--prebuilt` needs a custom deployment ID.
- Secret changes are deploys: `wrangler secret put`, `fly secrets set`, and similar create and roll out a new version immediately. `wrangler deploy` can also overwrite variables and routes set in the dashboard: reconcile first.
- Rolling back code does not roll back data, schema, or connected resources (Cloudflare rollback doesn't revert bindings, KV, or D1, and is blocked across Durable Object class changes). Plan migrations so the previous version still works.
- Fly's `immediate` strategy skips health checks: emergencies only.
- Check CLI flags with `--help` or current docs rather than memory, and never silently upgrade the platform CLI to make a command work.
- Don't deploy on top of an ongoing incident without the incident commander's OK.
- Never deploy uncommitted local changes to production, and never skip checks with `--force`/`--no-verify`-style flags.
