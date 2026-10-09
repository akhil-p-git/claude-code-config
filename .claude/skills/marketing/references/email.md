# Email: lifecycle, launch, newsletter, cold outreach

Email is the owned channel that compounds. Each email has one job and one call to action, is triggered by what the user did or didn't do, and stops when the job is done. Claude drafts and configures; the user approves every send.

## 1. Lifecycle design
- Triggers come from product events (`product` skill → `tracking-plan.md`): signed up; not activated after 24 h; activated; hit a limit; trial ends in 3 days; payment failed; inactive 14/30 days; canceled.
- Default onboarding (tune to time-to-value): **#0 immediately** welcome + the single first step (deep link) · **#1 day 1, only if not activated** remove the most common blocker · **#2 day 3** one use case with a real example · **#3 day 5–7** proof (a permissioned customer story) or the key feature · **#4 trial end − 3 days** what they've done, what they keep or lose, plan choice · **#5 after converting** one power-user tip.
- Exit when the goal event fires; suppress anyone already in another sequence or who contacted support in the last 48 h.
- Dunning: the payment provider's retry schedule plus 3 emails (failed, reminder, final notice), each with a one-click link to update the card; no threats.
- Keep transactional mail (receipts, password resets, security alerts) on a separate stream and subdomain from marketing, so marketing complaints never delay a password reset. Under CAN-SPAM the "primary purpose" decides which is which, and "transactional" is read narrowly: a receipt stuffed with promotions can become commercial.
- Per-email spec: name, trigger, delay, exit condition, subject + preview text, body, CTA → URL with UTMs, the metric it should move.

## 2. Copy
Subjects: clear over clever; no fake "Re:"/"Fwd:", no all caps, no clickbait, no em dashes; plain lowercase is fine. Preview text completes the subject. Open with the reason you're writing — never "I hope this email finds you well", "Just checking in", or "Feel free to reach out". One ask, a real name in the signature, short paragraphs, at most one button, a plain-text part. Tells list: `copy-and-cro.md`.

## 3. Law (not legal advice; flag edge cases for review)
- **US — CAN-SPAM** (commercial email, B2B included): accurate header information; no misleading subject lines; disclose clearly that the message is an ad (unless the recipient opted in); a valid physical postal address; a clear way to opt out that works for at least 30 days after the send; honor opt-outs within 10 business days, with no fee and no data beyond the email address; never sell or transfer opted-out addresses; you stay liable for vendors who send for you. Up to $53,088 per violating email (the 2026 inflation adjustment was cancelled, so 2025 levels apply).
- **UK — PECR**: marketing email to individuals (including sole traders and some partnerships) needs specific consent, except the soft opt-in for existing customers who bought or negotiated to buy a similar product, with a simple opt-out offered at collection and in every message. Corporate addresses can be emailed without consent but still need an opt-out. The Data (Use and Access) Act 2025 added a charity soft opt-in; the ICO's PECR guidance is being revised for it.
- **EU — ePrivacy + GDPR**: prior consent for marketing email to individuals, with a similar soft opt-in for existing customers; B2B rules vary by country (Germany is strict); GDPR Art. 21 gives an absolute right to object to direct marketing.
- **Canada — CASL**: express or implied consent (implied lasts 2 years after a purchase, 6 months after an inquiry); identify the sender; the unsubscribe link must stay valid for 60 days and requests are honored within 10 business days; penalties up to $1M for individuals and $10M for organizations.
- Confirm each subscriber's address (double opt-in); Google's sender guidelines recommend it and say not to buy lists. Never add scraped GitHub or LinkedIn contacts to marketing sequences.

## 4. Deliverability
- **All senders to Gmail** (since 2024-02-01): SPF or DKIM, valid forward and reverse DNS, TLS, RFC 5322-formatted messages, and a user-reported spam rate under 0.3% in Postmaster Tools (aim below 0.1%).
- **Bulk senders** (Gmail: anyone who has sent close to 5,000 messages a day to personal Gmail accounts, counted across subdomains — once reached, permanently bulk): SPF and DKIM and DMARC (at least `p=none`) with the From: domain aligned to SPF or DKIM; one-click unsubscribe for marketing mail (RFC 8058: `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click`; transactional mail excluded) honored within 2 days (Google recommends 48 hours); a visible unsubscribe link in the body. Since November 2025 Gmail has been ramping up enforcement with temporary (4.7.x) and permanent (5.7.x) rejections.
- **Yahoo**: the same SPF + DKIM (keys ≥ 1024 bits) + aligned DMARC, RFC 8058 one-click unsubscribe honored within 2 days, spam rate under 0.3%.
- **Outlook.com / Hotmail / Live**: since 2025-05-05, domains sending over 5,000 messages a day need SPF, DKIM, and DMARC; non-compliant mail goes to junk, then gets rejected.
- **Opens are unreliable**: Apple Mail Privacy Protection preloads pixels, and Apple clients account for most opens (Litmus, July 2026). Judge emails by clicks, replies, and downstream product events.
- New domain or IP: warm up gradually, mail engaged recipients first, remove hard bounces immediately and long-unengaged contacts after 90–180 days.

## 5. Cold outreach (B2B, 1:1 only)
- Only role-relevant business contacts with a specific reason to write. CAN-SPAM applies in the US. In the UK you can email corporate addresses with an opt-out, but individuals and sole traders need consent; in the EU check the recipient's country.
- Send from a separate domain or subdomain with SPF/DKIM/DMARC, warmed for weeks; low daily volume per mailbox (practitioner guides suggest tens, not hundreds; Google Workspace caps each user at 2,000 messages a day); plain text; one link at most; keep bounces low; disable open tracking (EDPB guidance treats tracking pixels as access to the device under ePrivacy Art. 5(3)).
- Shape: an observation about them → the problem it implies → one proof → a low-friction ask ("Worth a look?"). Don't open with "I"/"We"; first email ~3 sentences with no links. 2–4 follow-ups, each adding something new; stop on any reply or opt-out; include an opt-out line and postal address.
- Don't automate LinkedIn: its User Agreement (effective 2025-11-03) bans bots and automated messaging and can restrict or terminate the account.

## 6. Launch emails and newsletters
Launch: the subject names the thing and the outcome; 3 bullets of what's new, one screenshot, one CTA. Newsletter: one main story, 2–3 links, a steady cadence; re-permission dormant lists before mailing them.

## Implementation
Developer-friendly senders: Resend (+ React Email), Postmark (separate transactional and broadcast streams), Loops (SaaS lifecycle), Customer.io (event-driven), Kit (newsletters), Amazon SES (cheapest; you own deliverability). Trigger from server-side product events; keep consent and unsubscribe state in your own database as the source of truth, synced to the sender.

## Output
`docs/marketing/email/<sequence>.md`: the sequence map (trigger → emails → exit), each email's spec and copy, a compliance checklist, and target metrics.

## Gotchas
- A marketing email sent from the transactional stream to unsubscribed users breaks CAN-SPAM and burns the reputation that password resets depend on.
- DMARC passes only if SPF or DKIM aligns with the visible From: domain; "SPF passes" for your ESP's domain isn't alignment.
- Purchased, scraped, or "enriched" lists produce spam complaints that sink the whole domain; don't.

Sources (checked 2026-10-08): ftc.gov CAN-SPAM compliance guide · OMB M-26-11 (2026 penalty adjustment cancelled) · ico.org.uk PECR electronic-mail marketing + DUAA updates · laws-lois.justice.gc.ca (CASL) · support.google.com/a/answer/81126 and /14229414 · senders.yahooinc.com/best-practices · Microsoft Outlook.com postmaster (May 5, 2025) · litmus.com/email-client-market-share · knowledge.workspace.google.com (sending limits) · EDPB Guidelines 2/2023 · linkedin.com/legal/user-agreement. Detailed notes: research/I-sub-platform-legal.md.
