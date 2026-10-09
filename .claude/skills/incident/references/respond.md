# Live incident response — first-hour checklist

Sources: Google SRE book ch. 12/14 and Workbook ch. 9; PagerDuty incident response docs; Atlassian incident handbook.

## Operating rules
- The human is the **Incident Commander (IC)**; the agent is **investigator (SME) + scribe**. Diagnose read-only until the IC approves a specific mitigation. "Do not perform any actions unless the Incident Commander has told you to do so." (PagerDuty)
- One change at a time, announced before and logged after. Uncoordinated "freelancing" fixes made incidents "far worse" (SRE ch. 14).
- Priorities, in order: **stop the bleeding → restore service → preserve evidence → root cause** ("Ignore that instinct!" to root-cause first — SRE ch. 12).
- "Making the 'wrong' decision is better than making no decision" (PagerDuty) — but prefer reversible mitigations.

## T+0–5 min — declare and set up
- Is it an incident? Yes if users see it, a second party/team is needed, or it's unsolved after ~1 hour. In doubt: declare, and assume the higher severity.
- Severity guide: SEV1 = down for all / data loss / security breach; SEV2 = down for a subset or core feature broken; SEV3 = minor, workaround exists.
- Start a timeline (UTC): `HH:MM — event — evidence link/command`.

## T+5–15 — assess impact (read-only)
- What do users see? All or some (routes, regions, plans)? Since when? Any data loss or security angle?
- Golden signals: latency (track error latency separately), traffic, errors, saturation. Check dependency status pages.

## What changed? (check in this order)
1. Deploys: recent production deployments (`vercel ls` / deployment events, image tags), `git log --since=<time>` on the deployed branch, diff from the last known-good release.
2. Config: env vars, feature flags, `next.config.*`, `vercel.json`, middleware/proxy, rewrites.
3. Dependencies: lockfile diff, base image, runtime version.
4. Data: migrations, backfills, cron jobs that ran.
5. Platform: DNS, TLS certificate expiry, domains, CDN/cache invalidation.
6. Credentials and limits: rotated/expired secrets or API keys, quotas, billing, rate limits.
7. External: third-party incidents, traffic spikes, abuse/attacks.
8. Time-based triggers: month/quarter end, DST change, TTL or token expiry.

Preserve evidence before restarts or rollbacks: logs, deployment IDs, error samples, screenshots.

## T+10–20 — mitigate (with IC approval)
Generic mitigations, cheapest first: roll back / promote the previous good deployment · disable the feature flag · revert the config/env change · scale up or shed load · block abusive traffic · fail over · maintenance page. You need to know *where* the problem is, not the full *why*. Rollback restores code, not data: before rolling back across a migration or a stored-format change, check that the previous version can read the current schema and data.

On Vercel: read-only tools (list deployments, deployment events, runtime logs/errors) are free to use; rollback/promote changes production and needs the IC's go-ahead (enforced: `permissions.ask` covers the Vercel MCP write tools and `guard-prod-actions.sh` covers the CLI).

## Communication
- First status note within ~5 minutes; then updates every 20–30 minutes, each with the time of the next update.
- State unknowns plainly ("root cause currently unknown"). The final note confirms recovery and says explicitly whether any data was lost.

## T+20–60 — verify and loop
- Exit criterion: metrics back within SLO for ~30 minutes. If not recovered, go back to "assess impact" with what you've learned.
- Escalate early; don't play hero. If stuck for 30+ minutes, say so and propose the next escalation.

## Close
- Resolved when user-facing impact has ended. Record time to detect (impact start → detected) and time to resolve (impact start → resolved).
- Revert any temporary changes made during response, or list them as follow-ups.
- Create the postmortem skeleton immediately (see `postmortem.md`).

## Data loss or corruption
Stop writes first (maintenance mode, revoke the writer, pause the job). Snapshot or dump the current state before ANY recovery step, even a damaged one. Restore into a NEW database or instance and compare; never run recovery commands against the only copy (in anthropics/claude-code#27063 the tables that survived the wipe were dropped during recovery attempts). Ask the provider early: point-in-time recovery, or a snapshot you can't see yourself (AWS support found one in the DataTalks.Club incident). Say plainly what is lost and what is recovered.

## Security incidents
Stop the attack, cut the vector, isolate affected systems (don't delete — forensics needs them), rotate credentials, and keep communication private until the IC decides otherwise.
