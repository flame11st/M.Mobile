# UXR77 monetization integration and resilience matrix

Run date: 2026-08-25 America/Los_Angeles (2026-08-26 UTC)

## Decision

The implementation delivered by UXR65-UXR76 already provides the required automated coverage. UXR77 therefore verifies and traces the existing behavior instead of duplicating production code or weakening any policy. The full focused and regression suites pass, the configured debug APK builds, and a real local-API Medium Phone journey confirms the safe first-session and offline-return paths.

No product source or test source changed in this run. No concrete monetization defect was found, so no follow-up queue row was created.

## Requirement traceability

### Premium

- No native, interstitial, rewarded requirement, or ordinary deck limit: `test/monetization_service_test.dart` — `unresolved and Premium entitlement fail closed`; `test/native_ad_placement_test.dart` — `Premium suppresses a ready native placement immediately`; `M.Core.Tests/RecommendationAllowanceTests.cs` — `RestoredPremium_BypassesReachedLimitImmediately`.
- Existing lifetime field, monotonic entitlement, purchase/restore, and anonymous merge: `M.Core.Tests/PremiumEntitlementTests.cs` — all four tests; `test/monetization_service_test.dart` — cached/backend/verified-store/stale-profile cases.
- Loaded inventory is removed before backend sync: `test/ad_inventory_test.dart` — `Premium activation invalidates loaded and playing inventory`; `test/monetization_service_test.dart` — purchase/verified-store suppression tests.

### Interstitial completion policy

- First session, first deck per UTC day, 10-minute boundary, two/session, and three/day: named cases in `test/ad_policy_test.dart`.
- No prohibited or back-to-back placement: `native_ad`, `rewarded_ad`, and `premium_prompt blocks a back-to-back interstitial`; `test/monetization_service_test.dart` — all declared ad-free zones and the explicit approved placement/surface pairs.
- Duplicate completion, persisted state, foreground/consent revalidation, and post-ad exit: named `test/ad_policy_test.dart` cases.
- Unavailable inventory never delays completion: `test/recommendations_page_test.dart` — `10 of 10 completion is explicit, exactly once, and never waits on ads`; `test/ad_policy_test.dart` — Premium/disabled/unavailable fail closed.

### Rewarded allowance and credits

- Two successful fresh free decks, UTC reset, history/retry exclusion, empty/failure release, concurrent admission, duplicate in-flight request, storage fail-open, and JWT subject binding: all eight `M.Core.Tests/RecommendationAllowanceTests.cs` cases.
- One authoritative reward, zero for dismissed/failed, three-per-day maximum, persistent credit, atomic reserve/consume/restore, stale/app-kill reconciliation, concurrent finalization, and anonymous merge: all eight `M.Core.Tests/RewardedDeckCreditTests.cs` cases.
- Provider callback deduplication, dismissal/failure, explicit post-reward generation, Premium activation, and one optional offer per third-request token: `test/ad_inventory_test.dart`, `test/rewarded_deck_credit_service_test.dart`, `test/rewarded_allowance_flow_test.dart`, and the allowance cases in `test/recommendations_page_test.dart`.

### Native placements and content integrity

- Discover waits for real content and an approved section boundary; General lists and the explicitly authorized My Movies Watchlist/Viewed surfaces insert only after displayed content 10 and 20; movie indices/counts remain content-based: `test/native_ad_placement_test.dart` and `test/my_movies_page_test.dart`.
- Personal Lists, rating history, Search, details, rating/Mark Watched sheets, Premium, and every other ad-free surface remain denied centrally. Watchlist and Viewed accept only their distinct named native placements; they do not reuse the General-list classification: `test/monetization_service_test.dart`.
- Unavailable inventory leaves no gap and disclosed cards remain opaque/distinct: widget and golden cases in `test/native_ad_placement_test.dart` and `test/md_native_ad_surface_test.dart`.

### Configuration, lifecycle, privacy, and network resilience

- Missing, malformed, unsupported, extreme, stale, cached, and offline remote config: all eight `test/monetization_config_test.dart` cases.
- Lazy loading, bounded retry, duplicate callbacks, network recovery, foreground recovery, account suppression, Premium invalidation, and disposal: all nine `test/ad_inventory_test.dart` cases.
- First-session deferral, UMP/ATT/contextual modes, provider failure, offline refresh, and consent withdrawal: all `test/ad_privacy_consent_test.dart` cases.
- Cached lifetime entitlement survives profile/network failure: `test/monetization_service_test.dart` — stale-profile case.
- Offline product analytics is durable and exactly-once: `test/product_analytics_test.dart` — offline queue/restart case; backend monetization reporting tests preserve event/revenue separation.

### Core product continuity

- Tracking persists and retries without monetization coupling: `test/anonymous_rating_sync_test.dart` and `test/watch_lifecycle_test.dart`.
- Watchlist/Seen/Details/generation failure flows stay deterministic: named `test/recommendations_page_test.dart` cases.
- Cached history remains truthful offline: `test/recommendations_history_page_test.dart` — `cached history remains truthful when refresh is offline`.
- Library, personal Lists, Search, Details, Settings, onboarding, and navigation remain covered by the 290-test full Flutter regression suite; none owns raw ad-frequency or provider logic.

### Identity and process-loss edges

- Account switch suppresses/disposes inventory: `test/ad_inventory_test.dart` — account suppression/disposal.
- Anonymous-to-authenticated allowance, reward-credit, and Premium merges: backend allowance, reward, and entitlement merge tests.
- Wrong JWT subject is rejected for Premium, allowance, and reward operations: `PremiumEntitlementTests`, `RecommendationAllowanceTests`, and `RewardedDeckCreditTests`.
- App kill after a durable batch/reservation: `RewardedDeckCreditTests.DurableBatchBeforeAppKill_ReconcilesRewardAsConsumed`; abandoned reservations restore after restart.
- Persisted post-ad observation survives recreation and consumes once: `test/ad_policy_test.dart`.

## Automated result

- Focused Flutter monetization matrix: 96 passed, 0 failed.
- Focused backend Premium/allowance/reward/reporting matrix: 23 passed, 0 failed.
- Full Flutter suite: 290 passed, 0 failed.
- Full backend suite: 117 passed, 0 failed.
- Flutter analyze: 0 errors, 0 warnings, 42 existing informational diagnostics.
- Dart format gate: 115 files checked, 0 changed.
- Backend Release build: succeeded with 0 errors and the known .NET 7 lifecycle warning.
- Both repository diff checks: passed; line-ending notices only.
- Configured debug APK: 200,394,851 bytes; SHA-256 `B00A1CF8A79EE729BEF17994AA6A4969581B543856939D3A4F0B4E88AA4B2798`.

## Real local-API acceptance

Device: Android `Medium_Phone`, 1080x2340 at density 402 (approximately 430x930 logical), primary 1.0x text and secondary 1.25x text.

- A fresh incognito profile loaded 40 real starter choices and persisted 10 ratings.
- One fresh 10-item deck generated against `http://10.0.2.2:5000/`.
- Cards 1-9 remained inside the active deck; deliberate Finish at 10/10 reached `Deck complete` immediately without ad/loading delay.
- Safe missing remote monetization config and first-session policy produced no ad surface or blank reservation.
- SQL state matched the expected transaction: 10 ratings, one recommendation batch/session, 10 history rows, one committed free allowance reservation, zero reward credits.
- At 1.25x text, the completion card, primary action, secondary action, and filter chrome remained readable and unclipped.
- With the run-owned API stopped, a cold launch preserved the 10-rating MovieDNA state, showed the truthful offline banner, kept navigation/library affordances available, and rendered no monetization failure UI.
- Online/offline app log scans found no MovieDiary fatal exception, app ANR, FlutterError, RenderFlex, unhandled exception, or lost-device marker. One cold emulator System UI ANR was recovered with Wait and excluded as host noise.
- The exact disposable guest was soft-deleted under ID/incognito/creation-window guards, its one refresh token was removed, app data was cleared, and font scale was restored to 1.0.

Evidence: `qa-screenshots/uxr77-monetization-matrix-20260825/UXR77-EVIDENCE.md`.

## Manual provider boundaries

The following are architectural/manual fallbacks, not uncovered application logic or new defects:

- Signed Google native/interstitial/rewarded test inventory and authoritative SDK callbacks require approved provider units and typed remote configuration, which this automation is not authorized to publish.
- Signed Google Play/App Store purchase and restore receipts require store sandbox accounts and physical/signed builds.
- Regional UMP and iOS ATT behavior requires provider test geography and signed iOS/Android devices.

Provider-neutral fakes and backend serialization tests cover the deterministic application behavior around all three boundaries. These manual checks remain owner retest items inherited from UXR71, UXR74, UXR75, and UXR76; no production flag, credential, unit ID, price, tier, subscription, migration, or deployment setting changed.
