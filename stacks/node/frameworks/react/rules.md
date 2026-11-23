# React rules

- Function components + hooks only. Rules of Hooks are law (add `eslint-plugin-react-hooks` to `eslint.config.mjs`).
- Components small and focused; one exported component per file; props typed with a `Props` type, no `React.FC`.
- State: local first, lift when shared, server state via TanStack Query/SWR (or Next server components) — never duplicate server data in global stores.
- Effects only to sync with external systems; derive values instead of `useEffect` + `setState`. Every effect cleans up.
- Lists need stable `key`s (ids, not indexes). Memoize (`useMemo`/`useCallback`/`memo`) only for measured problems.
- Accessibility: semantic HTML, labels for inputs, keyboard reachable, `alt` text (`eslint-plugin-jsx-a11y`).
- No `dangerouslySetInnerHTML` without sanitising (DOMPurify). No secrets in client bundles (only `VITE_*`/`NEXT_PUBLIC_*` public values).
- Tests: Testing Library — query by role/label, test behaviour not implementation.

## UI / UX & accessibility (WCAG 2.2 AA)
- Every screen handles **loading, empty, error and success** states; no blank screens, no raw error dumps.
- Design tokens (colour, spacing, typography) from one theme source; no hard-coded colours/sizes in components.
- Responsive from 360 px; touch targets ≥ 24×24 px; visible focus; colour contrast ≥ 4.5:1 (text).
- Forms: label per input, inline validation messages tied with `aria-describedby`, errors announced; never rely on colour alone.
- Text through i18n keys (no hard-coded UI strings) when the product has more than one locale.
- E2E: Playwright for the main journey of every user story with UI, plus an axe accessibility scan (`kit-run e2e`; example in `.agent/stack/node/snippets/`).
