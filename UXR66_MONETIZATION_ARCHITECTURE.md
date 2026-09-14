# UXR66 centralized entitlement and placement policy

MovieDiary keeps the existing one-time lifetime Premium product and backend
`PremiumPurchased` field. `MonetizationService` is the observable
application-level decision source. `UserState` hydrates it from the cached
backend profile, refreshes it from `GetUserInfo`, and updates it immediately on
purchase or restore. During account changes or an unresolved entitlement, the
service fails closed: provider inventory is disposed/suppressed and no
placement is eligible.

## Placement contract

Only four product placements exist:

- `discover_native` on the Discover browsing feed.
- `general_list_native` on General/public list browsing.
- `watchlist_native` on My Movies Watchlist after displayed content 10/20.
- `viewed_native` on filtered/sorted My Movies Viewed after displayed content
  10/20.
- `recommendation_deck_completed_interstitial` at the completed-deck boundary.
- `extra_recommendation_rewarded` at the explicit allowance exchange.

This task does not enable the future native or rewarded placements. Typed
configuration, provider lifecycle, allowance, and frequency rules remain owned
by UXR67–UXR75. The current interstitial keeps its existing behavior behind the
same provider-isolated `AdManager` and `AdPolicyController`.

## Absolute ad-free zones

Onboarding/authentication, Rate Movies, MovieDNA, an active recommendation
deck, recommendation history, Search, My Movies/Watchlist/Viewed, Movie
Details/Where to Watch, Settings, personal Lists, purchase/rating sheets, and
Mark Watched are denied in product policy before config, frequency, allowance,
consent, or provider readiness is considered.

## Ownership boundary

- Widgets request a product decision through `MonetizationService`; they do not
  import `AdManager`, own SDK calls, or contain provider/frequency rules.
- `MonetizationService` owns resolved entitlement and the product
  placement/surface allowlist.
- `AdPolicyController` retains current interstitial frequency and persisted
  eligibility until UXR67/UXR71 replace it with the planned typed policy.
- `AdManager` owns Google Mobile Ads initialization, inventory, callbacks,
  consent, disposal, and focus/lifecycle restoration.
- Backend `User.PremiumPurchased` remains the durable entitlement source.

## Entitlement lifecycle

1. Cold start reads the cached backend user/guest entitlement. Authenticated
   profiles are refreshed in the background.
2. Account switches enter unresolved state before new credentials/profile data
   are applied, preventing inventory from the previous account from surviving.
3. Purchase/restore changes the application decision synchronously, then
   disposes/invalidates provider inventory and persists/synchronizes the
   existing entitlement path.
4. Logout returns to unresolved/ad-free state until the next guest or account
   profile resolves.

No subscription, tier, price, deployment configuration, recommendation limit,
or new ad placement is introduced by UXR66.
