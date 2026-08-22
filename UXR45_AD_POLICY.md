# UXR45 ad placement and measurement policy

MovieDiary 3.0 does not render persistent banner ads. The prior global banner
switch could place a banner above Search, My Movies, Lists, Settings,
Recommendation History, general/personal list detail, and Movie Details. Those
call sites and the shared banner loading path were removed. Rate Movies,
Discover/MovieDNA, Recommendations, Recommendation History, and the Movie
Details hero are therefore always banner-free.

## Free-tier interstitial contract

The only supported placement is `recommendation_completion`. It becomes
eligible after four successful, non-empty recommendation deck generations and
at most once per rolling 24 hours. Both values are centralized and may be
changed at build time with:

- `MOVIEDIARY_AD_COMPLETED_ACTION_THRESHOLD` (default `4`)
- `MOVIEDIARY_AD_COOLDOWN_HOURS` (default `24`)
- `MOVIEDIARY_AD_SHOW_WINDOW_SECONDS` (default `12`)

The defaults are deliberately conservative starting assumptions, not an
optimization claim. A failed, empty, timed-out, cancelled, retry-error, or lazy
page request does not count. The recommendation result state is committed and
its `recommendation_generated` event is queued before the ad policy runs. If
inventory is not ready within the short post-completion window, navigation
continues and the eligibility remains durable for a later completed action.
There is no attempt before first value, during onboarding/rating, while a deck
is loading, or as a consequence of an error.

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

- `recommendation_generated`: the completed product event and value boundary.
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

## Verification ownership

`test/ad_policy_test.dart` covers threshold/cooldown, premium bypass,
consent/inventory guards, durable pending eligibility, process recreation, and
the exit/return definition. Recommendation widget tests prove only successful
non-empty deck completion reaches the policy integration point. Physical
release-candidate verification must still confirm the real Google inventory,
iOS consent presentation, TalkBack/VoiceOver focus restoration, and app-store
premium purchase/restore transitions.
