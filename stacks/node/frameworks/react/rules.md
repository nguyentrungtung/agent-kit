# React rules

- Function components + hooks only. Rules of Hooks are law (add `eslint-plugin-react-hooks` to `eslint.config.mjs`).
- Components small and focused; one exported component per file; props typed with a `Props` type, no `React.FC`.
- State: local first, lift when shared, server state via TanStack Query/SWR (or Next server components) — never duplicate server data in global stores.
- Effects only to sync with external systems; derive values instead of `useEffect` + `setState`. Every effect cleans up.
- Lists need stable `key`s (ids, not indexes). Memoize (`useMemo`/`useCallback`/`memo`) only for measured problems.
- Accessibility: semantic HTML, labels for inputs, keyboard reachable, `alt` text (`eslint-plugin-jsx-a11y`).
- No `dangerouslySetInnerHTML` without sanitising (DOMPurify). No secrets in client bundles (only `VITE_*`/`NEXT_PUBLIC_*` public values).
- Tests: Testing Library — query by role/label, test behaviour not implementation.
