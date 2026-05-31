---
description: "Modern CSS and web UI best practices"
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.html"
  - "**/*.vue"
  - "**/*.svelte"
---

# Modern CSS & Web UI

## Layout & Architecture
- Use `@container` size queries for component-level responsiveness; set `container-type: inline-size` on the parent and query the component, not the viewport.
- Reach for `:has()` for parent/sibling state (e.g. `.card:has(img)`, `form:has(:invalid)`) instead of JS class toggling.
- Use `subgrid` (`grid-template-columns: subgrid`) so cards/forms share parent track alignment.
- Use native CSS nesting (no Sass needed); keep nesting shallow (max 2-3 levels) and use `&` explicitly.
- Organize the cascade with `@layer reset, base, components, utilities;` declared up front; this kills specificity wars and removes the need for `!important`.
- Prefer logical properties: `margin-inline`, `padding-block`, `inset`, `border-inline-start` over physical `left/right` for RTL support.

## Design Tokens & Color
- Define tokens as custom properties under `:root`; reference with `var()`. Scope component tokens locally.
- Use `oklch()`/`oklab()` for perceptually uniform colors; generate variants with relative color syntax: `oklch(from var(--brand) calc(l - 0.1) c h)`.
- Use `color-mix(in oklch, var(--brand) 80%, white)` for tints/shades instead of hardcoding hex.
- Use `light-dark(#fff, #111)` plus `color-scheme: light dark` for theming; honor `prefers-color-scheme` and never hardcode dark values.
- Fluid type/space with `clamp(min, preferred-vw, max)`; avoid fixed px breakpoint jumps.

## Motion & UX
- Use the View Transitions API for state/page transitions; assign `view-transition-name` and style `::view-transition-*`. Provide a progressive-enhancement helper.
- Use CSS scroll-driven animations via `animation-timeline: scroll()` / `view()` with `animation-range`; gate behind `@supports` (Firefox lags).
- Always gate motion: wrap non-essential animation in `@media (prefers-reduced-motion: no-preference)`.
- Apply `content-visibility: auto` + `contain-intrinsic-size` to long off-screen sections for render perf.

## Images & Performance
- Always set explicit `width`/`height` (or `aspect-ratio`) on `<img>`/media to prevent CLS.
- Serve AVIF then WebP then JPEG via `<picture>`; use `srcset` + `sizes` for resolution switching.
- Add `loading="lazy"` + `decoding="async"` to below-the-fold images; never lazy-load the LCP/hero.
- Mark the LCP image `fetchpriority="high"` (and `loading="eager"`); preload it if needed.

## Semantics & Hygiene
- Use semantic landmarks (`header`, `nav`, `main`, `article`, `footer`), real `<button>`/`<a>`, and labeled form controls over `<div>` soup.
- Ship a modern reset: `box-sizing: border-box`, `margin: 0`, `text-wrap: balance` on headings, `text-wrap: pretty` on body copy; place it in `@layer reset`.
- Avoid `!important`; resolve conflicts with cascade layers and lower specificity. Use `:where()` to add selectors at zero specificity.
- Tailwind v4: configure via CSS-first `@theme { --color-*, --font-*, --spacing-* }` and `@import "tailwindcss";` — drop `tailwind.config.js` and `@tailwind` directives.
