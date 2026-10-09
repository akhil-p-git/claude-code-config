---
description: "JavaScript and TypeScript standards"
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.mts"
  - "**/*.cjs"
  - "**/tsconfig*.json"
  - "**/package.json"
---

# JavaScript / TypeScript

## Types
- TypeScript in strict mode; for new projects also enable `noUncheckedIndexedAccess`. Never silence the compiler with `any`, `as any`, non-null `!`, or `@ts-ignore` — use `unknown` plus narrowing, or fix the type. (`@ts-expect-error` with a reason is acceptable in tests.)
- Model variants as discriminated unions; prefer string-literal unions or `as const` objects over `enum`.
- Use `satisfies` to type-check object literals without widening; `import type` for type-only imports.
- Validate untrusted data (request bodies, env, JSON files, LLM output) with Zod at the boundary and derive the type with `z.infer`.

## Runtime & Packages
- ESM (`"type": "module"`); `node:` prefix for built-ins. Node here is the fnm-managed LTS; prefer built-ins (global `fetch`, `node:test`, `--env-file`) over adding a dependency for them.
- Use the package manager the lockfile indicates (`pnpm-lock.yaml` → pnpm, `bun.lock*` → bun, `yarn.lock` → yarn, else npm); never mix managers or hand-edit a lockfile.
- Async: run independent work with `Promise.all`/`allSettled`; never leave a promise floating without handling rejection; pass an `AbortSignal` (`AbortSignal.timeout(ms)`) to network calls.

## Verify
- Type-check with the project's script or `tsc --noEmit`, then lint and tests. Run test runners in single-run mode (`vitest run`, `jest --ci`), never watch mode.
