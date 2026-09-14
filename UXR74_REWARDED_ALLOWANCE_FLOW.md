# UXR74 rewarded allowance flow

## Product boundary

The rewarded offer exists only on the backend-authoritative recommendation
allowance surface. It never appears during onboarding, rating, an active deck,
Search, My Movies, Lists, Details, Settings, or purchase.

After a Standard user uses the two free UTC-day decks, the next generation
attempt may open one dismissible **More recommendations** sheet for that intent.
The sheet offers:

1. **Watch ad & continue** — one authoritative completed reward can grant one
   durable deck credit.
2. **Get Premium** — opens the existing lifetime product without changing its
   product ID, tier, or price.
3. **Not now** — dismisses the offer and does not repeat it in the same request
   loop.

Inventory failure never blocks MovieDiary. Loading, unavailable, dismissal, and
playback failure states keep Premium and dismissal available.

## Transaction boundary

`RewardedAllowanceFlowController` accepts value only from UXR69's authoritative
provider reward callback. It deduplicates that callback, then uses
`RewardedDeckCreditService` to persist UXR73's idempotent provider transaction.
Dismissal and failure never reach the grant endpoint.

Reward completion does not call recommendation generation. The sheet first
shows **Your extra deck is ready**, then requires a separate **Build
recommendation deck** tap. That request uses UXR72/UXR73 reservation semantics:
free quota first, then the oldest reward credit; a successful batch consumes the
reservation and failure restores it.

## Premium and lifecycle

The application-level entitlement remains authoritative. Purchase, restore, or
account entitlement changes suppress and dispose rewarded inventory through
`AdManager.setPremiumStatus`. If Premium activates while the sheet is present,
the sheet closes and the recommendation limit state is removed immediately.

MovieDiary's production AdMob units are the normal build defaults:

- Android Native: `ca-app-pub-5540129750283532/8561091229`
- Android Rewarded: `ca-app-pub-5540129750283532/3128072193`
- iOS Native: `ca-app-pub-5540129750283532/9794281840`
- iOS Rewarded: `ca-app-pub-5540129750283532/4665244096`

The existing build-time inputs remain available only as explicit overrides:

- `MOVIEDIARY_ANDROID_REWARDED_AD_UNIT_ID`
- `MOVIEDIARY_IOS_REWARDED_AD_UNIT_ID`

Normal builds require no ad-environment or debug-ad flag. Google automatically
serves test creatives for emulators and registered test devices while the app
uses the production unit mapping. An explicitly empty debug/profile unit
override may use Google's official sample inventory for diagnostics; release
builds fail closed when a unit is unavailable.

## Verification contract

- Controller tests cover authoritative completion, duplicate callback,
  dismissal, playback failure, zero automatic generation, and Premium
  suppression.
- Recommendation widget tests prove the third attempt opens once and that the
  explicit post-credit tap starts the next request.
- Goldens cover 390×844 at 1.0× text and 430×930 at 1.25× text.
- UXR72/UXR73 backend tests remain the source of truth for consume/restore,
  idempotency, UTC caps, identity merge, and JWT ownership.

## Emulator E2E evidence — 2026-09-05

Android Google Play API 35 was verified with real Google-rendered components,
not placeholder cards:

- the production Native unit rendered a Google **Test Ad** and passed the
  AdMob native validator with no implementation issues;
- the production Rewarded unit rendered a fullscreen Google **Test Ad**,
  reached the authoritative **Reward granted** state, and created exactly one
  durable credit;
- **Build recommendation deck** consumed that credit exactly once, committed
  the rewarded reservation and batch, and displayed a different 10-item deck;
- an exhausted cached deck opens without an immediate paywall; the rewarded
  offer appears only after the user explicitly requests a fresh deck;
- a successfully generated rewarded deck is no longer covered by a second
  rewarded offer.

Evidence is stored under `e2e-artifacts/`. iOS remains **Required Manual
Verification** because no iOS simulator/runtime is available on this Windows
host. The production remote-config path also remains **Required Manual
Verification** until the AWS variables response contains its `monetization`
object; the endpoint currently returns no such object, so the server correctly
uses the conservative unmetered fallback. Local E2E used the existing
Development-only allowance override without changing deployment configuration.
