---
version: alpha
name: Ciridae Precision
description: Monochrome-first, precision-oriented product design system for Ciridae AI operating systems.
colors:
  background: "#FAFAFB"
  foreground: "#0A0A0B"
  card: "#FFFFFF"
  card-foreground: "#0A0A0B"
  popover: "#FFFFFF"
  popover-foreground: "#0A0A0B"
  primary: "#0A0A0B"
  primary-foreground: "#FCFCFC"
  secondary: "#EFF0F1"
  secondary-foreground: "#151617"
  muted: "#EFF0F1"
  muted-foreground: "#57585A"
  accent: "#E9E9EB"
  accent-foreground: "#111212"
  destructive: "#993A33"
  destructive-foreground: "#FCFCFC"
  border: "#D2D2D4"
  input: "#C8C9CA"
  ring: "#0A0A0B"
  surface: "#FFFFFF"
  surface-foreground: "#0A0A0B"
  surface-inverse: "#0A0A0B"
  surface-inverse-foreground: "#FCFCFC"
  success: "#315E3C"
  success-foreground: "#FCFCFC"
  success-muted: "#DEF1E1"
  info: "#3B5367"
  info-foreground: "#FCFCFC"
  info-muted: "#E2EDF7"
  warning: "#7D6533"
  warning-foreground: "#FCFCFC"
  warning-muted: "#F9EDD5"
  table-header-foreground: "#4C4D4F"
  chart-1: "#1A1B1B"
  chart-2: "#626364"
  chart-3: "#A4A4A6"
  chart-4: "#486781"
  chart-5: "#456F4E"
  sidebar: "#F3F3F4"
  sidebar-foreground: "#1C1D1E"
  sidebar-primary: "#0A0A0B"
  sidebar-primary-foreground: "#FCFCFC"
  sidebar-accent: "#E9E9EB"
  sidebar-accent-foreground: "#111212"
  sidebar-border: "#D2D2D4"
  dark-background: "#0A0A0B"
  dark-foreground: "#E9E9EA"
  dark-card: "#121314"
  dark-card-foreground: "#E9E9EA"
  dark-popover: "#171718"
  dark-popover-foreground: "#E9E9EA"
  dark-primary: "#F3F3F4"
  dark-primary-foreground: "#0A0A0B"
  dark-secondary: "#222324"
  dark-secondary-foreground: "#EBEBEC"
  dark-muted: "#222324"
  dark-muted-foreground: "#9E9EA0"
  dark-accent: "#272829"
  dark-accent-foreground: "#EBEBEC"
  dark-destructive: "#CE7067"
  dark-destructive-foreground: "#050606"
  dark-border: "#323334"
  dark-input: "#3C3D3E"
  dark-ring: "#D7D7D8"
  dark-surface: "#171718"
  dark-surface-foreground: "#E9E9EA"
  dark-surface-inverse: "#E9E9EA"
  dark-surface-inverse-foreground: "#0A0A0B"
  dark-success: "#77A680"
  dark-success-foreground: "#050606"
  dark-success-muted: "#152619"
  dark-info: "#85A2BC"
  dark-info-foreground: "#050606"
  dark-info-muted: "#16232E"
  dark-warning: "#C7AE7A"
  dark-warning-foreground: "#050606"
  dark-warning-muted: "#2F250E"
  dark-chart-1: "#DDDEDF"
  dark-chart-2: "#979899"
  dark-chart-3: "#5D5E5F"
  dark-chart-4: "#83A9CB"
  dark-chart-5: "#6FB07D"
  dark-sidebar: "#111212"
  dark-sidebar-foreground: "#D7D7D8"
  dark-sidebar-primary: "#F3F3F4"
  dark-sidebar-primary-foreground: "#0A0A0B"
  dark-sidebar-accent: "#222324"
  dark-sidebar-accent-foreground: "#EBEBEC"
  dark-sidebar-border: "#323334"
  dark-table-header-foreground: "#B6B7B9"
typography:
  display:
    fontFamily: Host Grotesk
    fontSize: 40px
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: 0em
  heading:
    fontFamily: Host Grotesk
    fontSize: 30px
    fontWeight: 400
    lineHeight: 1.15
    letterSpacing: 0em
  body:
    fontFamily: Host Grotesk
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.46
    letterSpacing: 0em
  label:
    fontFamily: Host Grotesk
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: 0em
  metadata:
    fontFamily: Host Grotesk
    fontSize: 11px
    fontWeight: 500
    lineHeight: 1
    letterSpacing: 0.035em
    textTransform: uppercase
  mono:
    fontFamily: IBM Plex Mono
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: 0em
rounded:
  sm: 3px
  md: 5px
  lg: 7px
  xl: 9px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container: 1180px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.primary-foreground}"
    rounded: "{rounded.md}"
    typography: "{typography.body}"
    height: 34px
  button-secondary:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.secondary-foreground}"
    rounded: "{rounded.md}"
    typography: "{typography.body}"
    height: 34px
  card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.card-foreground}"
    rounded: "{rounded.lg}"
    padding: 20px
  input:
    backgroundColor: "{colors.background}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.md}"
    typography: "{typography.body}"
    height: 34px
  badge:
    rounded: "{rounded.sm}"
    typography: "{typography.label}"
  table-row:
    height: 32px
---

# Ciridae UI Design

## Overview

Ciridae UI follows **Ciridae Precision**: exact, modern, serious product design for AI operating systems. The interface should feel like mission-critical infrastructure: calm, fast, intelligent, and durable.

The product language is minimal but not empty. It should support real operators doing repeated work in dense business systems. The design earns trust through alignment, hierarchy, restrained surfaces, precise type, and reliable interaction states.

## Colors

The palette is monochrome-first. Black, white, and calibrated grays carry the core identity. Color is reserved for semantic state, not decoration.

- **Primary:** Near-black in light mode and near-white in dark mode. Use for decisive primary actions and active command states.
- **Neutral surfaces:** Backgrounds, cards, popovers, sidebars, borders, and hover states are layered through small tonal steps.
- **Status colors:** Success, info, warning, and destructive tokens are desaturated and operational. They must remain readable as text on normal app surfaces, not only as filled badge backgrounds.
- **Charts:** Prefer neutral series first, with restrained blue and green only when additional distinction is needed.

`frontend/src/index.css` is the source of truth for all shadcn/Tailwind color tokens. Agents and engineers should use normal semantic utilities and let the token map carry the Ciridae Precision palette.

## Typography

Ciridae Precision is the product typography system. Host Grotesk gives the application a stable, machined, UI-native grotesk voice while staying neutral enough for customer-facing operating systems. Brand wordmarks should ship as logo assets, not as application UI fonts.

- **Display and headings:** Use Host Grotesk through the display token, regular weight, no negative tracking. Use type size, spacing, and alignment for hierarchy instead of heavy weight.
- **Body and controls:** Use Host Grotesk through the sans token, regular or medium. Keep rhythm compact and optimized for scanning, labels, forms, tables, and repeated workflows.
- **Mono/data:** Use IBM Plex Mono for identifiers, invoice numbers, timestamps, code, logs, and technical readouts. Use tabular numbers for financial and operational data.
- **Casing:** Use sentence case for page titles, section headings, buttons, nav, tabs, menus, form labels, table headers, and status text.
- **Uppercase:** Use all caps only for tiny metadata, system labels, section labels, and very short status labels through the `text-meta` utility. Do not use all caps for routine actions, page titles, form labels, or navigation.

Do not scale type with viewport width. Keep compact panels, cards, sidebars, and dashboards in appropriately small type.

## Layout

Favor operational layouts: sidebars, tabs, tables, forms, filters, panels, and command surfaces. Use dense grids with enough air to avoid fatigue.

Application page bodies should use the full available canvas by default. Do not wrap whole dashboards, demos, registry pages, or operational views in arbitrary max-width containers. Constrain only content that benefits from it, such as prose, narrow forms, settings columns, and focused detail panels. Use the spacing scale consistently: `4px`, `8px`, `16px`, `24px`, and `32px`. Avoid decorative page sections and marketing composition inside application screens.

Component density is centralized in `frontend/src/index.css` through `--control-height`, `--control-height-sm`, `--control-height-xs`, `--control-padding-x`, `--panel-padding`, `--panel-gap`, `--menu-item-height`, `--table-row-height`, `--badge-radius`, and `--focus-ring-width`. Normal Tailwind spacing is still appropriate for page layout; shared component defaults should carry the product feel.

## Elevation & Depth

Depth is conveyed through tonal layers, borders, and restrained shadows. Most surfaces should feel flat and engineered. Reserve stronger elevation for popovers, dialogs, menus, sheets, and other floating UI.

Use borders to create structure. Use shadows to clarify hierarchy, not to decorate. Default `Card` usage is a contained Ciridae Precision surface: flat, compact, bordered, and low-shadow. Use `variant="section"` only when a page area should be unframed. Cards should stay flat with `shadow-xs`; floating surfaces should use the restrained `shadow-md` to `shadow-lg` token range. Avoid scale-based entrance motion, heavy shadows, gradients, glows, blur effects, and arbitrary shadow values.

## Shapes

The shape language is compact and precise.

Use a `5px` base radius for routine controls. Smaller surfaces may use `3px`; larger floating or surface-contained panels may use `7px` to `9px`. Avoid oversized, playful, or pill-like cards. Full radius is reserved for circular icon controls and intentional pills.

## Components

- **Buttons:** Primary buttons are black or white command surfaces. Routine actions should usually be secondary, outline, or ghost.
- **Badges:** Prefer outline or muted badges with sharper small-radius geometry. Filled status badges should be used sparingly.
- **Inputs:** Inputs use clear borders, strong focus rings, compact height, and calm error states.
- **Cards:** Plain Cards are the default contained surface and should be safe for agent-generated card grids. Keep them flat, compact, and token-driven. Use `variant="section"` for intentional unframed sections. Do not nest cards inside cards or add manual divider bars inside Cards unless the content is a true table or list primitive.
- **Sidebar:** Sidebar surfaces should feel like a command rail, not a branded color block. Group labels use metadata typography; active rows use tonal state and a restrained ring rather than heavy weight.
- **Tables:** Tables should prioritize scan speed, alignment, subtle row states, metadata-style headers, and clear numeric columns.
- **Charts:** Keep chart palettes restrained and readable. Do not create rainbow dashboards.
- **Loading:** Use skeletons for unknown content, button loading for short actions, `Progress` for known jobs, and page loading only for auth or app boot. Do not hand-roll spinners, pulse blocks, or centered loading text.

## Do's and Don'ts

- Do use semantic tokens from `frontend/src/index.css`.
- Do use stock shadcn components from `frontend/src/components/ui`; their defaults encode Ciridae Precision.
- Do use Card grids for overview pages when the content is a set of destinations, summaries, or grouped actions.
- Do let page-level grids, tables, metrics, and cards span the available application workspace.
- Do keep color monochrome-first unless color communicates state.
- Do make dark mode feel native, not inverted.
- Do preserve strong text contrast and visible 2px focus states.
- Do use `CIRIDAE_PRECISION.md` for philosophy and this file for implementation rules.
- Do use `LoadingState`, `PageLoadingState`, `TableSkeleton`, `CardSkeleton`, `FormSkeleton`, `Spinner`, and `Progress` for loading surfaces.
- Don't use raw Tailwind palette utilities or arbitrary color values.
- Don't nest cards inside cards or recreate table/list structure with ad hoc `border-y` and `divide-y` bars.
- Don't create top-left content islands by putting whole app pages inside arbitrary max-width wrappers.
- Don't use raw `animate-spin`, raw `animate-pulse`, or visible ad hoc loading strings outside approved loading primitives.
- Don't use decorative gradients, glows, or futuristic effects.
- Don't use scale-based entrance motion, arbitrary shadows, heavy shadows, or oversized focus rings.
- Don't use colorful SaaS palettes.
- Don't add Storybook or a separate registry/docs stack without explicit direction.
- Don't change backend, auth, Firebase, infra, or deployment systems unless explicitly requested.
