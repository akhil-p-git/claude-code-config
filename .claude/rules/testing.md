---
description: "Testing standards for all languages"
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
  - "**/test/**"
  - "**/__tests__/**"
---

# Testing Standards

## Strategy
- Follow the Testing Trophy, not the classic pyramid: static analysis (TypeScript, ESLint) at the base, then unit, then a HEAVY integration layer, then a thin E2E cap.
- Optimize for confidence-to-cost: integration tests give the best ROI; most real bugs live at boundaries between units/services.
- Write tests at the highest level that stays fast and reliable. "The more your tests resemble the way your software is used, the more confidence they give you."
- Use TDD for complex logic, algorithms, and bug fixes (write the failing test first); skip it for throwaway prototypes.

## Tools
- Default to Vitest for unit/integration (ESM-native, shares Vite config, parallel); use Jest only on existing Jest codebases.
- Use Playwright for E2E and (via browser mode) component tests in real Chromium/Firefox/WebKit; prefer it over jsdom for complex UI.
- Query Testing Library and Playwright by accessible role + name (`getByRole('button', { name: /save/i })`), then label/text; never `getByTestId` or `querySelector` unless nothing else works.
- Drive interactions with `@testing-library/user-event`, never `fireEvent`; await async elements with `findBy*`, never `waitFor(() => getBy*)`.
- Mock network with MSW at the network level; never monkey-patch `fetch`/`axios`. Reuse handlers across tests, dev, and Storybook.

## Reliability
- Structure every test as Arrange-Act-Assert; assert one behavior per test.
- Make tests isolated and order-independent: no shared mutable state, reset MSW handlers and mocks in `afterEach`.
- Ban arbitrary sleeps (`waitForTimeout`, `setTimeout`): rely on Playwright auto-waiting and web-first assertions (`await expect(locator).toBeVisible()`).
- Use test-data factories/fixtures instead of duplicated inline setup; keep data deterministic (freeze clocks, seed randomness).
- Assert with semantic matchers from `@testing-library/jest-dom` (`toBeDisabled`, `toBeInTheDocument`), not raw property checks.

## Coverage & Quality
- Treat coverage as a guide, not a goal; do not chase 100% — high coverage with weak assertions catches nothing.
- Run mutation testing (Stryker) on core business logic to verify tests actually kill bugs; start with critical modules.
- Require effectively 100% on security-critical and money-handling logic (auth, authz, payments, validation).
- For services, add consumer-driven contract tests (Pact) and gate deploys with `can-i-deploy`.

## Accessibility & Visual
- Run automated a11y checks with `axe-core`/`jest-axe` (`expect(await axe(container)).toHaveNoViolations()`); treat it as a floor (~30%), not a substitute for manual audits.
- Keep snapshots small and intentional; prefer inline snapshots, review every diff — never blind-update with `-u`.
- Use pixel visual-regression (Playwright `toHaveScreenshot`) for layout-critical UI; pin OS/browser versions for determinism.

## CI & Feedback
- Run unit/integration on every push; shard E2E across CI jobs (`--shard`) for fast parallel feedback.
- Enable Playwright `retries` only in CI with `trace: 'on-first-retry'`; investigate every retry — flakiness is a defect, not noise.
- Keep the fast suite under a few minutes; fail the build on new a11y violations and dropped coverage thresholds.
