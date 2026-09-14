# UXR69 provider-isolated native and rewarded lifecycle

## Boundary

`AdInventoryCoordinator` is the provider-neutral owner for native and rewarded
inventory. Product code can request a preload, inspect readiness, render a
`NativeAdResource`, or start a `RewardedAdResource` without importing Google
Mobile Ads types. `GoogleMobileAdsInventoryProvider` is the only native or
rewarded adapter that imports `google_mobile_ads`.

UXR69 does not enable a product placement. `AdManager.applyConfiguration`
deliberately keeps managed-format infrastructure disabled even when the typed
remote contract contains true native or rewarded flags. No screen calls
`preloadNative`, `preloadRewarded`, or `showRewarded`. The Google adapter uses
only Google's published test inventory, and only in an explicit non-release
`MOVIEDIARY_AD_ENVIRONMENT=test` plus
`MOVIEDIARY_ENABLE_DEBUG_ADS=true` QA build. Production native/rewarded unit
credentials were not added or changed.

## Lifecycle contract

- Inventory is lazy and starts suppressed and disabled.
- Load state is provider-neutral: idle, loading, ready, showing, completed,
  dismissed-without-reward, failed, and disposed.
- Load failure uses bounded exponential backoff. Core app flow never waits for
  inventory and callers receive immediate unavailable/started/ready results.
- Background state pauses new load/retry work. Foreground recovery resumes only
  inventory that a caller previously requested.
- Network loss invalidates loaded objects while retaining explicit demand;
  recovery loads fresh provider objects.
- An unresolved entitlement, account transition, Premium purchase, or Premium
  restore fails closed, clears demand, invalidates in-flight generations, and
  disposes loaded or playing resources. Stale callbacks are ignored.
- Application disposal removes the app lifecycle observer and disposes native,
  rewarded, and interstitial resources deterministically.
- Native impression/click/close/failure callbacks and rewarded
  show/impression/click/close/failure/reward callbacks are deduplicated per
  attempt for the UXR68 analytics boundary.
- Reward credit can be proposed only by the provider's authoritative reward
  callback. The coordinator emits one unique `<show-attempt>:reward`
  idempotency key and never grants product credit or generates recommendations.

## Shared native surface

`MdNativeAdSurface` uses the canonical opaque MovieDiary tokens: 24 px screen
margin, 24 px outer radius, 16 px padding, 16 px internal spacing, restrained
border/shadow, and a 44 px disclosure icon target. `Sponsored` and
`Advertisement` are visible and the semantics container is labelled
`Sponsored advertisement`. The component contains no MovieDNA, match,
recommendation, or movie-card language.

## Follow-up ownership

- UXR70 may add policy-approved Discover and General-list calls, analytics
  context, and native placement enablement.
- UXR74 may request rewarded preload/show only after the backend allowance and
  durable credit ledger exist. It must persist the emitted idempotency key
  before granting or consuming a deck credit.
- Live flags, deployment configuration, credentials, signing, publishing,
  subscriptions, tiers, and lifetime Premium pricing remain unchanged.
