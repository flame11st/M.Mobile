# UXR45 ad placement and measurement policy

MovieDiary 3.0 does not render persistent banner ads. The prior global banner
switch could place a banner above Search, My Movies, Lists, Settings,
Recommendation History, general/personal list detail, and Movie Details. Those
call sites and the shared banner loading path were removed. Rate Movies,
Discover/MovieDNA, Recommendations, Recommendation History, and the Movie
Details hero are therefore always banner-free.

## Free-tier interstitial contract

UXR71 supersedes the legacy generation/action-threshold model. The only
supported placement remains `recommendation_completion`, but eligibility is
now evaluated only after the user explicitly finishes a complete 10-of-10
recommendation deck and the product completion state is rendered.

The typed remote policy defaults to no interstitial in the first app session or
on the first completed deck of each UTC day, a 10-minute minimum interval,
maximum two shown per app session, and maximum three shown per UTC day. Recent
native/rewarded interaction or a Premium prompt also starts the centralized
10-minute adjacency guard. Premium and unresolved entitlement always fail
closed.

Inventory may preload before an eligible completion. At the completion
boundary the manager shows only already-ready inventory. Missing inventory,
unresolved consent, or background state emits a skip and returns immediately;
there is no candidate timer, load wait, spinner, or delayed surprise on resume.
The incompatible encrypted `adPolicyV1` action state is deleted and replaced by
versioned `adPolicyV2` completion/session/day state.

## Entitlement, consent, and lifecycle safety

- Premium state is applied during startup, profile refresh, purchase/restore,
  and logout. Premium immediately clears pending eligibility and disposes loaded
  inventory; premium members never initialize, load, or show an ad.
- iOS requests tracking authorization only near eligibility. Denial,
  restriction, unavailable consent APIs, load failure, and show failure all
  fail closed without changing the product route or visible state. Android uses
  the platform ad request without an ATT prompt.
- An interstitial is shown only while the app is resumed. Backgrounding does
  not trigger a delayed surprise on resume; the member must complete another
  eligible action after the candidate window expires.
- The previous Flutter focus node is restored after dismissal/failure, and the
  native full-screen overlay does not rebuild or replace the recommendation
  route/card state.
- Policy count, cooldown, pending eligibility, and post-ad exit observation are
  stored in encrypted device storage and survive process recreation.

Native ads are disabled in debug builds by default. A deliberate ad QA build
must set `MOVIEDIARY_ENABLE_DEBUG_ADS=true`. Production unit IDs remain the
default; Google's platform test interstitial IDs are selected only in a
non-release build with `MOVIEDIARY_AD_ENVIRONMENT=test`, so a release build
cannot accidentally select test inventory.

## Telemetry definitions

- `recommendation_deck_completed`: emitted after the explicit Finish action and
  completion-state render; this is the only interstitial value boundary.
- `interstitial_shown`: emitted only from the native full-screen shown callback.
- `interstitial_closed`: emitted only from the dismissal callback with
  `outcome_category=dismissed_to_app`. This is the continuation population.
- `user_exit_after_ad`: emitted when the app backgrounds within 30 seconds of
  dismissal and does not return for 15 seconds. The observation is persisted,
  so a later process recreation can finish classification. A quick background
  and foreground round trip is not an exit.

All ad events use `ad_placement=recommendation_completion` and
`source_surface=recommendations`. Continuation is measured as closed events
without a matching defined exit; no ordinary pause, ad load failure, or
pre-dismissal lifecycle callback fabricates an exit.

UXR68 preserves these legacy fields/events and adds `placement`, `is_premium`,
session/day shown counts, eligibility/load/failure/skip outcomes, and
currency-specific paid-value telemetry. The admin report now classifies a
meaningful product action within 120 seconds of close as continuation, keeps the
existing qualified `user_exit_after_ad` as background/termination evidence, and
marks incomplete observation windows pending. The full cross-format ownership
and privacy contract is `M/UXR68_MONETIZATION_ANALYTICS.md`.

## Verification ownership

`test/ad_policy_test.dart` covers first session/deck, 9:59 versus 10:00,
session/day caps, UTC rollover, Premium/config/consent/inventory guards,
adjacency, duplicate completion, V1 retirement, process recreation, and the
exit/return definition. Recommendation widget tests prove cards one through
nine cannot trigger policy, Finish renders before provider completion, and the
boundary is exactly once. Physical
release-candidate verification must still confirm the real Google inventory,
iOS consent presentation, TalkBack/VoiceOver focus restoration, and app-store
premium purchase/restore transitions.
