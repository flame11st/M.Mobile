# MovieDiary semantic design contract

UXR35 makes `lib/Widgets/Shared/md3_ui.dart` the source of truth for shared
visual semantics. New UI should select a role from this contract before adding
a local value. Existing component-specific geometry remains local only when it
cannot express a reusable product decision.

## Token groups

- `Md3Colors`: brand, surface, text, border, state, opinion, destructive,
  skeleton, scrim, and glass roles. `disliked` is intentionally distinct from
  `destructive`/`error`; dislike describes taste and never implies deletion.
- `Md3Spacing`: the 4/8/12/16/20/24/32/40/48 scale plus screen, card, control,
  and section aliases. Compact phone page edges retain the verified 16-point
  UXR16 inset; regular/wide screens use the 24-point screen role.
- `Md3Radius`: 8/12 component radii and the named input/poster 16, button 20,
  navigation-selection 22, card 24, navigation 28, sheet 32, and pill roles.
- `Md3Targets`: 44-point minimum and 48-point primary interactive geometry.
- `Md3Typography`: page, section, card, title, body, metadata, label, and
  navigation-label roles. The app theme consumes these values directly.
- `Md3Shadows`: one opaque content-card treatment plus sheet, glass,
  navigation, and selected-navigation roles. Glass roles are restricted to
  navigation, top filter/tab controls, and sticky bottom actions.
- `Md3Durations`: quick 120 ms, feedback 160 ms, standard 180 ms, emphasis
  240 ms, and shimmer 1200 ms. Interactive motion resolves to zero when the OS
  requests reduced motion.

## Shared geometry

- Content cards are opaque, radius 24, border `Md3Colors.border`, and use
  `Md3Shadows.contentCard`.
- Buttons are radius 20 with 48-point primary targets.
- Chips are pills and interactive chips retain a 44-point target.
- Bottom sheets are opaque, radius 32, safe-area aware, and scroll controlled.
- Poster thumbnails use radius 16 unless a deliberately smaller provider-logo
  or skeleton placeholder calls for a component-specific radius.
- Root navigation is a 72-point dock excluding the safe area, radius 28, with
  compact 22-point selected pills and bounded 8–12 point bottom margins.

## Targeted magic-value audit

Retained local values and rationale:

- Root-navigation flex weights (`64/50/75/49/58`) balance five labels with very
  different lengths on 390–430 point phones; they are content measurements,
  not reusable spacing tokens.
- Navigation internal values (`2` horizontal padding, `6` vertical padding,
  `56` selected-item height, `22` icon size, `11` label size) live in
  `Md3NavigationMetrics` because they form one tested dock geometry.
- Movie poster dimensions (for example 72x108 and 80x120) preserve the 2:3
  artwork ratio and vary by row density; only their corner treatment is a
  global token.
- Existing UXR16 compact layouts in Settings, recommendations, and inline
  notices retain measured 16-point card padding and 16/20-point local radii.
  These values equal the semantic scale but remain local where converting the
  call site would not change ownership or remove a repeated decision.
- The 180 ms active-tab scroll-to-top durations in Discover and Settings are
  navigation behavior, not rendered transition timing, so they remain local.
- Bottom-sheet drag thresholds, velocity, handle width, and 90% height cap are
  interaction mechanics rather than visual spacing.
- Network timeouts, debounce intervals, carousel dwell times, and animation
  controller periods are behavior/performance values, not visual-duration
  tokens unless they render a direct interface transition.
- A few 6-, 10-, 14-, and 18-point values remain inside dense metadata or
  icon geometry where replacing them with the nearest scale value changes
  alignment or legibility. They must not be copied into new components without
  a measured reason.

## Review rule

Before shipping a shared-surface change, verify one medium phone at 1.0x and
one large phone around 1.3x, 44-point targets, safe-area clearance, reduced
motion, opaque content, truthful loading/error/offline states, and dark system
icons on the light background.
