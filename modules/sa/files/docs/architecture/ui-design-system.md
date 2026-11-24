# UI design system — <system>
<!-- Owned by kit-sa (§5) when the product has a UI. BA defines WHAT each screen shows (wireframes + 4 states in the stories);
     this file defines HOW it looks and behaves. The Full-stack Developer uses only these tokens/components — no ad-hoc colours,
     spacing or one-off components. Change a token here first, then in code (tokens file path below). -->

## 1. Stack
| Concern | Choice | Why (ADR) |
|---|---|---|
| UI framework | | |
| Component library | <shadcn/ui · MUI · Ant Design · own> | |
| Styling | <Tailwind · CSS modules · …> | |
| Server state | <TanStack Query · SWR · framework loader> | |
| Client state | <none / Zustand / Redux> — only for state that is not server data | |
| Forms & validation | <react-hook-form + zod · …> — schemas aligned with the generated API types | |
| i18n | | |
| Tokens file in code | <frontend/src/shared/ui/tokens.css · tailwind.config> | |

## 2. Design tokens
| Token | Light | Dark | Use |
|---|---|---|---|
| color.primary | | | primary actions, links |
| color.danger | | | destructive actions, errors |
| color.success / warning / info | | | feedback |
| color.bg / surface / border | | | layout |
| color.text / text-muted | | | text (contrast ≥ 4.5:1 on bg) |
| font.family · size scale | | | e.g. 12/14/16/20/24/32 |
| space scale | | | e.g. 4/8/12/16/24/32 |
| radius · shadow | | | |

## 3. Breakpoints & layout
Mobile < 640px · Tablet < 1024px · Desktop ≥ 1024px. Navigation pattern per breakpoint: <…>.

## 4. Standard states (every data view)
| State | Component | Rule |
|---|---|---|
| Empty | `<EmptyState>` | illustration/text + primary action |
| Loading | `<Skeleton>` / button spinner | no layout shift; disable submit while pending |
| Error | field errors + `<Alert>`; RFC 9457 `detail` mapped to a message | retry where safe |
| Success | toast / inline confirmation / redirect | |

## 5. Accessibility (WCAG 2.1 AA)
Semantic HTML first · visible focus ring · full keyboard path · labels for every input · `aria-live` for async messages ·
contrast ≥ 4.5:1 · checked by eslint-plugin-jsx-a11y + Playwright/axe in e2e.

## 6. Component inventory
| Component | Variants | Status (planned / built) | Where |
|---|---|---|---|
