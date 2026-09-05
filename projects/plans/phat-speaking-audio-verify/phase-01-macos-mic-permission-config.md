# Phase 1: macOS Mic Permission Config

## Requirements
A future macOS build of pte-app must be able to request and receive microphone access under App Sandbox — today it will hard-fail because required Info.plist and entitlement keys are missing. Maps to spec P1 story: "As the developer, I want macOS's Info.plist and entitlements to declare the microphone usage keys required by App Sandbox, so that a future macOS build doesn't hard-fail on mic permission" (FR-01, FR-02).

## Steps
1. Add an `NSMicrophoneUsageDescription` key to `macos/Runner/Info.plist` with the exact value: `"This app needs microphone access to record your spoken answers during PTE speaking exam tasks."` (confirmed by the developer — not a generic/placeholder string, per spec NFR on notarization review).
2. Add `com.apple.security.device.audio-input` set to `true` in `macos/Runner/DebugProfile.entitlements`, alongside the existing `com.apple.security.app-sandbox` key (leave the other existing keys, e.g. `com.apple.security.cs.allow-jit` and `com.apple.security.network.server`, untouched).
3. Add the same `com.apple.security.device.audio-input` = `true` entitlement to `macos/Runner/Release.entitlements`, alongside its existing `com.apple.security.app-sandbox` key.
4. Visually confirm all three edited files remain well-formed plist/XML (same DOCTYPE/`<plist>` structure already present) and that no unrelated keys were changed or removed.
5. Run `flutter analyze` from `pte-app` to confirm nothing else broke (this only checks Dart, so plist well-formedness is confirmed by step 4, not by this command).

## Success Criteria
- `macos/Runner/Info.plist` contains `NSMicrophoneUsageDescription` with a non-empty, purpose-specific string mentioning speaking-exam recording.
- `macos/Runner/DebugProfile.entitlements` contains `com.apple.security.device.audio-input` = `true`.
- `macos/Runner/Release.entitlements` contains `com.apple.security.device.audio-input` = `true`.
- `flutter analyze` exits with no new errors.
- All three files remain valid, well-formed plist XML with no unrelated keys altered.

## Risks
- Cannot be build- or run-verified on real macOS hardware this round: mitigation — keys/values follow Apple's documented App Sandbox microphone requirements used by AVFoundation-based recorders (matches spec Assumptions); flagged as a residual risk in plan.md, to be confirmed once a macOS device/teammate is available.
- A vague or placeholder usage string could fail App Store/notarization review later: mitigation — the string explicitly names the speaking-exam recording purpose, per the spec's NFR on security/review.
