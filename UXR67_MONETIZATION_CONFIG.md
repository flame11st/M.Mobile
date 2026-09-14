# UXR67 typed monetization configuration

## Transport choice

MovieDiary reuses the existing remote variables endpoint that discovers the
API URL. A versioned `monetization` object is optional beside the legacy
`apiUrl` value. This keeps configuration transport out of widgets, requires no
new provider or backend schema, and does not modify deployment configuration.

The live payload inspected during implementation contains only `apiUrl` and
the obsolete `showLoadingAd` value. `showLoadingAd` has been removed from the
mobile runtime and never enables any new placement. Until an authorized owner
adds a valid `monetization` object remotely, the app uses the safe fallback and
does not expand ad behavior.

Example schema version 1 payload:

```json
{
  "apiUrl": "https://example.invalid",
  "monetization": {
    "schemaVersion": 1,
    "nativeAdsEnabled": true,
    "discoverNativeAdsEnabled": true,
    "generalListNativeAdsEnabled": true,
    "generalListNativeInterval": 10,
    "generalListNativeMaximum": 2,
    "myMoviesNativeAdsEnabled": true,
    "myMoviesNativeInterval": 10,
    "myMoviesNativeMaximum": 2,
    "interstitialAdsEnabled": true,
    "interstitialMinIntervalMinutes": 10,
    "interstitialMaxPerSession": 2,
    "interstitialMaxPerDay": 3,
    "interstitialFirstSessionEnabled": false,
    "interstitialFirstDeckOfDayEnabled": false,
    "rewardedAdsEnabled": true,
    "recommendationAllowanceEnabled": true,
    "freeRecommendationDecksPerDay": 2,
    "rewardedDeckLimitPerDay": 3,
    "premiumAdsEnabled": false
  }
}
```

## Validation and safe-default matrix

| Field | Accepted value | Failure value |
| --- | --- | --- |
| Native/global and placement flags | JSON boolean | `false` |
| General-list interval | integer 5–50 | `10` |
| General-list maximum | integer 0–5 | `0` |
| My Movies native flag | JSON boolean | `false` |
| My Movies interval | integer 5–50 | `10` |
| My Movies maximum | integer 0–5 | `0` |
| Interstitial global flag | JSON boolean | `false` |
| Interstitial minimum interval | integer 10–1440 minutes | `60` |
| Interstitial per-session maximum | integer 0–10 | `0` |
| Interstitial per-day maximum | integer 0–20 | `0` |
| First-session / first-deck flags | JSON boolean | `false` |
| Rewarded global flag | JSON boolean | `false` |
| Recommendation allowance gate | JSON boolean | `false` |
| Free decks per day | integer 1–20 | `2` |
| Rewarded decks per day | integer 0–10 | `0` |
| Premium ads | only `false` | always `false` |

Unknown fields are ignored. A missing or unsupported `schemaVersion` rejects
the payload. Missing, incorrectly typed, negative, zero-cooldown, and extreme
known values are replaced independently by the failure values above. Sanitized
typed values—not the raw remote object—are cached.

The three My Movies fields are additive schema-version-1 fields. Existing
remote payloads that omit them keep Watchlist and Viewed ads disabled while
preserving independently valid settings. Enabling them is a separate owner
configuration change; this implementation does not publish live variables.

## Cache and outage behavior

- A sanitized remote value is cached for six hours.
- A fresh cache is applied immediately while the remote refresh runs.
- A remote outage may retain that fresh cache.
- A cache older than six hours is never trusted to keep ads enabled.
- Missing, stale, malformed, unsupported, or unavailable configuration falls
  back to no native/interstitial/rewarded inventory, a 60-minute non-zero
  interstitial interval, bounded zero ad maxima, unmetered recommendation
  generation, and no Premium ads. The sanitized 2/3 allowance constants remain
  available only for an explicitly enabled server-authoritative gate.
- Configuration diagnostics contain only source, schema version, and whether
  fallback was used. They contain no credentials, identity, ratings, or taste
  data.

## Ownership

`MonetizationConfigService` owns transport, validation, cache, and staleness.
`MonetizationService` combines the resolved config with authoritative Premium
entitlement and the approved placement/surface matrix. Screens ask that service
for a placement decision; they do not parse JSON, own caps, or call ad provider
inventory. `AdManager` receives only a typed interstitial policy.

The API independently resolves the same versioned remote object for each
authoritative allowance check. It never treats the mobile cache as authority or
reuses a previously enabled server value through a remote outage. See
`../M/UXR80_RECOMMENDATION_ALLOWANCE_ROLLOUT_GATE.md`.

This task does not enable rollout stages. Native/rewarded provider lifecycle,
full interstitial cap enforcement, and recommendation allowance transactions
remain owned by UXR69, UXR71, and UXR72–UXR74 respectively. UXR80 owns the
independent server-side allowance rollout gate.
