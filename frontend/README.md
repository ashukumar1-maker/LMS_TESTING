# Fullstack Template Frontend

React 19 + TypeScript + Vite 8 frontend for Ciridae fullstack applications. The visible starter UI is intentionally blank and protected by Ciridae Auth; future product UI should be pulled from Ciridae UI.

## Stack

- React 19
- React Router 7
- Tailwind v4 through `@tailwindcss/vite`
- Ciridae UI shadcn registry
- Firebase/Ciridae Auth
- TanStack Query
- PostHog and Sentry

## Development

```bash
yarn install
yarn dev
```

The Docker Compose service serves the frontend at `http://localhost:3000` unless a `wt` workspace remaps the port.

## Ciridae UI

`src/index.css` is the local token and theme source of truth. It should stay aligned with the Ciridae UI registry base.

Use shadcn-style lowercase imports for registry components:

```tsx
import { Button } from "@/components/ui/button"
```

To add future UI from the hosted Ciridae registry, use either direct item URLs or the configured `@ciridae` registry in `components.json`:

```bash
npx shadcn@latest add https://ciridae-ui.ciridae.app/r/button.json
npx shadcn@latest add @ciridae/button
```

Reusable UI should be created in `int-ciridae-ui` first, published through the registry, then consumed here.

## Commands

```bash
yarn lint
yarn typecheck
yarn themecheck
yarn format:check
yarn build
```

## Frontend Boundaries

- Keep auth, Firebase, Sentry, PostHog, and `BackendClient` behavior intact unless the feature requires a deliberate change.
- API hooks should live under `src/hooks/api`, use TanStack Query, call `src/lib/BackendClient.ts`, and parse API responses with Zod schemas.
- All mutations must capture PostHog events on success.
- Use Ciridae semantic utilities such as `bg-background`, `text-foreground`, `bg-card`, `text-muted-foreground`, `border-border`, `bg-primary`, and `text-primary-foreground`.
- Do not rebuild a parallel local design system or preserve old component wrapper APIs.
