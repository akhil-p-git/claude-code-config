---
name: a11y-audit
description: Run an accessibility audit (axe-core via Playwright) against a running local web app, plus a manual keyboard/focus/contrast checklist, aligned to WCAG 2.2 AA. Use when the user asks to audit or check accessibility (a11y) of a page, site, or component, or wants to find WCAG violations on a local URL.
---

# Accessibility Audit (WCAG 2.2 AA)

Audit a running local web app. Automated scanning catches only ~30–40% of issues, so the manual pass is required, not optional.

## 1. Get a URL
- A dev server must be running. If none is, start the app first (or use the `webapp-testing` skill) and get the URL, e.g. `http://localhost:3000/`.

## 2. Automated axe-core scan
```bash
node ~/.claude/skills/a11y-audit/scripts/a11y_audit.mjs <url>
```
- Requires Playwright (chromium). If missing: `npm i -D playwright && npx playwright install chromium`, or run inside the `webapp-testing` skill's environment.
- It injects axe-core (from CDN, no install) and prints violations grouped by impact (critical/serious/moderate/minor) with the rule id, affected selectors, and a help URL. A clean scan is a floor, not a pass.

## 3. Manual checks (axe cannot catch these)
- **Keyboard only**: Tab through the whole page — every interactive element reachable, in logical order, with a visible `:focus-visible` ring; no keyboard traps.
- **Focus management**: modals trap + restore focus and close on Esc; SPA route changes move focus to the new heading.
- **Forms**: every input has a real `<label>`; errors are in text and linked via `aria-describedby`; focus moves to the first error on submit.
- **Target size**: interactive targets ≥ 24×24 CSS px (WCAG 2.2 2.5.8).
- **Color**: information not conveyed by color alone; contrast ≥ 4.5:1 text, 3:1 large text / UI.
- **Motion**: honors `prefers-reduced-motion`.

## 4. Report
- List violations by severity with the file/selector and a concrete fix, citing the WCAG criterion. The `accessibility` rules file has the criteria reference.
