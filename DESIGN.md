---
name: PRM393_VNMAP
description: Vietnam geographic dashboard for operational field data management and analytics
colors:
  ocean-blue: "#2563EB"
  ocean-blue-light: "#60A5FA"
  ocean-blue-dark: "#1D4ED8"
  cyan: "#06B6D4"
  cyan-light: "#22D3EE"
  violet: "#8B5CF6"
  violet-light: "#A78BFA"
  mint: "#10B981"
  amber: "#F59E0B"
  coral: "#EF4444"
  paper: "#DEE4EC"
  surface: "#FFFFFF"
  surface-muted: "#F1F5F9"
  ink: "#1E293B"
  ink-secondary: "#64748B"
  ink-muted: "#94A3B8"
  border: "#E2E8F0"
typography:
  display:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "42px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: -0.5
  headline:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -0.3
  title:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.2
  body:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0.1
  caption:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: 0.2
  label:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.3
rounded:
  card: "16px"
  input: "12px"
  button: "12px"
  chip: "20px"
  badge: "8px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border}"
    rounded: "{rounded.card}"
    padding: "{spacing.lg}"
  elevated-button:
    backgroundColor: "{colors.ocean-blue}"
    textColor: "#FFFFFF"
    rounded: "{rounded.button}"
    padding: "18px 48px"
    fontSize: "14px"
    fontWeight: 600
  input:
    backgroundColor: "{colors.surface-muted}"
    borderColor: "{colors.border}"
    rounded: "{rounded.input}"
    padding: "16px 16px"
  chip-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    borderColor: "{colors.border}"
    rounded: "{rounded.chip}"
    padding: "6px 12px"
  chip-selected:
    backgroundColor: "{colors.ocean-blue}"
    textColor: "#FFFFFF"
    borderColor: "{colors.ocean-blue}"
    rounded: "{rounded.chip}"
    padding: "6px 12px"
  snackbar:
    backgroundColor: "{colors.ink}"
    textColor: "#FFFFFF"
    rounded: "{rounded.button}"
  dialog:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "{spacing.xl}"
---

# Design System: PRM393_VNMAP

## 1. Overview

**Creative North Star: "The Field Tablet"**

A calm, high-contrast data environment that feels like a precision instrument for field operations. Light surfaces carry soft blue-grey papers; dark surfaces sink into deep slate. The system is built for long working sessions, dense tables, and rapid map navigation. The palette is restrained: one primary blue, one cyan secondary, one violet accent, and smart neutrals. Gradients are used sparingly to mark rank and status, not decoration. The Redux pattern may imply "desk worker aesthetic" but the finished product must feel like a rugged tablet interface — information-rich, high-density, aware of ambient light and stakeholder fatigue.

Key Characteristics:
- High information density without clutter
- Clear surface layering through subtle borders and soft backgrounds
- Primary actions use Ocean Blue; secondary telemetry uses Cyan; attention-directing highlights use Violet
- Reduced motion by default; transitions are pure state changes
- Typography is tight, technical, and unambiguous

## 2. Colors

A disciplined palette of cool neutrals with three functional accents. The system uses DynamicColor to swap palette roles between light and dark modes while preserving recognition.

### Primary
- **Ocean Blue** (#2563EB / oklch(48% 0.2 264)): Primary actions, active navigation, map selection, focus rings, rank-1 highlights. Used on approximately 10% of any screen to preserve visual weight.

### Secondary
- **Cyan** (#06B6D4 / oklch(78% 0.14 196)): Secondary actions, metadata labels, status chips. Keeps informational content readable without competing with Ocean Blue.

### Tertiary
- **Violet** (#8B5CF6 / oklch(62% 0.22 293)): Tertiary actions, priority badges, selective emphasis. Reserved for alerts, edit mode indicators, and the occasional highlight.

### Neutral
- **Paper** (#DEE4EC / oklch(92% 0.01 220)): Base light background. A cool, slightly blue-tinted white that reduces eye strain in daylight.
- **Surface** (#FFFFFF / oklch(100% 0 0)): Cards, panels, and floating surfaces in light mode.
- **Surface Muted** (#F1F5F9 / oklch(96% 0.005 220)): Input fields, subtle containers, hover targets.
- **Ink** (#1E293B / oklch(23% 0.01 220)): Primary text, high-contrast labels, graph axes.
- **Ink Secondary** (#64748B / oklch(48% 0.02 220)): Body text, secondary metadata.
- **Ink Muted** (#94A3B8 / oklch(65% 0.01 220)): Captions, timestamps, disabled labels.
- **Border** (#E2E8F0 / oklch(88% 0.01 220)): Dividers, subtle strokes, hierarchy lines.
- **Success Mint** (#10B981): Positive confirmations, "active" status, top-rank indicators.
- **Warning Amber** (#F59E0B): Caution states, medium-priority alerts, rank-2 indicators.
- **Error Coral** (#EF4444): Destructive actions, validation errors, bottom-rank indicators.

### Named Rules
**The Rare Accent Rule.** Primary Ocean Blue appears on ≤10% of any given screen. Cyan and Violet are even rarer. Their rarity is the point — when the user sees blue, something is actionable.

**The Dark Surface Rule.** Dark mode is not simply inverted light mode. Dark surfaces carry reduced saturation (`#1E293B` instead of `#E2E8F0`) so highlights remain punchy. Never paste a light-mode value into dark mode; always derive from the neutral stack with adjusted luminance.

## 3. Typography

**Display Font:** System sans-serif stack, optimized for legibility of dense Latin and Vietnamese text. The stack prefers San Francisco on macOS, Segoe UI on Windows, Roboto on Android, ensuring each platform renders crisp local-language characters.

**Character:** Technical and precise. Tight line heights, negative letter spacing at large sizes, and a strict six-level hierarchy. Vietnamese tone-mark rendering is supported by the platform default stacks.

### Hierarchy
- **Display** (800 weight, 42px, line-height 1.1, letter-spacing -0.5): Page titles only. Maximum contrast against the background.
- **Headline** (700 weight, 32px, line-height 1.15, letter-spacing -0.3): Section headers. Used sparingly to separate major dashboard zones.
- **Title** (700 weight, 24px, line-height 1.2, letter-spacing -0.2): Card titles, panel headers, significant lists.
- **Body** (400 weight, 16px, line-height 1.4, letter-spacing 0.1): Core reading text. Supports 65–75ch per line on desktop.
- **Caption** (500 weight, 13px, line-height 1.3, letter-spacing 0.2): Secondary labels inside cards, metadata, timestamps.
- **Label** (600 weight, 11px, line-height 1.2, letter-spacing 0.3): Muted text, badges, map overlays, chip labels.

### Named Rules
**The Vietnamese Clarity Rule.** All text sizes maintain a minimum contrast ratio of 4.5:1 against their background under both light and dark themes. Font rendering must not truncate diacritical marks; use full leading and avoid tight clipping on accent marks.

## 4. Elevation

Surfaces are flat at rest with subtle borders. Depth is conveyed through layered borders, tone shifts, and only when the user acts. The system uses one ambient shadow for elevated cards and dialogs; no cast shadows appear on default cards.

### Shadow Vocabulary
- **Card Ambient** (`0 8px 24px rgba(0,0,0,0.18)` in dark, `0 4px 16px rgba(0,0,0,0.08)` in light): Cards, panels, and dialogs that float above the base surface. Applied conservatively; most content sits flush against the background.

### Named Rules
**The Flat-By-Default Rule.** No card has a shadow unless it is modal, elevated, or in focus. Default panels are separated via `border: 1px solid {colors.border}` on surface-muted backgrounds. Shadows appear only as response to state — hover, focus, or modal elevation.

## 5. Components

All components derive from a shared vocabulary of rounds, paddings, and palette roles. The system uses Material-style elevation but with custom color assignments.

### Buttons
- **Shape:** Gently curved edges (12px radius)
- **Primary:** Ocean Blue background (#2563EB) with white text. Padding is 18px horizontal, 12px vertical, fontWeight 600, fontSize 14. Zero elevation; no shadow at rest.
- **Hover / Focus:** Darker ocean blue tint (primaryDark). Focus ring uses a 2px Ocean Blue outline with 12px offset.
- **Destructive variants:** Use Error Coral (#EF4444) background with white text; same shape and padding.

### Chips / Filter Pills
- **Style:** Pill-shaped with 20px radius. Default state uses white or surface background with `{colors.border}` stroke and Ink text. Selected state inverts to Ocean Blue background with white text. Font size 12px, weight 500.
- **State:** Selected chips gain a soft `OKLCH(48% 0.2 264 / 0.15)` tint in dark mode when not fully selected; in light mode, a 10% opacity Ocean Blue wash.

### Cards / Containers
- **Corner Style:** Generously curved (16px radius), consistent across all cards.
- **Background:** Surface (#FFFFFF light, #1E293B dark).
- **Shadow Strategy:** Flat at rest with 1px `{colors.border}` stroke. Modal cards receive the Card Ambient shadow.
- **Border:** Solid 1px border only; no decorative gradients unless they carry semantic rank data.
- **Internal Padding:** 24px (xl) on desktops; cards collapse to 16px on smaller viewports.

### Inputs / Fields
- **Style:** Filled style with search/surface-muted background (#F1F5F9 light, #334155 dark), 1px `{colors.border}` stroke, 12px radius.
- **Focus:** Ocean Blue border expands to 1.5px width; no glow, no background shift.
- **Error / Disabled:** Error Coral border for validation. Disabled inputs use Ink Muted text and no border emphasis.

### Navigation
- **Style:** Bottom navigation uses the Surface background. Selected item is Ocean Blue; unselected is Ink Muted. Type fixed, zero elevation. Active indicator is color only, no underline.
- **Tab Bar:** Same color logic. Label size 13px, weight 600 selected, 500 unselected. Indicator is 2px Ocean Blue bar anchored to tab bottom.

### Map Province Cards
- **Style:** Compact cards within map popovers, 12px radius, surface background, 1px border. Province name uses Title size (24px bold), metadata uses Caption. Rank indicators are pill badges using the topRank / bottomRank colors.

### Statistics Panels
- **Style:** Score cards with internal padding of 14px, radius 8px, border 1px. Numeric values use Display size when shown alone; labels use Caption. Gradients are semantic only: primaryGradient for rank-1, greenGradient for positive trends, orangeGradient for caution.

## 6. Do's and Don'ts

### Do:
- **Do** reserve Ocean Blue (#2563EB) for actions, selections, and focus. When in doubt, ask whether the element moves the task forward.
- **Do** keep cards on the neutral surface stack. A card that needs emphasis should grow in size or weight, not in decoration.
- **Do** use the six-level text hierarchy exactly. Do not invent ad-hoc font sizes between levels.
- **Do** keep rank gradients semantic. Primary gradient for number 1, green for positive, orange for warning, never for decoration.
- **Do** verify 4.5:1 contrast for all text under WCAG AA, including caption sizes on both light and dark themes.
- **Do** use system font stacks so Vietnamese diacritical marks render crisply on all desktop platforms.

### Don't:
- **Don't** use decorative gradients, patterned backgrounds, glassmorphism, or noise textures. The surface is flat; depth comes from structure, not materiality.
- **Don't** place heavy marketing-style illustrations, hero images, or narrative scroll sections. This is an operational instrument — data density is the brand.
- **Don't** introduce additional accent colors beyond the defined trio. If a new color seems necessary, reconsider whether an existing token can carry the meaning.
- **Don't** use shadows by default. A shadow on every card is visual noise; reserve them for modal, active, or focus states only.
- **Don't** break the Surface / Surface Muted / Border stack. If a container feels flat, increase its border contrast or shift its surface token; never add a gradient to a passive element.
- **Don't** rely on color alone for status. Pair every color-coded indicator with text or icon affordance for color-blind users.