---
description: "React and Next.js performance and best practices"
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React Best Practices

Full reference: @knowledge/react-best-practices.md

## CRITICAL
- `Promise.all()` for independent async operations (2-10x faster)
- `next/dynamic` for heavy components (reduces bundle size)
- Avoid barrel file imports (use direct imports or `optimizePackageImports`)

## HIGH
- `React.cache()` for server-side request deduplication
- SWR/React Query for client-side data deduplication
- `<Suspense>` boundaries for non-blocking data loading
- Pass only needed fields across RSC boundaries, not entire objects

## MEDIUM
- Extract expensive work to memoized components with `React.memo()`
- Narrow effect dependencies to primitives, not objects
- Lazy state initialization: `useState(() => expensive())`
- Hoist static JSX outside components

## Avoid
- Sequential awaits when operations are independent
- Object/array deps in useEffect when primitives suffice
- `{count && <Badge />}` (renders "0") — use `{count > 0 ? <Badge /> : null}`
