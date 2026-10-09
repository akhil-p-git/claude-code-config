---
name: ui-craft
description: Systematic UI craft for React, Next.js, Tailwind v4, and shadcn/ui. Sets up and enforces design tokens (type scale, spacing, color roles, radius, elevation, motion), designs every component state (hover, focus, active, disabled, loading, empty, error), checks responsive and dark mode, writes interface copy, and removes the 2026 "AI default" look. Use when building, restyling, or reviewing any page, component, form, dashboard, or landing page, when a UI looks generic or AI-made, or when asked to polish a UI or make it production-ready. For aesthetic direction on new marketing surfaces, use the frontend-design plugin first.
argument-hint: "[component-or-route | review <path>]"
---

# UI craft

The `frontend-design` plugin (install: `/plugin install frontend-design@claude-plugins-official`) chooses a direction. This skill is the floor every screen clears and the system that keeps screens consistent. Accessibility criteria live in `rules/accessibility.md` and CSS mechanics in `rules/web-frontend.md`; don't restate them, apply them.

## 1. Name the surface before designing

- **Operate** (app, dashboard, settings, admin, tools): scanability and consistency beat expression. Start from the shadcn token baseline and put the brand in precise details: one accent, the typeface, radius, icon set. Pick one density per page.
- **Persuade** (landing, pricing, launch page): open with the most characteristic thing in the product's world. Run `frontend-design` for direction if it's installed, then come back here for the floor.
- **Read** (docs, blog, changelog): text column of 60 to 75 characters, generous leading, a clear heading scale, little chrome.

Choose light or dark from where and when the product is used, not from its category.

## 2. Load or create DESIGN.md

- If the repo has a `DESIGN.md` (Google's format: YAML tokens plus prose), read it first and follow it. The user's brief overrides it; it overrides your habits.
- If it doesn't and the task creates or restyles UI, write one before writing components: 4 to 6 named colors with semantic roles, one or two typefaces with roles, type scale, spacing scale, radius, elevation, motion tokens, three to five principles, and a Do's and Don'ts list naming the defaults you're avoiding. Start from [references/design-md-template.md](references/design-md-template.md).
- Validate with `npx @google/design.md lint DESIGN.md` (structure, broken token references, WCAG contrast of component color pairs).
- Mirror the tokens in Tailwind v4 `@theme` and the shadcn CSS variables. Components use semantic tokens only (`bg-background`, `text-muted-foreground`, `bg-primary`). No raw hex and no arbitrary `[13px]` values in components; a one-off needs a comment saying why.
- shadcn defaults are a baseline, not a design: change at least the typeface, base hue, accent, and radius (`npx shadcn@latest init --preset <code>` or edit the variables) so the app doesn't read as the stock template.
- For component APIs and composition, follow the shadcn skill (the official one from shadcn-ui/ui, `pnpm dlx skills add shadcn/ui`, or the vercel plugin's): semantic color tokens, `flex gap-*` instead of `space-*`, `FieldGroup`/`Field` forms, `Empty` for empty states, `Skeleton` for loading, `Spinner` inside buttons rather than a loading prop, a title on every dialog and sheet.

## 3. Type

- One family, or two that clearly differ (for example a serif display with a sans UI face). Self-host with `next/font`. On Persuade surfaces, don't reach for the faces every generated page uses (Inter, Geist, Space Grotesk, a high-contrast serif display with italic accents) unless the brief asks; Geist or Inter are fine for Operate surfaces.
- Pick a ratio and stay on it. Product UI around 1.2 (12, 14, 16, 20, 24, 30); marketing 1.25 to 1.333 with display sizes of 48 to 96 px. Map steps to `--text-*` tokens and never invent a size between steps.
- Body 16 px (14 px is acceptable in dense tables and sidebars), line-height 1.5 to 1.6 for body and 1.1 to 1.25 for headings, measure 60 to 75 characters (`max-w-prose`).
- Tighten only display text (-0.01 to -0.03 em). Don't track body text. Uppercase only for short labels, with about +0.05 em tracking, and not above every heading.
- Build hierarchy with weight and color before size. One card shows at most three sizes and two weights.
- `text-balance` on headings, `text-pretty` on paragraphs, `tabular-nums` wherever numbers are compared, the `…` character for truncation and loading text.

## 4. Space, layout, shape

- 4 px base. Use one subset: 4, 8, 12, 16, 24, 32, 48, 64, 96 px (Tailwind 1, 2, 3, 4, 6, 8, 12, 16, 24). Comfortable density uses `gap-6 p-6`; compact uses `gap-4 p-4`. Don't mix them on one page.
- Space inside a group is smaller than space between groups. Leave more space above a heading than below it.
- Group with spacing and background shifts before reaching for borders. Declare elevation once per surface: a border or a shadow, not both.
- Radius comes from one scale. Nested radius equals the outer radius minus the padding. Cards 8 to 16 px; pills only for small controls such as badges and chips.
- Keep a z-index scale in tokens. Use `h-dvh`, not `h-screen`; respect `env(safe-area-inset-*)` on fixed bars; give truncating flex children `min-w-0`.

## 5. Color

- Build a neutral ramp of 8 to 10 steps tinted slightly toward the brand hue, one primary ramp, and semantic colors (success, warning, danger, info), each with an on-color. Work in OKLCH and step lightness; lower chroma at the extremes.
- Components reference roles, not hues: background, card, muted, border, input, ring, foreground, muted-foreground, primary, primary-foreground, accent, destructive.
- One accent per view. Secondary text on a colored surface is tinted from that surface's hue, never plain gray.
- Contrast: body text 4.5:1, large text and UI parts 3:1, checked in both themes. Hover, active, and focus raise contrast; they never lower it.
- Where a state has no designed color, overlay the on-color at 8% for hover, 10% for focus and pressed, 16% for dragged; disabled content sits at 38% opacity (Material 3 state layers).
- Charts get a color-blind-safe palette and never rely on color alone; use the `dataviz` skill.

## 6. Every component, every state

| State | Requirement |
|---|---|
| Hover | Only under `@media (hover: hover)`; a visible but small change |
| Focus | `:focus-visible` ring, 2 px with offset, 3:1 against its background |
| Active | Immediate feedback: `scale(0.97)` or a darker fill |
| Disabled | Explain why nearby when it isn't obvious; prefer `aria-disabled` when the control must stay focusable |
| Loading | Keep the label and width, add a spinner, disable only after the request starts; skeletons mirror the final layout |
| Empty | One sentence on what belongs here and one primary action to create it |
| Error | What failed, why if known, how to fix it, and a retry; shown next to the field or action |
| Success | Confirm with the same verb as the action ("Publish" leads to "Published") |
| Extremes | One item, a thousand items, a 60-character name, missing image, RTL text |

- Data views keep filters, sort, and page in the URL, restore scroll on Back, and virtualize past a few hundred rows.
- Forms: labels above inputs, helper text before errors, validate on blur and submit (not every keystroke), never block paste, correct `type`, `inputmode`, and `autocomplete`. Destructive actions use an `AlertDialog` or an Undo window. Warn before discarding unsaved changes.

## 7. Motion

- Animate to show cause and effect, keep spatial continuity, or confirm a state change. Anything used many times a day (command palette, keyboard shortcuts, list navigation) doesn't animate.
- Durations: press 100 to 160 ms; tooltip and popover 125 to 200 ms; dropdown 150 to 250 ms; modal and drawer 200 to 300 ms (up to 500 ms for large sheets). Exits run faster than entrances.
- Easing tokens in `@theme`: `--ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1)` for enter and exit, `--ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1)` for movement on screen. Never ease-in for UI.
- Animate `transform` and `opacity` only, never `transition: all`. Enter from `scale(0.95)` with `opacity: 0`, never from `scale(0)`. Popovers scale from their trigger (`transform-origin: var(--radix-popover-content-transform-origin)` or equivalent); modals scale from the center. Tooltips wait on first hover and open instantly on neighbors.
- On Persuade surfaces, spend motion on one orchestrated moment, not a fade-up on every section and a lift on every card. Under `prefers-reduced-motion: reduce`, use a fade or nothing.

## 8. Responsive

- Design at 360 px first; check 360, 768, 1024, 1440, and an ultra-wide width where content width and line length must stay capped.
- Touch targets at least 44 px on touch devices (24 px is the WCAG floor); inputs at least 16 px on mobile so iOS doesn't zoom.
- Pages change layout at breakpoints; components adapt with container queries.
- On small screens, tables become stacked rows or scroll horizontally with a sticky first column; navigation moves into a `Sheet`.

## 9. Dark mode

- Tune a separate palette instead of inverting. Elevated surfaces get lighter, not more shadowed. Derive the dark background from the brand hue rather than defaulting to a neutral #0B0B0B or #111.
- Lower the chroma and raise the lightness of accents in dark mode; re-check every contrast pair.
- Set `color-scheme` on `<html>`, a `theme-color` meta per theme, and apply the theme before first paint (next-themes or an inline script) so there's no flash.
- Theme the browser's own surfaces in both modes: text selection, caret, scrollbars, focus ring, link underline offset.

## 10. Words in the interface

- Name things by what users get, not how the system works: "Notifications", not "Webhook config".
- Buttons say verb plus object ("Create project", "Save changes"), and the same verb carries through the flow.
- Errors say what happened and how to fix it, include the bad value, and don't apologize or say "Oops". Empty states invite the first action. Sentence case everywhere. Format numbers and dates with `Intl`. Options that open a follow-up end with `…` ("Rename…").
- Check new copy against `~/.claude/rules/writing.md`.

## 11. Avoid the generic AI look

Unless the brief asks for it, don't ship: a cream background (near #F4F1EA) with a serif display and terracotta accent (near #D97757); a near-black page with one neon accent; broadsheet hairlines with zero radius as a default; a grid of identical icon-heading-text cards with the same soft shadow; a gradient wash behind everything; a tracked uppercase eyebrow above every heading; 01/02/03 numbering on things that aren't a sequence; one italic or colored word in the headline; the hero made of a big number, a small label, three stats, and a gradient; monospace used as a "technical" costume; an arrow appended to every link; "A · B · C" meta strings; gradient text; glass cards; colored left-border callouts; purple-to-indigo gradients; emoji as icons; pill-shaped primary buttons everywhere.

Generic instructions like "avoid the AI look" swap one default for another, so name what you avoid. Before coding, write the plan (tokens plus an ASCII layout) and ask whether you'd produce the same plan for any similar prompt; change any axis where the answer is yes. After the first render, list which of the patterns above appeared, remove them, and add them to DESIGN.md's Don'ts.

## 12. Verify once, thoroughly

1. Grep the diff for raw values that should be tokens: `#[0-9a-fA-F]{3,8}\b`, `\[[0-9.]+(px|rem)\]`, `transition-all`, `h-screen`.
2. Look at the rendered result: desktop and mobile, both themes, in one batch. For anything beyond a small tweak, hand the rendered review to the `ui-reviewer` agent (it drives the screens, runs the a11y-audit scan and keyboard checks, and forces loading, empty, and error states); otherwise screenshot it yourself with whichever browser tool is available.
3. Fix everything found in one batch, confirm with one more round, and stop. Report what you checked and what you couldn't.

Review checklist: [references/checklist.md](references/checklist.md).

Sources: Anthropic frontend-design skill (2026-09), Anthropic prompting guide for Opus 5.5, Vercel Web Interface Guidelines, vercel plugin shadcn skill, pbakaus/impeccable craft floor, emilkowalski/skills, ibelick/ui-skills baseline-ui, Google DESIGN.md spec, Tailwind v4.3 theme defaults, Material 3 state tokens.
