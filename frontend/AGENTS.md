# Frontend Development Guide

> Code patterns and conventions for Ciridae UI development.

**For styling, theming, and visual design, see [STYLE_GUIDELINES.md](./STYLE_GUIDELINES.md).**

---

## 0. Code Style

### 0.0 File Ordering — Top-Down Readability

Files should read like a story: **highest-level (exported) functions and components first, lower-level helpers below.** A reader opening a file should immediately see the public API at the top, with implementation details further down.

```tsx
// Good — exported component first, helpers below
export function OverlaysCard() {
  return (
    <Card>
      <ModalDemo />
      <SheetDemo />
    </Card>
  )
}

function ModalDemo() { /* ... */ }
function SheetDemo() { /* ... */ }
```

```tsx
// ❌ Bad — helpers before the main export
function ModalDemo() { /* ... */ }
function SheetDemo() { /* ... */ }

export function OverlaysCard() {
  return (
    <Card>
      <ModalDemo />
      <SheetDemo />
    </Card>
  )
}
```

### 0.1 Querying the Backend

All calls to the backend should be made through a custom hook in `src/hooks/api/`.

* All api hooks should be prefixed with `use`.
* All api hooks should be built on top of the `useQuery` and `useMutation` hooks from `@tanstack/react-query`.
* All api hooks must use the `BackendClient` from `src/lib/BackendClient.ts` to make the calls.
* **All API response types must be defined as Zod schemas and parsed at runtime.** Do not use plain TypeScript types for API responses. Define a Zod schema, infer the TS type from it with `z.infer`, and call `.parse()` on the response data before returning it.
* **Keep the API contract camelCase end-to-end.** Backend JSON, frontend request payloads, and frontend response types should all use the same camelCase field names. Use Zod schemas (co-located with the hooks in `src/hooks/api/`) to validate the API data at runtime, not to translate between casing conventions.

```tsx
import { useQuery } from "@tanstack/react-query"
import { z } from "zod"
import BackendClient from "@/lib/BackendClient"

const ExampleResponseSchema = z.object({
  message: z.string(),
})

type ExampleResponse = z.infer<typeof ExampleResponseSchema>

const fetchExampleData = async (): Promise<ExampleResponse> => {
  const response = await BackendClient.get("/example")
  return ExampleResponseSchema.parse(response.data)
}

export const useExampleRoute = () => {
  return useQuery<ExampleResponse, Error, string>({
    queryKey: ["exampleData"],
    queryFn: fetchExampleData,
    select: (data) => data.message,
  })
}
```

### 0.2 PostHog Analytics

**IMPORTANT: All mutations MUST include PostHog capture events.**

* Every `useMutation` hook should capture an event in the `onSuccess` callback
* **Every mutation invalidates the queries it stales.** In the same `onSuccess`, call `queryClient.invalidateQueries` for every query key the mutation affects (or `setQueryData` with the response when a refetch is wasteful). Without this, components reading those queries keep showing the cached, pre-mutation data until an unrelated refetch happens.
* Import PostHog: `import { posthog } from "@/contexts"`
* Use descriptive event names like `user_created_post`, `user_updated_profile`, etc.
* Include relevant properties in the event data
* All events are automatically tagged with `project_id` and `environment` - do not add these manually

```tsx
import { useMutation, useQueryClient } from "@tanstack/react-query"
import BackendClient from "@/lib/BackendClient"
import { posthog } from "@/contexts"

export const useCreatePost = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => BackendClient.post("/posts", data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["posts"] })
      posthog.capture('user_created_post', {
        post_id: data.id,
        title_length: variables.title.length,
      })
    },
  })
}
```

### 0.3 Structure & Naming

- **One exported component or hook per file.** Don't grab-bag several into an `XComponents.tsx` or a multi-export module — split them. If you can't predict a file's contents from its name, that's the smell.
- **The file name answers "what does this do?"** and, for a single-export module, **matches the export**: `useLogUrlState.ts` exports `useLogUrlState`; `LogsList.tsx` exports `LogsList`. No subject-only names (`logEntry`), no pattern-labels (`viewModel`), no `utils`/`helpers`/`config` junk drawers.
- **Bake intent into the name.** If it takes a beat to see what something is for, rename it — e.g. put `default` in the name when it's the default value/segment.
- **Keep routers / config / index files thin** — split per route or per app so they don't bloat. Don't mix demo/example code into real shell code.

### 0.4 State & Data

- **React Query is the store for server state.** Never copy query data into `useState`, context, or a state library. Read it from the query hook where it is consumed, and change it only through mutations plus invalidation or `setQueryData`. For detailed React Query hook style guidance, see [react_query.md](./react_query.md).
- **Stop prop-drilling. Push data-fetching *down*, don't hoist it up.** The smell is a component with many props or `onX` callbacks threaded through 2–3 levels. Fetch where you consume — pass IDs down (`projectId`, `deploymentId`), not resolved state. React Query de-dupes identical query keys, so two components calling the same `useX(id)` share one request; fetching low is free.
- **A messy, bloated top-level component state is a red flag — decompose it.** Don't store everything at the top or bundle unrelated state into one blob. A modal owns its own open state; a create form owns its create state. Push feature hooks down into the components that use them.
- **The URL is global state — read it directly.** Filters and cursors live in `useSearchParams` (one thin hook per param); a component reads the filter via that hook instead of receiving `selected…` + `onToggle…` props. Source-of-truth order: URL (shareable filters/cursors) > React Query (server data) > minimal local UI state (open/hover). **No `useEffect`-synced local mirrors** of URL or server state.
- **Separate logic into small, single-concern hooks.** Break a god-hook into focused hooks; the page/controller hook stays a thin orchestrator that composes them and returns, with no logic inline.
- **Wrap involved logic in a named, documented custom hook** — a non-obvious `useEffect`, `IntersectionObserver`, or subscription doesn't sit inline in a component; it moves into a named hook whose docstring explains *what it does and why*.
- **No large `useEffect` — keep them under ~30 lines.** Effects are only for genuine subscriptions, intervals, observers, or imperative sync. Past ~30 lines, extract into a named hook, move derivation into `useMemo`/pure functions, and sync state into the URL or React Query instead of copying one piece of state into another.
- **Define every default exactly once.** Don't re-spell a default across nested layers, and don't add options/props that callers never pass.
- **Use the right platform primitive.** Scope event listeners to the component, not `window` (a window listener that calls `preventDefault` breaks sibling DOM). Use browser storage, not cookies, for UI state. Watch timezone correctness in rendered times.

### 0.5 Typing

- **`type` over `interface`.** Prefer inference and `as const satisfies T`, derive literal unions from their source, and **brand loose primitives** (`type ProjectId = string & { __brand: "ProjectId" }`) instead of passing a bare `string`. If you made a type, use it — don't fall back to `object` + casts.

### 0.6 Testing

Ciridae frontends are **zero-test by convention** — integration confidence comes from a browser smoke, not a render harness. Do **not** add a test toolchain (jsdom, snapshot, render harness) inside a feature PR; that's an owner decision and its own PR.

- **Test behavior, not implementation.** Tests that assert which functions were called, or that are mostly mocks, test implementation details — delete them.
- **Don't test trivial functions.** A test for a one-line formatter or a simple internal interface is noise.
- **A test should not be more complex than the code it covers.** If anything, test pure-logic units only (cursor math, encoding, dedupe) as plain `.ts` — no jsdom, no snapshots.

---

## 1. Component Architecture

```
src/components/
├── ui/           # Reusable primitives (Button, Input, Card, Modal)
├── layouts/      # App shell, navigation
└── features/     # Feature-specific (auth/, feedback/)
```

---

## 2. Start with Existing Components

Before building new UI:

1. Check `src/components/ui/` for existing primitives
2. If building new, use Ciridae UI registry components for complex behavior (modals, popovers, etc.)
3. Use CVA for variants, our semantic tokens for styling

**We use Ciridae UI through the shadcn registry.** Local primitives should follow the registry shape and use lowercase imports like `@/components/ui/button`.

**Installing a new Ciridae UI primitive:**
```bash
npx shadcn@latest add https://ciridae-ui.ciridae.app/r/button.json
```

**Adding components:**
- Reusable primitives → `ui/component-name.tsx`, export from `ui/index.ts` when needed
- Feature-specific → `features/[feature]/ComponentName.tsx`

---

## 3. Development Workflow

**Need a UI component?**

1. Check existing `ui/` components
2. If it exists, use it
3. If not, pull it from the Ciridae UI registry or build it using Radix (for behavior) + CVA (for variants) + our tokens (for styling)

**Example: Extending a primitive**

```tsx
import { Button } from "@/components/ui/button"

export function SubmitButton({ isLoading, children }) {
  return (
    <Button type="submit" disabled={isLoading} className="w-full">
      {isLoading ? "Loading..." : children}
    </Button>
  )
}
```

---

## 4. DO / DO NOT

**DO**
* Check existing components first
* Use semantic color tokens (see STYLE_GUIDELINES.md)
* Follow existing patterns in the codebase
* Use TypeScript types for all props and returns
* Use Zod schemas to define and runtime-parse all API responses

**DO NOT**
* Rebuild existing components from scratch
* Hardcode colors — use tokens (`bg-background`, not `bg-white`)
* Reintroduce Interface One token names (`bg-bg-default`, `text-content-default`, etc.)
* Skip PostHog events on mutations
* Use plain TypeScript types for API responses — always use Zod schemas with `.parse()`

---

## 5. Code Quality

### Linting & Type Checking

```bash
yarn lint              # ESLint
yarn typecheck         # TypeScript
yarn themecheck        # Theme contrast check
yarn lint && yarn typecheck  # Both
```

### What Gets Checked

**ESLint:** React hooks, TypeScript best practices, code consistency
**TypeScript:** Type errors, missing types, import errors

### Never Suppress Lint or Type Errors

Do not use `@ts-ignore`, `@ts-expect-error`, `eslint-disable`, or `any` to silence errors. It is almost never necessary. Instead, fix the underlying type issue:

1. **Use `satisfies`** instead of `any` to validate a value matches a type without widening it.
2. **Question the types** of inputs and outputs of the functions you're calling. The error often means a type upstream or downstream is wrong or too narrow — fix it there.
3. **As a last resort, add runtime guards** such as type-narrowing `is` functions or Zod `.parse()` / `.safeParse()` calls to prove the type at runtime. This is almost always preferable to silencing the compiler.

```tsx
// Bad — silencing the error
const result = someLibFn() as any // eslint-disable-line @typescript-eslint/no-explicit-any

// Good — satisfies to validate shape
const config = { theme: "dark", size: 4 } satisfies AppConfig

// Good — runtime guard to narrow an unknown type
function isUser(val: unknown): val is User {
  return typeof val === "object" && val !== null && "id" in val
}

// Good — Zod parse for untrusted data
const user = UserSchema.parse(response.data)
```

---

## 6. Docker Development

### Common Mistakes

* **New Dependencies Not Appearing After Rebuild:** Docker uses anonymous volumes for node_modules. If you add a dependency with `yarn add` and rebuild, the old volume persists. Fix by recreating anonymous volumes without dropping the database:
  ```bash
  # Recreate anonymous volumes (keeps named volumes like DB)
  docker-compose up --build -V frontend

  # Or remove just the frontend container's volumes
  docker-compose rm -v frontend && docker-compose up --build frontend
  ```
  Do NOT use `docker-compose down -v` as this drops all volumes including your database.

---

## 7. Quick Reference

```bash
# Linting
yarn lint && yarn typecheck

# List existing UI components
ls src/components/ui/
```

**Key files:**
- `src/index.css` — Tailwind v4 tokens and global styles
- `components.json` — Ciridae UI registry config
- `src/components/ui/index.ts` — UI component exports
- `src/hooks/api/` — API hooks
- `src/lib/BackendClient.ts` — Authenticated API client
- `src/contexts/` — Auth, Theme, PostHog providers
