# Blameless postmortem — template and rules

Sources: Google SRE book ch. 15 + Appendix D, SRE Workbook ch. 10, Lunney et al. "Postmortem Action Items" (;login: 2017), PagerDuty postmortem guide, Atlassian handbook, Allspaw ("The Infinite Hows"), Etsy debriefing guide, Howie guide, incident.io (2026).

## When one is required
User-visible impact beyond a trivial blip · any data loss · any rollback or emergency intervention · resolution time past expectations · a monitoring failure (users found it before alerts did). "An unreviewed postmortem might as well never have existed."

## Template
```markdown
# Postmortem: <title> (INC-YYYYMMDD-NN)
Status: Draft | In review | Final – actions open | Closed      Severity: SEV-1/2/3
Owner: <one person>   Responders (by role): …   Incident date: …   Published: …
Times (UTC): impact start · detected · mitigated · resolved  → time to detect / time to resolve
Change-related?: yes/no — deployment / commit / PR

## Summary
2–3 sentences: what users saw, for how long, how it was mitigated.

## Impact
Quantified: users or requests affected (%), duration, features/routes, support tickets, SLO budget consumed.
Data loss or corruption: YES/NO (always state it).

## Timeline (UTC)
Start in the lead-up, before impact. Facts only, no judgment.
| Time | Event | Evidence (link / command) |
Markers: LEAD-UP · IMPACT STARTS · DETECTED · MITIGATED · RESOLVED

## Detection
How we found out (alert / user report / luck). How could detection time have been cut in half?

## Response and recovery
What was tried, what worked, what slowed us down. Was a generic mitigation (rollback, flag) available, and was it used?

## Trigger
The (usually innocuous) event that activated latent conditions.

## Contributing factors
2–5 conditions that had to be true for this to happen or to be this bad — technical, process, tooling, and what made the response harder. No names. No single "root cause".

## Lessons learned
### What went well
### What went wrong or was difficult
### Where we got lucky (near misses)

## Recurrence check
Was this known or deferred? Links to similar past incidents ("incidents that rhyme").

## Action items
| # | Action (verb-first, bounded) | Category: Detect / Mitigate / Prevent / Repair / Process | Priority P0–P2 | Owner | Due | Ticket | Status |
Decided NOT to do (and why):

## Supporting information
Links to dashboards, logs, PRs, chat — link, don't paste.

## External message (if users were affected)
Summary · What happened · What we're doing about it
```

## Blameless language
| Don't | Do |
| --- | --- |
| Name people ("Alice ran the script") | Roles: "the deployer", "the on-call engineer" — including the user |
| "Root cause: human error" | The conditions: "the script had no rate limit; the runbook was out of date" |
| "Why did you deploy on Friday?" | "What did you expect the deploy to do? How did it make sense at the time?" |
| "should have" / "could have" | What was known and visible at each moment, written forward in time |
| "careless", "ridiculous", "!!!" | Neutral, verifiable data: "error rate 38% for 22 min" |
| "outage" for a partial failure | "degradation affecting 12% of checkout requests" |
| "Train engineers not to run X" | "Add a confirmation and a blast-radius cap to X" |

Fix systems, not people: "trying to change human behavior is less reliable than changing automated systems and processes" (SRE Workbook).

## Action items
1. Actionable, specific, bounded: starts with an outcome verb (add, remove, change, test, deploy), has a verifiable end state. Reject "improve", "review", "investigate further", "be more careful".
2. One owner, a due date, and a real ticket (for a solo dev: a GitHub issue labelled `postmortem`).
3. Prioritize by risk: P0 = high risk of unmitigated recurrence; P1 = medium; P2 = low. Every user-visible incident gets at least one P0 or P1.
4. Cover at least one each of detect, mitigate-future, prevent (plus repair if data was damaged).
5. Prefer automation and generic mitigations (rollbacks, flags, guards) over procedures.
6. Balance quick fixes with one strategic item; also shorten detection and recovery, not only eliminate the trigger.
7. Few, real items; record the decisions not to act.
8. Learning before fixing: agree the timeline and contributing factors first; write action items last (or a day later).

## Quality bar for the fresh-context review
Impact quantified and data-loss stated · timeline evidenced and in UTC · contributing factors are conditions, not people · each action item owned, dated, ticketed, verifiable · at least one P0/P1 for user-visible incidents · readable by someone who wasn't there ("postmortems are letters you write to future team members"). Publish within about a week.
