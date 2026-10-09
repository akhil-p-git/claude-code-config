# DESIGN.md template (Google design.md format, alpha)

Put `DESIGN.md` at the product root. Tokens in the YAML front matter are normative; the prose explains how to apply them. Sections are optional, but the ones present must keep this order: Overview, Colors, Typography, Layout, Elevation & Depth, Shapes, Components, Do's and Don'ts. Unknown sections (such as Motion below) are preserved by the tooling. Spec: https://github.com/google-labs-code/design.md (`npx @google/design.md spec`).

Replace every value below with choices made for this product. The example describes a personal-finance dashboard; it is not a default.

```markdown
---
version: alpha
name: Tallyho
description: Personal finance dashboard for freelancers tracking invoices and tax set-asides.
colors:
  ink: "oklch(0.22 0.02 200)"
  paper: "oklch(0.985 0.004 200)"
  # slate, line, and amber are optional supporting colors: reference them from components or delete them (the design.md linter warns on orphaned tokens).
  slate: "oklch(0.55 0.02 200)"
  line: "oklch(0.90 0.01 200)"
  primary: "oklch(0.53 0.12 160)"
  on-primary: "oklch(0.99 0.01 160)"
  amber: "oklch(0.78 0.15 75)"
  danger: "oklch(0.58 0.19 25)"
  on-danger: "oklch(0.99 0.01 25)"
typography:
  display:
    fontFamily: Newsreader
    fontSize: 48px
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: -0.02em
  heading:
    fontFamily: Newsreader
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
  figure:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
    fontFeature: '"tnum" 1'
rounded:
  sm: 6px
  md: 10px
  lg: 14px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: 10px 16px
    height: 40px
  button-danger:
    backgroundColor: "{colors.danger}"
    textColor: "{colors.on-danger}"
    rounded: "{rounded.sm}"
  card:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: 24px
---

## Overview
Calm, ledger-like, and exact. Numbers are the content, so type and alignment do the work and color is reserved for money that needs attention. Surfaces are Operate mode: dense tables, quiet chrome, one accent.

## Colors
- Ink and paper carry 90% of the interface; both are tinted toward the slate-teal hue.
- Primary (a kelp green) is the only accent: primary actions and "paid" status. Amber marks money due within 7 days. Danger is for overdue amounts and destructive actions only.
- Secondary text uses slate; on kelp or danger surfaces use the matching on-color, never gray.

## Typography
- Newsreader for page titles and the balance figure; IBM Plex Sans for everything else.
- Every amount uses the figure style (tabular numerals), right-aligned in tables.
- Scale: 14, 16, 20, 24, 32, 48 px. No sizes in between.

## Layout
- 4 px base; spacing tokens only. Tables use compact density (8/16), forms comfortable density (16/24).
- Content max width 1200 px; text columns 65 characters.

## Elevation & Depth
- Cards are separated by background and spacing, not shadows. Popovers and dialogs use one shadow token; nothing else casts a shadow.

## Shapes
- Radius sm for controls, lg for cards and dialogs. Nested radius = outer minus padding. No pills except status badges.

## Components
- Primary button: primary (kelp), label style, 40 px tall; one per view.
- Status badge: text plus icon; color never carries status alone.
- Empty table: one sentence and a "Create invoice" button.

## Do's and Don'ts
- Do show every amount with its currency and tabular numerals.
- Do confirm destructive actions with an AlertDialog that names the invoice.
- Don't use gradients, glass, or colored left borders on cards.
- Don't add uppercase eyebrow labels above headings or number sections 01/02/03.
- Don't animate table rows or anything opened from a keyboard shortcut.

## Motion
- Enter: 200 ms, exit: 150 ms, cubic-bezier(0.23, 1, 0.32, 1). Movement on screen: 240 ms, cubic-bezier(0.77, 0, 0.175, 1).
- Reduced motion: fades only.
```

## Mirror the tokens in Tailwind v4 and shadcn

```css
@import "tailwindcss";

:root {
  --background: oklch(0.985 0.004 200);
  --foreground: oklch(0.22 0.02 200);
  --muted-foreground: oklch(0.55 0.02 200);
  --border: oklch(0.90 0.01 200);
  --primary: oklch(0.53 0.12 160);
  --primary-foreground: oklch(0.99 0.01 160);
  --destructive: oklch(0.58 0.19 25);
  --ring: oklch(0.53 0.12 160);
  --radius: 0.625rem;
}

.dark {
  --background: oklch(0.20 0.02 200);   /* derived from the brand hue, not #111 */
  --foreground: oklch(0.95 0.01 200);
  --muted-foreground: oklch(0.72 0.02 200);
  --border: oklch(0.32 0.02 200);
  --primary: oklch(0.70 0.10 160);      /* lighter, lower chroma in dark mode */
  --primary-foreground: oklch(0.18 0.02 160);
  --destructive: oklch(0.68 0.15 25);
  --ring: oklch(0.70 0.10 160);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-muted-foreground: var(--muted-foreground);
  --color-border: var(--border);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-destructive: var(--destructive);
  --color-ring: var(--ring);
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: var(--radius);
  --radius-lg: calc(var(--radius) + 4px);
}

@theme {
  --font-display: "Newsreader", ui-serif, Georgia, serif;
  --font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif;
  --ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1);
  --ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1);
}
```

Load fonts with `next/font` and pass their CSS variables into `--font-display` and `--font-sans`. Lint the file with `npx @google/design.md lint DESIGN.md` (exit 1 on errors). To generate the theme instead of writing it by hand: `npx @google/design.md export --format css-tailwind DESIGN.md > theme.css`. Compare versions with `npx @google/design.md diff DESIGN.md DESIGN-next.md`.
