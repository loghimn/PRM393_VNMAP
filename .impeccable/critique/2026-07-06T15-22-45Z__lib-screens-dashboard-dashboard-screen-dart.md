---
timestamp: 2026-07-06T15-22-45Z
slug: lib-screens-dashboard-dashboard-screen-dart
---
Method: ⚠️ DEGRADED: single-context (no sub-agent tool exposed)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No loading/error states visible in dashboard view |
| 2 | Match System / Real World | 3 | Vietnamese labels and recognizable icons; some icon-only meaning |
| 3 | User Control and Freedom | 3 | View switching and collapse available; no undo/escape patterns visible |
| 4 | Consistency and Standards | 3 | Consistent component vocabulary; KPI toggle is an inconsistent micro-pattern |
| 5 | Error Prevention | 2 | No confirmation dialogs or guardrails visible in this surface |
| 6 | Recognition Rather Than Recall | 3 | Sidebar icons + labels; chart tab relies on icon recognition |
| 7 | Flexibility and Efficiency | 2 | No keyboard shortcuts, bulk actions, or power-user accelerators |
| 8 | Aesthetic and Minimalist Design | 3 | Dense but structured; clear layering |
| 9 | Error Recovery | 2 | No visible error states or recovery flows |
| 10 | Help and Documentation | 1 | No contextual help or documentation |
| **Total** | | **23/40** | **Acceptable** |

## Anti-Patterns Verdict

**LLM assessment**: This does not look AI-generated. It has a rugged, functional aesthetic with deliberate density. The compact header, pinned sidebar, and gradient KPI cards read as a field-operations tool. No generic "SaaS landing page" vibes.

**Deterministic scan**: detect.mjs returned [] — clean. No markup-level anti-patterns detected in this file.

**Visual overlays**: Not applicable. Flutter desktop app, not web-viewable in this session.

## Overall Impression

A functional, data-dense dashboard that prioritizes geographic context and rapid view switching. The biggest weakness is ergonomics: some controls are too small for comfortable desktop use, and the app lacks visible scaffolding for first-time users or error scenarios.

## What's Working
- Clear surface separation: background / surface-muted / border stack is consistent and readable.
- Primary navigation is always visible: sidebar on desktop, bottom nav on mobile. Users never lose orientation.
- Semantic gradients: rank and status use color purposefully (primary for selected, mint/green for positive, amber for caution, coral for error).

## Priority Issues

[P1] KPI toggle is too small for reliable interaction
- Why: The toggle buttons are ~20px tall with 9px text. Material guidance recommends minimum 48x48 touch targets. Users will misclick or avoid them.
- Fix: Increase minimum tap target to 40x40; use Icon + Text minimum 14px.
- Suggested command: /impeccable polish dashboard_screen

[P1] Empty state returns nothing
- Why: if (provinces.isEmpty) return const SizedBox.shrink(); — if data fails to load, the KPI row disappears silently. Users get no guidance.
- Fix: Show an inline empty state with a retry action and descriptive message.
- Suggested command: /impeccable harden dashboard_screen

[P2] Icon-only meaning in tab 1
- Why: The first tab icon changes based on _chartMetric (density/area/population), but the label stays static ("Mật Độ Dân Số"). Users won’t realize the tab content mode changed.
- Fix: Replace icon with segmented control above the tab bar, or add the metric name to the tab label.
- Suggested command: /impeccable clarify dashboard_screen

[P2] Header typography is extremely small
- Why: Page title is 16px, subtitle 10px. At desktop viewing distances this is illegible. The DESIGN.md scale calls for Title at 24px and Caption at 13px minimum.
- Fix: Scale header up to at least Title/Caption minimums; reduce KPI row density instead.
- Suggested command: /impeccable typeset dashboard_screen

[P2] No visible loading or error states
- Why: Data loads in initState but the dashboard shows no skeleton, spinner, or error banner if loadData() fails.
- Fix: Add loading placeholders for KPI cards and error banner with retry.
- Suggested command: /impeccable onboard dashboard_screen

## Persona Red Flags

Alex (Power User): No keyboard shortcuts detected. View switching requires mouse/touch only. KPI toggle is so small it slows even fast users down. No bulk actions for province filtering.

Jordan (First-Timer): The KPI toggle/chevron pair is ambiguous — two controls that appear to do similar things. No contextual help. Empty state gives zero guidance.

Sam (Accessibility-Dependent): Touch targets below minimum size. Very small text (10px) risks failing contrast/readability at 200% zoom. No ARIA semantics visible for custom interactive widgets (sidebar items are GestureDetector), Flutter accessibility may expose labels but custom hit targets can be problematic.

## Minor Observations
- Tab bar uses TabBarIndicatorSize.tab with custom gradient indicator — consistent with DESIGN.md.
- Animated scale on sidebar hover (1.05) is subtle and tasteful.
- Provincial rank badges use emoji (🏆, 📍) — acceptable but could be replaced with icon widgets for consistency and localization.

## Questions to Consider
- Should the KPI toggle be replaced with a segmented control or sidebar section to reduce micro-interaction cost?
- Can the header gain breathing room by reducing KPI card padding instead of shrinking text?
- What should the user see if province data is stale or partially loaded?
