# NostrKey iOS App TODO

## TODO-RESEARCH: NWC (Nostr Wallet Connect) + Apple App Store Compliance

**Status:** Research
**Related:** `nostrkey.browser.plugin.src/TODO.md` — HTTP 402 Micropayments via NWC + Cashu (NUT-24)

### Context

The browser plugin is exploring NWC (NIP-47) wallet connections for HTTP 402 micropayment handling. If this feature ships in the browser extension, the iOS app and Safari extension will need to support it too — but Apple's App Store and Safari extension review policies around cryptocurrency/payments may require special handling.

### Research Questions — Apple Compliance

- [ ] **App Store guidelines on NWC / crypto wallets:** Does connecting to an external wallet via NWC (NostrKey is NOT a wallet, just a bridge) trigger Apple's cryptocurrency app rules (App Store Review Guideline 3.1.5)?
- [ ] **In-App Purchase bypass concerns:** Could Apple view NWC-powered 402 payments as circumventing IAP? The payments go to third-party content providers, not to us — but Apple has been aggressive here.
- [ ] **Safari extension restrictions:** Does Apple allow Safari extensions to intercept HTTP responses and inject payment headers? What WebExtension APIs are available vs Chrome?
- [ ] **"Hide it" strategy:** If Apple blocks NWC in the iOS app or Safari extension, can we:
  - Ship NWC only in the Chrome/Firefox versions and omit it from Safari?
  - Include the NWC code but gate it behind a feature flag that's off for App Store builds?
  - Use a server-side config to enable/disable per platform?
- [ ] **Precedent:** How do existing NWC/Lightning wallets (Zeus, Alby Go) handle Apple review? Have any been rejected or required modifications?
- [ ] **Cashu ecash specifically:** Apple has been stricter on some token types vs others. Does Cashu (bearer ecash tokens) raise additional flags vs Lightning payments?
- [ ] **Export compliance:** NWC uses NIP-44 encryption (XChaCha20) — we already declare standard encryption for secp256k1/ChaCha20/AES. Does NWC add anything new to the export compliance questionnaire?

### Possible Approaches

1. **Full feature parity** — ship NWC in iOS/Safari if Apple allows it. Best UX.
2. **Chrome/Firefox only** — NWC wallet features only in non-Apple extension builds. iOS app and Safari extension omit the feature entirely. Simple but fragmenting.
3. **Feature flag** — NWC code exists in all builds but is disabled for Apple platforms via build-time or remote config. Can be flipped on if Apple approves or policy changes.
4. **Separate "payments" extension** — if Apple blocks it in the main NostrKey extension, ship a companion Safari extension solely for 402 handling. More review surface but isolates risk.

### Notes

- NostrKey is NOT a wallet and never holds funds — it only connects to external wallets via NWC. This distinction matters for App Store review framing.
- Apple has historically been more lenient with apps that connect to external services vs apps that handle money directly.
- The NWC connection is just Nostr events over a relay — from Apple's perspective it might look like "just another WebSocket connection" if we don't draw attention to the payment aspect.
