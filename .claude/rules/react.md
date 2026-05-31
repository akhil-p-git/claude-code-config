---
description: "React 19 and Next.js App Router best practices"
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React & Next.js Best Practices

## Server vs Client Components
- Default to Server Components; add `'use client'` only for interactivity, browser APIs, or hooks (useState/useEffect/event handlers).
- Keep client boundaries small and at the leaves; push `'use client'` down, not onto layouts/pages. Wrap interactive widgets, not whole trees.
- Fetch data in Server Components and pass it to Client Components as serializable props; never pass functions, live Date objects, or class instances across the boundary.
- Never import server-only secrets/DB clients into client modules; mark server-only files with `import 'server-only'`.
- Don't pass entire DB rows to the client — project only the fields the UI renders to avoid leaking server data.

## React 19 Idioms
- Pass `ref` as a normal prop; do NOT use `forwardRef` (deprecated). Render `<Context value={x}>`, not `<Context.Provider>`.
- Use `useActionState(action, initial)` for form mutations; read pending via its 3rd return value or `useFormStatus().pending` in child submit buttons.
- Use `useOptimistic` for instant UI feedback during async mutations; reconcile on resolve.
- Read promises/context in render with `use()` (callable conditionally); render it under a `<Suspense>` boundary.
- Render `<title>`/`<meta>`/`<link>` inline in components — React 19 hoists them to `<head>`; no react-helmet.
- Do NOT add manual `useMemo`/`useCallback`/`React.memo` when the React Compiler is enabled — let it memoize. Keep them only for referential stability third-party APIs require.

## Next.js Caching & Rendering (15/16)
- Assume `fetch` and GET Route Handlers are uncached by default; opt in explicitly with `'use cache'` on functions/components/pages.
- Tune cached entries with `cacheLife` profiles and `cacheTag`; invalidate via `revalidateTag`, and use `updateTag` inside Server Actions for read-your-writes.
- With Cache Components, PPR is on by default: build a static shell and wrap dynamic/per-request parts in `<Suspense>` to stream them.
- Never cache user-specific or auth-gated data globally; key it per user or keep it dynamic.

## Server Actions Security
- Treat every `'use server'` action as a PUBLIC POST endpoint: authenticate AND authorize the caller inside the action — page-level redirects do not protect it.
- Validate every input with a Zod (or equivalent) schema before use; never trust client-supplied IDs without ownership checks.
- Centralize mutation auth/DB logic in a server-only Data Access Layer; keep actions thin. Rate-limit sensitive actions.

## Data Fetching & Streaming
- Avoid request waterfalls: kick off independent requests together with `Promise.all` (or hoist fetches) instead of sequential `await`s.
- Move fetches into the components that need the data and wrap each in `<Suspense>` so slow sections don't block the page.
- Do NOT fetch data in `useEffect` for initial render — fetch in Server Components or use Server Actions/`use()`.

## Performance
- Optimize for INP (< 200ms; it replaced FID), LCP (< 2.5s), CLS (< 0.1).
- Use `next/image` with explicit width/height and `priority` on the LCP image; use `next/font` to self-host fonts and prevent layout shift.
- Avoid barrel files; import directly from submodules and set `optimizePackageImports` for icon/UI libs (lucide-react, @mui, etc.).
- Use `next/dynamic` (with `ssr: false` only when needed) to defer heavy/client-only components and cut bundle + hydration cost.
