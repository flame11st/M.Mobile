# UXR71 recommendation-completion interstitial policy

## Product boundary

Interstitial policy is invoked only by the explicit `Finish` action on a full
10-of-10 recommendation deck. Reaching or swiping to card 10 does not trigger
monetization. The calm `Deck complete` product state is committed and rendered
before the optional policy call begins. Watchlist, Seen already, rating,
Search, Details, Mark Watched, and tab navigation have no call path to it.

## Persisted policy

`AdPolicyController` owns schema-version-2 encrypted state:

- stable app-session identity and session shown count;
- UTC day bucket, completed-deck count, and shown count;
- last interstitial and recent native/rewarded/Premium-prompt interaction;
- a bounded set of completion IDs for duplicate/process-recreation safety;
- pending placement and post-close exit observation.

The incompatible V1 arbitrary-action/24-hour state is deliberately deleted,
not silently reinterpreted. Default remote rules are first session protected,
first deck of each UTC day protected, 10-minute minimum interval, two shown per
session, and three shown per UTC day. Premium or unresolved entitlement remains
an unconditional application-level suppression.

## Inventory and callback behavior

An eligible upcoming deck may preload through the provider-neutral service.
Completion never starts or awaits a load: only already-ready, consented,
foreground inventory may show. Every unavailable path returns immediately and
records a skip outcome. Native impressions/clicks and Premium-offer display
record the shared adjacency timestamp; rewarded can use the same API when UXR74
wires its real transitions.

Provider show/dismiss callbacks are guarded by one active placement and one
analytics attempt. A duplicate completion ID cannot increment counts or show a
second ad, and duplicate SDK callbacks cannot resume or classify the route
twice. The completed product screen remains the route state before, during, and
after the full-screen overlay.

## Verification contract

- `test/ad_policy_test.dart`: first-session/day protection, exact cooldown
  boundary, session/day caps, UTC rollover, Premium/config/inventory, adjacency,
  duplicate/process state, legacy retirement, and exit recovery.
- `test/recommendations_page_test.dart`: cards 1–9 and viewing 10/10 do not call
  monetization; explicit Finish calls once; completion UI does not wait for the
  fake provider; the source has one completion-policy call site.
- Existing entitlement, config, native placement, analytics, recommendation,
  and Premium tests remain regression gates.

Production flags, ad credentials, deployment configuration, lifetime Premium
price/tier, and rewarded/allowance behavior are unchanged.
