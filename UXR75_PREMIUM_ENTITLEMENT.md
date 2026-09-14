# UXR75 lifetime Premium entitlement

## Contract

- `premium_purchase` remains the only lifetime Premium SKU. Price and store configuration are unchanged.
- A verified purchase or restore writes `lifetimePremiumStoreVerifiedV1`, suppresses all monetization inventory immediately, and then synchronizes the current backend identity with bounded idempotent retries.
- Backend Premium is monotonic: the Premium endpoint accepts only `true`, is bound to the authenticated subject, and repeated grants do not replace the original purchase date.
- Anonymous-to-authenticated identity merge uses Premium-wins semantics and preserves the earliest known purchase date.
- A stored anonymous session refreshes its backend profile on cold start. Until that response resolves, monetization fails closed; a stale response cannot revoke Premium for the same identity.
- When Premium is activated from an allowance-limit prompt, the exact blocked recommendation request resumes automatically.

## Verification boundary

Automated coverage proves backend permanence and identity isolation, app purchase/restore activation, durable cold-start behavior, immediate ad suppression, and exact recommendation retry. The remaining owner retest is a signed Google Play/App Store sandbox purchase and restore on store-capable devices, including an account switch with real receipts.

