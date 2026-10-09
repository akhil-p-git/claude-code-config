---
name: deploy
description: Deploy the current project with pre-flight checks, a rollback path recorded before deploying, and post-deploy verification. Auto-detects Vercel, Fly.io, Cloudflare (wrangler), Railway, Render, Docker Compose hosts, or a CI deploy workflow. Run only when the user invokes /deploy.
argument-hint: "[preview|production] [notes]"
disable-model-invocation: true
---

# Deploy

Arguments: `$ARGUMENTS`. Default target is **preview**. Production needs the word "production" from the user in this conversation and a final confirmation of the summary in step 4.

## 1. Detect how this project deploys
| Signal | Deploy path |
| --- | --- |
| `.github/workflows/*` that deploys on push/merge/tag | The pipeline is the source of truth: deploying = merging/pushing/tagging (with approval), then `gh run watch`. Don't bypass it with a manual deploy. |
| `vercel.json` or `.vercel/project.json` | Vercel — use the vercel plugin's guidance (`vercel:deployments-cicd`, `vercel:vercel-cli`) for exact commands; preview = `vercel deploy`, production = `vercel deploy --prod` or promoting a verified preview. |
| `fly.toml` | `fly deploy`; history `fly releases`; logs `fly logs`. |
| `wrangler.toml` / `wrangler.jsonc` | `wrangler deploy` (or `wrangler versions upload` + gradual `versions deploy`); `wrangler tail` for logs; `wrangler rollback`. |
| `railway.json` / `railway.toml` | `railway up`; `railway logs`. |
| `render.yaml` | Render deploys from git; trigger by pushing/merging or the deploy hook. |
| `compose.yaml` / Dockerfile + a remote host | Build and push an image tagged with the git SHA (never `latest`), then pull/restart on the host. |
If nothing matches, ask how the project is deployed — don't guess.

## 2. Pre-flight (each must pass, or the user explicitly waives it)
- Clean tree, on the intended branch, pushed; deploying exactly what was reviewed.
- Canonical checks green: lint, typecheck, tests, build (the `ship-check` skill, or the project's commands).
- Environment variables: list what the code needs (`.env.example`, config schema) and confirm each exists in the target environment (`vercel env ls`, `fly secrets list`, `wrangler secret list`, …) — names only, never values. Remember `NEXT_PUBLIC_*` values are baked in at build time.
- Database migrations: anything pending? Apply backward-compatible (expand) steps before the code that needs them; destructive (contract) steps only after the new code is live and with approval. Never use data-loss flags.
- Record the rollback path now: the current production deployment ID/URL/release and the exact rollback command for this platform (Vercel instant rollback / `vercel rollback`, `fly deploy --image <previous>`, `wrangler rollback`, or revert + redeploy).
- Risky behavior changes go behind a feature flag where the project has them.

## 3. Deploy
Run the platform command non-interactively; capture the deployment URL/ID and the build log location. A failed build is a stop — show the error, don't retry with force flags.

## 4. Verify (before calling it done)
"Deployed" needs three proofs — exit code 0, "queued", or a passing dry run are not success:
1. The platform reports a terminal SUCCESS/READY state for **the exact deployment ID you created** (not a newer concurrent one). A timeout or dropped stream means the outcome is unknown: poll that deployment before retrying.
2. The live URL serves the new build: a version/health endpoint returns the commit SHA you shipped, or a marker unique to this change.
3. A bounded log scan after the switch (state the time window and line count you read), with no new errors.
Then:
- Health endpoint and the 2–3 most important routes: real HTTP status and a content check (`curl -sS -o /dev/null -w '%{http_code}'`, plus grep the body for an expected marker). A shallow `/ping` that skips the database proves little.
- For UI changes, load the page and look (the `run` skill or a browser).
- Watch runtime logs/errors for 5–10 minutes after a production deploy; compare the error rate to before.
- Production deploys: show a summary (what's deployed, checks run with results, rollback command) and get confirmation before promoting or switching traffic.

## 5. If verification fails
Stop. Show the evidence, propose the recorded rollback, and run it only with the user's go-ahead (unless they pre-authorized automatic rollback for this deploy). If users are affected, switch to the `incident` skill.

## 6. Report
URL and deployment ID, checks run with real results, migrations applied, rollback command, and anything left manual — under **Blocked on me / Changed / Found**.

## Gotchas
- Vercel previews are auto-`noindex`; production promotion is a separate, deliberate step (`promote` re-points the production alias instantly without rebuilding — promote the preview you verified). Env var changes take effect only on the next deployment.
- Secret changes are deploys: `wrangler secret put`, `fly secrets set`, and similar create and roll out a new version immediately.
- Rolling back code does not roll back data, schema, or connected resources — plan migrations so the previous version still works.
- Check CLI flags with `--help` or current docs rather than memory, and never silently upgrade the platform CLI to make a command work.
- Don't deploy on top of an ongoing incident without the incident commander's OK.
- Never deploy uncommitted local changes to production, and never skip checks with `--force`/`--no-verify`-style flags.
