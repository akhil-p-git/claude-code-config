# UI review checklist

Pinned and condensed on 2026-10-08 from the Vercel Web Interface Guidelines (github.com/vercel-labs/web-interface-guidelines, AGENTS.md, MIT) and the impeccable craft floor (github.com/pbakaus/impeccable, Apache-2.0). Items already covered by `rules/accessibility.md` and `rules/web-frontend.md` are left out. Report findings as `file:line - problem - fix`, grouped by file, with no preamble.

## Forms and input
- MUST keep the submit button enabled until the request starts, then disable it and show a spinner while keeping its label.
- MUST NOT block paste in inputs or textareas.
- MUST accept free text and validate afterwards; allow submitting an incomplete form so validation can show.
- MUST put errors inline next to the field and focus the first error on submit.
- MUST trim input values; MUST warn before navigating away from unsaved changes.
- MUST submit with Enter in a single input; in a textarea, Cmd/Ctrl+Enter submits.
- MUST use `font-size` of at least 16 px on mobile inputs (prevents iOS zoom); NEVER disable browser zoom.
- SHOULD disable spellcheck for emails, codes, and usernames; placeholders end with `…` and show an example.
- MUST give checkboxes and radios one shared hit target with their label, with no dead zones.

## State, navigation, feedback
- MUST reflect filters, tabs, pagination, and expanded panels in the URL; Back and Forward restore scroll.
- MUST use links (`<a>`/`<Link>`) for navigation so Cmd/Ctrl/middle-click work.
- SHOULD update optimistically and roll back or offer Undo on failure.
- MUST confirm destructive actions or provide an Undo window.
- MUST leave no dead ends: every error and empty state offers a next step.
- MUST delay the first tooltip; neighboring tooltips open instantly.
- MUST set `overscroll-behavior: contain` in modals and drawers.

## Motion
- MUST animate only compositor-friendly properties (`transform`, `opacity`); NEVER `transition: all`.
- MUST make animations interruptible; autoplay only muted, non-essential loops, with pause controls if longer than 5 s.
- MUST set the correct `transform-origin`; SVG transforms go on a `<g>` with `transform-box: fill-box`.

## Layout and content
- MUST verify mobile, laptop, and ultra-wide (simulate ultra-wide at 50% zoom).
- MUST handle short, average, and very long user content: `truncate`, `line-clamp-*`, `break-words`, and `min-w-0` on flex children.
- MUST render empty strings and arrays without broken UI.
- MUST make skeletons mirror the final content so nothing shifts.
- MUST design empty, sparse, dense, and error states.
- MUST use `tabular-nums` for numbers that are compared; `Intl.DateTimeFormat` and `Intl.NumberFormat` for dates and numbers.
- SHOULD add `translate="no"` to brand names, code tokens, and identifiers.
- MUST use non-breaking spaces in `10&nbsp;MB`, `⌘&nbsp;K`, and brand names; the `…` character, not three dots.
- MUST keep `<title>` in sync with the current view.

## Visual detail
- SHOULD use layered shadows (ambient plus direct), with offset and blur; a zero-offset colored glow is decoration.
- SHOULD make nested radii concentric (child radius no larger than parent).
- SHOULD tint borders, shadows, and secondary text toward the background hue.
- MUST raise contrast on hover, active, and focus.
- SHOULD avoid banding in dark gradients.
- MUST theme the browser's own surfaces: selection color, caret, scrollbars, focus ring, link underline offset.
- MUST declare elevation once per surface (border or shadow, not a 1 px border under a wide soft shadow).

## Dark mode and theming
- MUST set `color-scheme: dark` on `<html>` for dark themes and a matching `<meta name="theme-color">`.
- MUST give native `<select>` explicit `background-color` and `color` (Windows renders them unreadable otherwise).
- SHOULD guard date and time rendering against hydration mismatches; inputs with `value` need `onChange` (or use `defaultValue`).

## Performance
- MUST virtualize long lists; MUST keep mutations (`POST`/`PATCH`/`DELETE`) under 500 ms or show progress.
- MUST preload the above-the-fold image and lazy-load the rest; prevent layout shift with explicit dimensions.
- SHOULD preload critical fonts with `font-display: swap` (or use `next/font`).
- SHOULD prefer `<video autoplay muted loop playsinline>` to animated GIFs, with a still fallback for reduced motion.
