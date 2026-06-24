# Ciridae UI Style Guidelines

Ciridae UI follows Ciridae Precision: monochrome-first, compact, operational product UI. Root `DESIGN.md` is the implementation guide and root `CIRIDAE_PRECISION.md` is the design north star.

## Tokens

Use the Tailwind v4 tokens defined in `src/index.css`.

Common utilities:

- `bg-background`
- `text-foreground`
- `bg-card`
- `text-card-foreground`
- `text-muted-foreground`
- `border-border`
- `bg-primary`
- `text-primary-foreground`
- `bg-secondary`
- `text-secondary-foreground`

Color should communicate hierarchy or semantic state. Do not use raw Tailwind palette utilities, arbitrary color values, gradients, glows, or decorative effects.

## Typography

Use Host Grotesk through the Ciridae font tokens for product UI. Use IBM Plex Mono for identifiers, timestamps, code, and numeric operational data.

Use sentence case for routine UI. Reserve uppercase for tiny metadata labels through `text-meta`.

## Components

Use Ciridae shadcn primitives from `@/components/ui` first. Future reusable UI should be added to the Ciridae UI registry before it is consumed in this template.

Cards, tables, controls, overlays, loading states, focus rings, and density should come from shared Ciridae primitives rather than one-off local styling.

## Motion And Loading

Use the motion tokens in `src/index.css`. Keep motion subtle and reduced-motion aware.

Use shared loading primitives for auth/app boot, skeletons for unknown content, button loading for short actions, and progress for known jobs.
