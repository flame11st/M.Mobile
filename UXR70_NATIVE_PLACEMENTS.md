# UXR70 approved native placements

MovieDiary owns four native-ad placement types and no others:

- `discover_native` renders once at the first curated section boundary after
  at least six real Popular Movies/TV cards. The existing five-title preview
  cap is preserved, so the normal two-section feed places after ten cards
  rather than splitting Popular TV merely to chase an index. It is never
  placed around MovieDNA, the
  recommendation CTA, or the first viewport.
- `general_list_native` renders after content items 10 and 20 in external
  General/public lists. Personal lists continue to use their original list and
  animation path with zero ad insertion.
- `watchlist_native` and `viewed_native` render independently after displayed
  content items 10 and 20 in My Movies only. Filters, removals, and
  Watchlist-to-Viewed moves recompute these slots from movie content; the ad
  widgets never enter movie counts, indices, swipe/action wrappers, or details
  navigation.

`NativeContentInsertionPlan` maps mixed render indices back to canonical movie
indices for General lists and supplies the same bounded content positions to
My Movies. Ads do not change movie totals, pagination, navigation positions,
or movie analytics. A failed/unavailable placement is a zero-height widget and
reserves no space.

Every visible placement owns a distinct provider-neutral inventory handle.
Entitlement, remote flags, provider lifecycle, and monetization analytics stay
behind `MonetizationService` and `AdManager`; product screens do not import an
ad SDK, unit IDs, or frequency configuration. Premium and unresolved
entitlement states suppress and dispose every handle immediately.

The rollout flags remain remotely controlled and conservative defaults remain
off. Local visual acceptance uses Google's test inventory with:

```text
--dart-define=MOVIEDIARY_AD_ENVIRONMENT=test
--dart-define=MOVIEDIARY_ENABLE_DEBUG_ADS=true
```

Production native unit IDs are intentionally not committed. Existing build
infrastructure may supply `MOVIEDIARY_ANDROID_NATIVE_AD_UNIT_ID` and
`MOVIEDIARY_IOS_NATIVE_AD_UNIT_ID`; absence fails closed with no placeholder or
layout reservation. This implementation does not enable a production flag or
change deployment configuration.
