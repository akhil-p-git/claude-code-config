---
description: "Web accessibility (WCAG 2.2 AA) standards"
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.html"
  - "**/*.vue"
  - "**/*.svelte"
---

# Accessibility (WCAG 2.2 AA)

## Semantic HTML & ARIA
- Use native elements first: `<button>`, `<a href>`, `<nav>`, `<select>`, `<input>`. First rule of ARIA: don't add ARIA if a native element with the needed semantics exists.
- Never put click handlers on `<div>`/`<span>` for actions — use `<button>`. Links navigate (`<a>`), buttons act.
- Don't override native semantics (no `role="button"` on `<a>`). Don't apply `aria-hidden="true"` to focusable elements.
- One `<h1>` per page; never skip heading levels (h2→h4). Use headings for structure, not styling.
- One `<main>`; wrap regions in `<nav>`, `<header>`, `<footer>`, `<aside>`. Label duplicate landmarks with `aria-label`.
- Every control needs an accessible name (visible text, `aria-label`, or `aria-labelledby`). Icon-only buttons require `aria-label`.

## Keyboard & Focus
- All interactive elements must be reachable and operable by keyboard (Tab/Enter/Space/Arrows). No keyboard traps (2.1.2).
- Provide visible focus styling via `:focus-visible`; never `outline: none` without a replacement. Keep 3:1 contrast on indicators.
- Focus Not Obscured (2.4.11, AA): focused element must not be fully hidden by sticky headers/footers or overlays.
- Tab order must follow visual/reading order; avoid positive `tabindex`. Use `tabindex="-1"` for programmatic focus targets only.
- Modals: trap focus inside while open, set initial focus, restore focus to the trigger on close, close on `Esc`.
- SPA route changes: move focus to the new view's heading or a focusable container and announce it.
- Add a skip-to-content link as the first focusable element.

## Pointer & Target Size
- Target Size Minimum (2.5.8, AA): interactive targets ≥ 24×24 CSS px, OR ≥ 24px spacing between centers. Inline text links are exempt.
- Dragging Movements (2.5.7, AA): any drag operation needs a single-pointer alternative (tap/click) unless dragging is essential.
- Don't rely on hover-only or path-based gestures; provide click/tap equivalents.

## Forms
- Associate every input with a `<label for>` (or wrap it). Placeholder is not a label.
- Mark required fields with `required`; expose errors with `aria-invalid="true"` and link messages via `aria-describedby`.
- Errors must be specific, in text (not color-only), and programmatically tied to the field; move focus to the first error on submit.
- Use `autocomplete` tokens (`name`, `email`, `current-password`, `one-time-code`) for identity/contact fields.
- Redundant Entry (3.3.7, A): don't ask users to re-enter info already provided in the same process.
- Accessible Authentication (3.3.8, AA): never require a cognitive function test. Allow paste, password managers, and OTP autofill.

## Color, Media & Motion
- Contrast: 4.5:1 normal text, 3:1 large text (≥24px or ≥18.66px bold) and UI components/icons/meaningful graphics (1.4.3, 1.4.11).
- Never convey information by color alone — pair with text, icons, or patterns (1.4.1).
- Meaningful images need descriptive `alt`; decorative images use `alt=""` (empty, not omitted). Don't start alt with "image of".
- Video needs synchronized captions; audio needs a transcript. Don't autoplay; provide pause controls.
- Respect `@media (prefers-reduced-motion: reduce)` — remove/limit non-essential animation, parallax, auto-advancing carousels.

## Dynamic Content & Testing
- Announce async updates with live regions: `aria-live="polite"` for status, `role="alert"` for errors. Region must exist in DOM before content changes.
- Reflect state with `aria-expanded`, `aria-selected`, `aria-pressed`, `aria-current`; keep them in sync with UI.
- Consistent Help (3.2.6, A): keep contact/help links in the same relative place across pages.
- Test with axe-core / eslint-plugin-jsx-a11y in CI, keyboard-only navigation, and a screen reader (NVDA, VoiceOver). Automated tools catch only ~30–40%; manual testing is required.
