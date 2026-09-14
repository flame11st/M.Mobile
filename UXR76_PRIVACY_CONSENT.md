# UXR76 privacy, consent, and contextual advertising

Audit date: 2026-08-25 (America/Los_Angeles).

This is an implementation audit, not legal advice. MovieDiary preserves its
existing lifetime Premium product, pricing, placements, provider application
IDs, remote configuration, and deployment settings.

## Authoritative requirements checked

- Apple [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/): ATT is required for cross-company tracking or IDFA access; denial cannot gate app functionality; the app remains responsible for third-party SDK behavior.
- Apple [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), sections 2.5.18 and 5.1.1: advertising must match the app age rating, privacy disclosures must cover third parties, consent must be withdrawable, and permission choices must not gate paid or core functionality.
- Apple [`ATTrackingManager`](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager): authorization is one-time per installation and must be checked again because users can change it in Settings.
- Google [Flutter UMP setup](https://developers.google.com/admob/flutter/privacy): refresh consent information every launch, show required forms, check `canRequestAds`, expose privacy options when required, and avoid duplicate ad requests.
- Google [Flutter IDFA guidance](https://developers.google.com/admob/flutter/privacy/idfa): UMP can sequence the IDFA explanation; ads may still be requested after ATT denial without IDFA.
- Google [EEA/UK/Switzerland disclosure guidance](https://developers.google.com/admob/flutter/privacy/gdpr) and [certified-CMP requirement](https://support.google.com/admob/answer/13554020): applicable traffic needs current disclosures/choices through a certified CMP such as Google UMP.
- Google [US state privacy guidance](https://developers.google.com/admob/flutter/privacy/us-states): UMP writes GPP signals; `rdp=1` is the supported per-request restricted-data-processing signal.
- Google Play [app review preparation](https://support.google.com/googleplay/android-developer/answer/9859455): Play Console declarations, privacy policy, ads, target audience, and Data safety answers must match the shipped SDK behavior.
- Google-maintained [`google_mobile_ads` changelog](https://pub.dev/packages/google_mobile_ads/changelog): the repository currently resolves 5.2.0; current public release is newer. A major SDK upgrade is deliberately not mixed into this privacy state-machine change and must be verified as a separate release dependency before rollout.

## Repository audit before implementation

- Android had no UMP integration and treated consent as granted.
- iOS used ATT as the only consent signal, automatically requested it at the first eligible preload, and treated denied/restricted as no-ad rather than a contextual path.
- Interstitial requests used the ATT gate, but native and rewarded provider requests did not.
- Every format created a plain `AdRequest`; no explicit contextual/RDP request contract existed.
- Settings had no provider privacy-options/revocation entry point.
- `Info.plist` contained the required app ID and ATT purpose key, but the SKAdNetwork array had an invalid duplicate nested key/array. The duplicate wrapper is removed and the purpose text now states personalized-ad use plus the no-taste-data boundary.
- Android contains the AdMob application ID and Internet permission. No advertising ID permission is explicitly added by MovieDiary code.

## Implemented state machine

`AdPrivacyConsentController` is the single consent owner for native,
interstitial, and rewarded inventory.

1. At every process launch it refreshes UMP consent information without
   showing a form or ATT prompt.
2. The first application session is always ad/permission deferred. Rendering
   the real MovieDiary product shell records experience for a future session;
   it does not unlock prompts in the current session.
3. In a later session, the first eligible monetizable boundary may show a UMP
   form only when UMP reports one required. Navigation and recommendation work
   never wait on inventory; unresolved/error paths skip ads.
4. On iOS, a direct delayed ATT request is used only when UMP says no regional
   form is required. When UMP collected a choice, its configured IDFA message
   owns any ATT sequencing. Denied, restricted, not-determined, or unavailable
   ATT uses contextual requests instead of disabling MovieDiary.
5. `canRequestAds=false` means no provider initialization/load. A UMP or
   network failure may use a provider-cached prior choice only in conservative
   contextual mode.
6. Contextual requests set `nonPersonalizedAds=true` and `rdp=1`. Request
   objects contain no keywords, content URLs, ratings, MovieDNA, genres,
   recommendation evidence, user IDs, or preference payloads. UMP-managed
   TCF/GPP values stay in provider-owned storage.
7. Consent/ATT is rechecked after resume and identity/entitlement transitions.
   Losing eligibility suppresses all managed formats and disposes stale native,
   rewarded, and interstitial inventory immediately.
8. Settings exposes **Ad privacy choices**. When UMP requires an entry point,
   it presents the provider form; otherwise it truthfully reports that no
   additional device choice is required.

Premium and unresolved entitlement still override every consent result and
suppress all inventory.

## State and request matrix

| Provider/ATT state | Ad behavior | Request policy | Core MovieDiary |
| --- | --- | --- | --- |
| First session | No ads, no forms, no ATT | No request | Fully usable |
| UMP unresolved/required/error with no valid prior choice | No ads | No request | Fully usable |
| UMP allows requests; Android | Provider-managed TCF/GPP | No MovieDiary targeting payload | Fully usable |
| UMP allows requests; iOS ATT authorized | Provider-managed | No MovieDiary targeting payload | Fully usable |
| UMP allows requests; iOS ATT denied/restricted/not determined | Contextual | NPA + RDP | Fully usable |
| Offline refresh with provider-cached prior eligibility | Contextual | NPA + RDP | Fully usable |
| Consent withdrawal | Dispose/suppress current and future inventory | No incompatible future request | Fully usable |
| Premium/unresolved entitlement | No ads | No request | Fully usable |

## Product/legal and console decisions not guessed in code

- MovieDiary currently has no verified age/DOB classification signal. The app
  does not guess that a user is a child or adult and does not pass TFUA. Before
  production rollout, the owner must confirm the Play target audience/App Store
  age rating and whether a child/teen treatment is legally required. If so,
  implement one authoritative age state and apply it to both UMP parameters and
  Google Mobile Ads request configuration.
- The AdMob account owner must publish and validate applicable European, US
  state, and iOS IDFA messages for both app IDs; select/review ad technology
  partners; and confirm that **Privacy and cookie settings** is enabled where
  required. Code cannot publish account-side messages.
- App Store privacy nutrition labels, Google Play Data safety/Ads/target
  audience declarations, and the public privacy policy must be reconciled to
  the exact signed SDK build before rollout. Those store/deployment edits are
  intentionally outside UXR76.
- Product analytics remains separate from ad targeting. This task changes no
  analytics consent policy and forwards no analytics or taste fields into the
  ad SDK.

## Verification contract

- `test/ad_privacy_consent_test.dart` covers first-session delay, UMP-required,
  authorized/denied/restricted/not-determined/unavailable ATT, offline cached
  state, form failure, privacy withdrawal, unavailable privacy options, and
  request-payload inspection.
- `test/uxr31_premium_settings_test.dart` verifies the required privacy entry
  remains present for Standard and Premium users at medium/large-phone geometry.
- UXR93 observes the existing AdManager snapshot through MonetizationService.
  Settings hides the entire advertising Privacy section when UMP confirms the
  entry is not required. Initial unknown stays hidden; failed/unknown refreshes
  preserve last-known required access without inferring permission to serve ads.
  Duplicate taps share one provider form, whose dismissal is not constrained by
  the network-operation timeout.
- Real UMP QA disables `MOVIEDIARY_AD_PRIVACY_DEVELOPMENT_BYPASS` and may use
  `MOVIEDIARY_UMP_DEBUG_GEOGRAPHY=eea` or `not_eea` on a registered test device.
  Debug geography/test identifiers are ignored in release mode and absent from
  the final normal API debug build. Production AdMob unit IDs remain unchanged.
- Existing ad-policy, native, rewarded, Premium, recommendation, lifecycle,
  and release-hygiene suites remain regression gates.

Signed iOS ATT/UMP presentation, Android UMP geography messages, console-published
GPP/TCF behavior, store metadata, and HTTPS request capture remain owner/device
retest boundaries. Production flags and provider credentials stay unchanged.
