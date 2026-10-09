---
name: incident
description: Production incident handling — live response (impact, what changed, mitigate, status updates) and blameless postmortems with owned action items; also SLO burn-rate alerting design. Use when something is broken or degraded in production, a deploy needs rolling back, the user asks for an RCA, postmortem, or incident review, after any data loss, or when designing alerts/SLOs.
argument-hint: "[respond|postmortem|alerting] <what happened>"
---

# Incident

Pick the mode from `$ARGUMENTS` or context: something is broken right now → **respond**; it's over → **postmortem**; designing alerts/SLOs → **alerting**.

## Respond (live)
Read `references/respond.md` and follow its first-hour checklist. The non-negotiables:
- The user is the Incident Commander; you are the investigator and scribe. Diagnose **read-only** until the user approves a specific mitigation. Announce each change before making it, one change at a time, and log it.
- Mitigate before root-causing: if you know *where* the problem is (a recent deploy, a flag, a config change), propose the generic fix — roll back / promote the previous deployment, turn the flag off, revert the config. Customers need the errors to stop; the full "why" can wait.
- Start from "what changed?" (deploys, config/env, dependencies, migrations, certs/DNS, quotas, third parties, traffic). Preserve evidence (logs, deployment IDs) before restarts.
- Keep a running UTC timeline in the conversation (or `incident-<date>.md` if long). It becomes the postmortem.

## Postmortem
Read `references/postmortem.md` (template, blameless-language rules, action-item rules). Then:
1. Build the timeline from evidence first (git log, deploy history, logs, alerts, chat) — facts with UTC times and links; no judgments yet.
2. Quantify impact (who, how many, how long, data loss yes/no, SLO budget used).
3. Name the trigger and 2–5 contributing factors (conditions that had to be true) — not a single "root cause", never a person.
4. Write action items last: verb-first, owned, dated, ticketed, covering detect / mitigate / prevent.
5. Draft to `docs/postmortems/YYYY-MM-DD-<slug>.md` (or where the repo keeps them), then have a fresh-context reviewer check it against the template's quality bar.

## Alerting / SLOs
Read `references/slo-alerting.md` (multiwindow burn-rate table, page-vs-ticket rules, low-traffic caveats).

## Gotchas
- Don't run destructive "fixes" (deleting data, force-pushing, recreating infrastructure) under time pressure — they turned recoverable incidents into data loss in several 2025–26 agent incidents.
- "Human error" is never a root cause; refer to people by role ("the deployer"), including the user.
- A postmortem with only "be more careful" / "improve monitoring" items has failed — every item needs a verifiable end state.
- Always state explicitly whether any data was lost or corrupted, even when the answer is no.
