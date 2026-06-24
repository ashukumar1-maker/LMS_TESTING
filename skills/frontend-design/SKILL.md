---
name: frontend
description: Design system, styling conventions, and component patterns for the React frontend.
---

# Frontend Design System

## When to Use

Use these guidelines when building or modifying any frontend UI. The design system ensures visual consistency, dark mode support, and maintainable code.

## Core Principles

1. **Semantic tokens only** — No raw colors (`bg-blue-500`). Use tokens (`bg-bg-default`, `text-content-emphasis`).
2. **Composition over configuration** — Small, focused components that combine well.
3. **Mobile-first** — Start with mobile layout, enhance for desktop.
4. **Dark mode aware** — All UI must work in both modes.

---

## Design Tokens

### Color Tokens

| Token | Usage |
|-------|-------|
| `bg-bg-default` | Main background |
| `bg-bg-muted` | Secondary surfaces |
| `bg-bg-subtle` | Hover states, cards |
| `bg-bg-emphasis` | Emphasized sections |
| `text-content-emphasis` | Headings |
| `text-content-default` | Body text |
| `text-content-subtle` | Secondary text |
| `text-content-muted` | Tertiary, placeholders |
| `border-border-default` | Standard borders |
| `border-border-subtle` | Light borders |
| `bg-accent` / `text-accent` | Primary actions, brand |

### Adding Custom Colors

Raw Tailwind colors (`bg-blue-500`, `text-gray-200`) are disabled. To add a new color:

1. Add CSS variable in `src/styles/themes.css` (both `.light` and `.dark`)
2. Add token in `tailwind.config.ts` under `colors`

```css
/* src/styles/themes.css */
.light {
  --bg-warning: 255 237 213; /* orange-100 */
}
.dark {
  --bg-warning: 113 63 18; /* yellow-900 */
}
```

```ts
// tailwind.config.ts
colors: {
  "bg-warning": "rgb(var(--bg-warning) / <alpha-value>)",
}
```

### Typography

```tsx
font-display    // Headings (Pragmatica Cond)
font-sans       // Body text (Pragmatica)
font-mono       // Code (system monospace)

text-2xs / text-xs / text-sm / text-base / text-lg / text-xl / text-2xl
font-light / font-normal / font-medium / font-semibold / font-bold
```

### Heading Utilities

Semantic elements (`h1`-`h6`) get heading styles automatically. For non-semantic elements:

```tsx
<span className="heading-lg">Section Title</span>
<div className="heading-xl">Page Title</div>

// Available: heading, heading-sm, heading-base, heading-lg, heading-xl, heading-2xl
```

### Animations

| Class | Use for |
|-------|---------|
| `animate-scale-in` | Modal enter |
| `animate-fade-in` | Overlay backgrounds |
| `animate-slide-up-fade` | Tooltips, popovers |
| `animate-slide-in-from-right` | Sheet/drawer |
| `animate-accordion-down` | Expandable sections |

---

## Component Architecture

```
src/components/
├── ui/           # Reusable primitives (Button, Input, Card, Modal)
├── layouts/      # App shell, navigation
└── features/     # Feature-specific (auth/, feedback/)
```

### Available Primitives

Check `ui/` before building. We have:
- `Modal`, `Sheet`, `Popover`, `Tooltip` (Radix-based)
- `Button`, `Input`, `Card`, `Badge`, `Avatar` (custom)

For new complex components, use [Radix UI](https://www.radix-ui.com/) primitives.

### CVA Pattern for Variants

```tsx
import { cva, type VariantProps } from "class-variance-authority"

export const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md font-medium transition-colors",
  {
    variants: {
      variant: {
        primary: "bg-accent text-accent-foreground hover:bg-accent-emphasis",
        secondary: "bg-bg-subtle text-content-default hover:bg-bg-emphasis",
      },
      size: {
        sm: "h-8 px-3 text-sm",
        md: "h-10 px-4 text-sm",
      },
    },
    defaultVariants: { variant: "primary", size: "md" },
  }
)
```

### Adding a Component

**Primitive (reusable everywhere):**
1. Create `ui/MyComponent.tsx`
2. Use CVA for variants
3. Export from `ui/index.ts`

**Feature-specific:**
1. Create in `features/[feature]/MyComponent.tsx`
2. Export from feature's `index.ts`

---

## Icons

Use **Lucide React**:

```tsx
import { Search, Settings } from "lucide-react"

<Search className="h-4 w-4" />
```

Browse: [lucide.dev/icons](https://lucide.dev/icons)

---

## Client Customization

### ThemeProvider

```tsx
import { ThemeProvider } from "@/contexts"

<ThemeProvider
  accentColor="#6366f1"           // Client brand color
  client={{
    logo: "/logos/client.svg",    // For light mode
    logoDark: "/logos/client-white.svg",
  }}
>
  <App />
</ThemeProvider>
```

### What's Customizable

| Element | Customizable? |
|---------|---------------|
| Platform nav logo | No (always Ciridae) |
| Favicon | No (always Ciridae) |
| Accent color | Yes |
| Client logo | Yes (shows in app nav) |

### Adding Client Logos

1. Place in `/public/logos/`
2. Use SVG (preferred) or transparent PNG
3. Pass to ThemeProvider:
   - `logo` — required, used on light backgrounds (and dark if no `logoDark`)
   - `logoDark` — optional, used on dark backgrounds

---

## Key Files

| File | Purpose |
|------|---------|
| `tailwind.config.ts` | Token definitions, animations |
| `src/styles/themes.css` | CSS variable values |
| `src/contexts/ThemeContext.tsx` | Theme provider, accent color |
| `src/components/ui/index.ts` | All UI exports |
| `src/apps/config.tsx` | App registry (nav, icons) |
| `src/apps/ADDING_APP.md` | Guide for adding new apps |

---

## DO / DO NOT

**DO**
- Check existing `ui/` components first
- Use semantic color tokens
- Follow existing patterns in the codebase
- Use TypeScript types for all props

**DO NOT**
- Rebuild existing components from scratch
- Hardcode colors — use tokens (`bg-bg-default`, not `bg-white`)
- Install shadcn components (we use Radix directly)
- Use raw Tailwind colors (`bg-blue-500`)

