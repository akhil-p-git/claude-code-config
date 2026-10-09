# Tracking plan

Track to answer decisions, not to collect data. Every event maps to a question someone will act on. The plan is a contract between product and engineering: exact triggers, typed properties, owners.

## 1. Questions and metrics
- List the 5–10 questions the founder must answer (e.g., "Which channel brings users who activate?", "Where do signups drop?", "Do users of feature X retain better?").
- **North Star**: the metric that best captures value delivered to customers and leads revenue (e.g., weekly projects with ≥ 1 successful run), plus 3–5 **input metrics** the team can move directly.
- **Activation**: a specific action within N days that predicts retention — a hypothesis until cohort data confirms it. **Retention**: one definition (e.g., weekly active), kept stable.
- Funnel: acquisition → activation → retention → revenue → referral, each entered through one defining event.

## 2. Naming (pick one convention, write it down, enforce it in code)
- PostHog style: lowercase snake_case, `category:object_action`, present-tense verbs from a fixed allowlist (`view`, `click`, `submit`, `create`, `delete`), e.g. `signup_flow:pricing_page_view`; version a redesigned flow (`signup_v2:…`).
- Segment style: "Object Action" in past tense (`Order Completed`). Don't mix styles.
- Never build names dynamically; put variables in properties (`page_view` + `page_name`).
- Properties: `object_adjective` (`plan_price`), booleans `is_`/`has_`, times `_at`/`_timestamp`, money as integer minor units + `currency`.
- Keep a provider's reserved names when using its recommended events (GA4 `sign_up`, `login`, `purchase`).
- Limits: GA4 event names ≤ 40 characters, ≤ 25 parameters per event, parameter values ≤ 100 characters, 25 user properties. Vercel Web Analytics custom events: Pro/Enterprise plans only, flat properties (string/number/boolean/null), names, keys, and values ≤ 255 characters, property count limited by plan.

## 3. Triggers and identity
- Write the exact trigger: "form submitted successfully (server returned 201)", not "user clicks Submit".
- Use your own stable user id as the distinct id (never an email); call `identify` at signup and login so pre-login events link; `reset` on logout; group analytics (company/workspace) for B2B; one id format across client and server ("user-456" ≠ "USER-456").
- Flag internal and test users (`is_internal`, dev hosts) and filter them out of every dashboard.

## 4. Where events come from
- **Server-side for truth**: account created, subscription started/renewed/canceled, payment failed (from Stripe webhooks), AI task completed (model, tokens, latency, cost as properties). Ad blockers can't drop these.
- **Client-side for UX**: page views, CTA clicks, form steps. Proxy the client SDK through your own domain (e.g., a Next.js rewrite to `/ingest`) to reduce blocking.
- **Attribution**: on the first visit capture `utm_*`, referrer, and landing page; persist them to the user record at signup. UTM values lowercase, from a documented list.
- **LLM features**: never put raw prompts or outputs containing personal data into analytics; log a data class (e.g., "contains user document"), sample traces, and set retention.

## 5. Consent and privacy (EU/UK; not legal advice)
- ePrivacy Art. 5(3) covers more than cookies: EDPB Guidelines 2/2023 include pixel and URL tracking, IP-based tracking, and unique identifiers. Being in scope doesn't always mean consent; check the exemptions.
- France (CNIL): audience measurement can skip consent only if it serves the publisher alone, produces anonymous statistics, doesn't cross-match or track people across sites, uses cookies ≤ 13 months, and keeps data ≤ 25 months.
- UK (Data (Use and Access) Act 2025; ICO guidance finalized 2026-04-29): analytics purely to understand and improve the service can run without consent if you give clear information and a simple, free way to object, and any third-party tool acts as your processor; it doesn't cover advertising.
- Google Ads / GA4 for EEA users: Consent Mode v2 (`ad_user_data`, `ad_personalization`); you must collect consent to keep measurement and remarketing.
- Cookieless tools (Plausible; PostHog `cookieless_mode`) reduce consent needs, but "no banner needed" is the vendor's position, not a guarantee. Decide per jurisdiction.
- No personal data (emails, names) in event properties; document each event's purpose and lawful basis.

## 6. Implement
Generate a typed catalog so wrong events fail at compile time:
```ts
// src/lib/analytics/events.ts
import { z } from "zod";
export const events = {
  "signup_flow:account_create": z.object({ method: z.enum(["email", "github", "google"]) }),
  "project:create": z.object({ template: z.string().nullable() }),
  "billing:subscription_start": z.object({ plan: z.string(), interval: z.enum(["month", "year"]), amount_minor: z.number().int(), currency: z.string() }),
} as const;
export type EventName = keyof typeof events;
export type EventProps<E extends EventName> = z.infer<(typeof events)[E]>;
// track<E extends EventName>(name: E, props: EventProps<E>): validate in dev/test, forward to the provider in prod.
```
Server events go through a separate `trackServer()` called from webhooks and server actions. Document every event in `docs/analytics/tracking-plan.md`:
| Event | Question it answers | Exact trigger | Properties (type, example) | PII? | Source (client/server) | Owner |

## 7. QA
Verify in the tool's live or debug view (PostHog activity, GA4 DebugView) with a flagged test user; unit-test the `track` wrapper; after deploy, compare event counts to the database (signups in the DB vs. signup events — a gap means loss or double-firing); then build three views: the funnel, a retention cohort, and the North Star trend.

## Gotchas
- Client-only signup or purchase events undercount (ad blockers, closed tabs); record money and identity events on the server.
- Renaming an event silently breaks every funnel built on it; version instead.
- Autocapture is not a tracking plan; it misses server outcomes and creates unnamed noise.
- Session-replay and heatmap tools record form fields; mask inputs and exclude sensitive pages.

Sources (checked 2026-10-08): posthog.com/docs/product-analytics/best-practices · support.google.com/analytics/answer/9267744 (GA4 limits) · vercel.com/docs/analytics/custom-events · edpb.europa.eu Guidelines 2/2023 · cnil.fr audience-measurement exemption (2025-07-04) · ico.org.uk storage-and-access exceptions (2026-04-29) · developers.google.com/tag-platform/security/guides/consent · plausible.io/data-policy · posthog.com/docs/privacy/data-collection.
