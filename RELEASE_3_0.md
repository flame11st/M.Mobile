# MovieDiary mobile 3.0 release inventory

## Version and identifiers

- Product version: `3.0.0`; Android/iOS build number: `95`.
- Android application ID and namespace: `com.flame.moviediary`.
- Premium product ID: `premium_purchase`.
- Android and iOS AdMob application/unit IDs are production inventory. Test
  inventory is impossible in release mode; debug ad QA also requires an
  explicit opt-in define.

## Release configuration

- Production API traffic uses the configured remote base URL. The
  `MOVIEDIARY_API_BASE_URL` compile-time override is for deliberate builds;
  local cleartext traffic is permitted only by the Android debug manifest.
- Android signing must come from the ignored `android/key.properties` file or
  `MOVIEDIARY_ANDROID_STORE_FILE`, `MOVIEDIARY_ANDROID_STORE_PASSWORD`,
  `MOVIEDIARY_ANDROID_KEY_ALIAS`, and `MOVIEDIARY_ANDROID_KEY_PASSWORD`.
  Release Gradle tasks fail closed when any field is absent.
- Firebase/Google client files contain client identifiers that ship with the
  application; provider-console package, SHA/callback, and key restrictions
  remain a release-owner check.
- Product analytics is server-stamped and environment/schema isolated. See
  the backend release inventory for the deployed API configuration.

## Repository and artifact policy

- Local signing material, keystores, Flutter build output, logs, and local QA
  screenshots are ignored.
- Batch-specific QA evidence remains intentionally outside Git under
  `qa-screenshots/`; it is referenced from the canonical Notion queue.
- Do not delete legacy routes or widgets solely because a static search finds
  no reference. Removal requires a clean reference scan plus route/runtime or
  regression evidence.

## External release gates

- Rotate the Android keystore passwords because they existed in Git history;
  verify Play App Signing continuity before replacing the upload key.
- Confirm release-signed Android and iOS OAuth, purchase/restore, ad consent
  and live inventory, provider/deep links, account deletion, accessibility,
  and privacy/store disclosures on physical devices.
