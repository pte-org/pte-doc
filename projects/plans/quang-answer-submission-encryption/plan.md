# Plan: Answer Submission Encryption

**Spec:** [spec.md](spec.md)
**Date:** 2026-08-28
**Status:** Ready
**Mode:** Hard
**Test:** --tdd
**Created by:** Plan Agent

---

## Overview

This plan delivers client-side encryption of exam answer submissions for STRICT-integrity attempts, ensuring a student's submitted answer cannot be silently altered between leaving the device and being persisted — even if TLS pinning is bypassed locally. The mechanism asymmetrically wraps a fresh AES-256 key with RSA-OAEP, then symmetrically encrypts the payload with AES-GCM, conditional on the attempt's pinned `answerIntegrityLevel` field (already delivered by the listening-exam-policy feature, Phase 1/4). Encryption is transparent to storage and downstream scoring — only the `SubmitAnswerRequest` wire format changes for STRICT-pinned attempts; persisted payloads and `AnswerSubmittedEvent` stay plaintext as today, unchanged for STANDARD-pinned attempts.

## Phases

- [x] Phase 1: RSA Keypair Provisioning & StartAttempt Public Key Exposure [quality: approved, 0 findings; testing: passed, 29/29] — `exam-delivery` generates/loads its own RSA-2048 keypair (own service, not `iam`'s); `StartAttempt` response carries the public key only when the pinned `answerIntegrityLevel == STRICT`.
- [x] Phase 2: Conditional Submission Routing & Server-Side Decryption [quality: approved, 0 findings; testing: passed, 41/41] — New `EncryptedSubmissionRequest` DTO; `AttemptController` routes by pinned level; RSA-OAEP unwrap + AES-GCM decrypt+verify; any crypto failure → 4xx, no persistence.
- [x] Phase 3: Client-Side Encryption (pte-app, Flutter/Dart) [quality: approved, 1 BLOCKER fixed (crypto exception isolation in SyncEngine); testing: passed, 499/499] — Extend the existing submission path in `sync_engine.dart`/`api_client.dart` to encrypt per submission when the attempt is STRICT-pinned, using the public key delivered at StartAttempt.

**Plan status: COMPLETED — all 3 phases done.**

## Research Summary

Findings from parallel research (Primary: implementation approach; Alternative: scheme validation) — locked, not for re-derivation:

1. **RSA-OAEP + AES-GCM hybrid confirmed sound** against the stated threat model (attacker who has already defeated TLS on the student's own device). HMAC-based integrity was rejected in the spec itself for exactly this reason — any secret transmitted to that same device is exposed to the same attacker. Pure client-side signatures were considered and rejected: they provide integrity but not confidentiality, and the spec wants both. ECDH-derived AES-GCM is a legitimate alternative but adds Dart implementation risk (weaker crypto ecosystem than Java's) for no net security gain over RSA-OAEP — not adopted; the spec's locked choice stands.

2. **`exam-delivery` owns its own RSA keypair** — does not call `iam`'s `RsaKeyProvider` (Nimbus JWK-based) at runtime. Calling another service synchronously for key material at request time would violate this project's already-stated invariant that exam-delivery's only inbound runtime dependency is StartAttempt-time fetches it already makes, and it has no business calling `iam` per-submission. Keypair is generated at startup (dev) or loaded from PEM in config/env (prod; Vault is a future concern per the sibling plan's precedent, not this plan's).

3. **Cross-platform interop is the single highest-risk item.** Dart's `pointycastle` (the de-facto AES-GCM/RSA-OAEP library for Flutter, a BouncyCastle port) defaults RSA-OAEP's MGF1 hash to SHA-1 if not explicitly configured — Java's `OAEPWithSHA-256AndMGF1Padding` will silently fail to decrypt (or throw a padding/block-size error) against a Dart payload encrypted with the library default. Both sides must explicitly pin SHA-256 for both the OAEP digest and the MGF1 digest:
   - Dart: `OAEPEncoding(RSAEngine(), SHA256Digest(), SHA256Digest())`
   - Java: `Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")` initialized with `OAEPParameterSpec("SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT)`

4. **IV sizing is the second highest-risk item.** AES-GCM here uses a 96-bit (12-byte) IV. Dart's `SecureRandom` does not default to 12 bytes — Phase 3 must generate exactly 12 random bytes, not reuse a 16-byte block-cipher-style IV. Phase 2 must defensively reject any IV whose decoded length isn't exactly 12 bytes before attempting decryption.

5. **Wire format** — `EncryptedSubmissionRequest` record: `wrappedKey` (Base64 RSA-OAEP output), `iv` (Base64, 12 bytes), `ciphertext` (Base64 AES-GCM output, auth tag included per the JCE/pointycastle convention of appending the tag to the ciphertext). All three `@NotBlank`. Matches the existing codebase's plain-record DTO style (no existing crypto-specific DTO precedent in `exam-delivery` to diverge from).

6. **Auth-tag / unwrap failure → 4xx, never 500, never persisted.** Java's `AEADBadTagException` (GCM auth failure) and RSA unwrap failures must both be caught and mapped to a 4xx response before any `AttemptAnswer` row is written or `AnswerSubmittedEvent` emitted.

7. **Flagged integration risk (not a spec gap — a plan-time note):** the spec does not explicitly define replay-of-a-valid-encrypted-submission protection. This is not being added as a new requirement; Phase 2 must verify whether `exam-delivery` already has a submission-uniqueness constraint (e.g., one answer row per `attempt_id` + `item_id`, upsert-on-retry) that incidentally prevents replay from mattering, and add a test case confirming it. If no such constraint exists, that is a pre-existing gap unrelated to encryption and out of this plan's scope to fix — only to verify and document.

## Dependencies

- `quang-listening-exam-policy` plan — **COMPLETED** (all 6 phases). Provides `answerIntegrityLevel` (STANDARD|STRICT) already pinned onto `PinnedExamSnapshot` at `StartAttempt`. This plan consumes that field; does not redefine it.
- Existing `exam-delivery` service: `AttemptService`, `AttemptController`, `ExamAttempt`/`PinnedExamSnapshot` entities, existing plain-`payload` `SubmitAnswerRequest` DTO and persistence path.
- Existing `pte-app` (Flutter) submission path: `lib/core/network/api_client.dart`, `lib/core/sync/sync_engine.dart` — encryption slots into this existing flow, does not replace the sync/retry mechanics.
- Java: `javax.crypto.Cipher`, `java.security.KeyFactory`/`KeyPairGenerator` (standard JDK — no new Maven dependency needed for RSA-OAEP/AES-GCM).
- Dart: `pointycastle` package (added to `pte-app/pubspec.yaml` if not already present — verify during Phase 3).

## Risks

- **HIGH — Dart↔Java OAEP hash mismatch**: pointycastle's default MGF1 digest is SHA-1, not SHA-256. If Phase 3 doesn't explicitly configure `OAEPEncoding(RSAEngine(), SHA256Digest(), SHA256Digest())`, every submission from the client will fail to unwrap on the server (100% failure, not intermittent). Mitigation: Phase 2 and Phase 3 both pin SHA-256 explicitly on both sides; add a same-day cross-platform round-trip test (encrypt in Dart test, decrypt in a Java test using a fixed test keypair, or vice versa) before considering either phase done.
- **HIGH — IV length mismatch**: if Dart generates a 16-byte IV instead of 12, GCM either fails outright or (worse, on some implementations) silently produces wrong plaintext without an auth-tag error, which is a much harder bug to catch. Mitigation: Phase 2 validates decoded IV length == 12 bytes and rejects (4xx) before decryption; Phase 3 explicitly sizes the IV generator to 12 bytes; add a unit test asserting IV byte length.
- **MEDIUM — Replay of a previously-valid submission**: see Research Summary point 7. Mitigation: Phase 2 step includes verifying/documenting the existing uniqueness constraint; add a test submitting the same valid encrypted payload twice and asserting the second is handled per whatever the existing (pre-encryption) retry semantics already are — this plan must not change retry semantics, only confirm they still hold.
- **MEDIUM — Partial deployment ordering**: Phase 2 depends on Phase 1's public key being present in `StartAttempt` responses; Phase 3 depends on both. Deploying Phase 2 or 3 ahead of their dependency leaves STRICT-pinned clients unable to submit (no public key to encrypt with, or server can't decrypt). Mitigation: cook and deploy strictly in order 1 → 2 → 3; do not deploy Phase 2 until Phase 1 is live; do not ship a pte-app release with Phase 3 until Phase 2 is live in the target environment.
- **LOW — Private key exposure via logs**: any accidental `toString()`/logging of the loaded `PrivateKey`, the unwrapped AES key, or request bodies containing `wrappedKey` at DEBUG level could leak key material to log aggregators. Mitigation: Phase 1/2 code review gate explicitly checks no key material appears in any log statement or exception message; use structured exceptions that omit payload/key fields.
- **NOTED (out-of-scope, acknowledged)**: `AnswerSubmittedEvent`'s plaintext `correctAnswerText`/`optionsJson` leak (separate finding, not this spec) and at-rest DB encryption of `payload` remain unaddressed — this plan's "storage/event contract unchanged" is intentional per spec's Out of Scope section, not an oversight.

### Cook-time infra note (applies to all 3 phases)

Same limitation as `quang-listening-exam-policy`: `ck:quality`'s receipt mechanism requires one git repo covering both the quality report and every reviewed file, but this project spans 4 separate repos (`pte-api`, `pte-app`, `pte-web`, `pte-doc`) under a non-repo parent. Cryptographic receipts are skipped for this plan too; each phase's `## Quality and Testing State` records the `ck:quality --gate` result directly, with the JSON report saved under `quality/{phase}-quality-report.json` in this plan directory.

### Red-team review

Run via `plan-reviewer`. Verdict: **WARN** — no CRITICAL findings. 4 ACCEPTED findings were applied directly to the phase files: Base64-decode exception handling in Phase 2 Step 3, a runtime (not just documentation) guard against ephemeral-key generation outside dev in Phase 1, mandatory PEM line-ending normalization in Phase 1 Step 2, and a Phase 1→Phase 3 public-key-format interop pre-check in Phase 1 Step 7a. Remaining findings, NOTED here (acknowledged, not blocking):

- **StartAttempt auth is assumed, not re-verified**: Phase 1 assumes `StartAttempt` is already properly auth-gated (student can only start/read their own attempt) — this phase does not change or need to change that; if it somehow isn't already enforced, exposing the public key isn't the vulnerability, unauthenticated attempt access already would be.
- **Missing/null `answerIntegrityLevel` defaults to STANDARD**: if a pinned snapshot somehow has a null integrity level, Phase 2's routing must treat it as STANDARD (accept plain-`payload` only) rather than erroring or defaulting to STRICT — call this out explicitly during Phase 2 implementation review.
- **No runtime guard against out-of-order phase deployment**: mitigated procedurally only (strict cook/deploy order 1→2→3, stated in Cook Order Recommendation). Before shipping Phase 2, manually verify Phase 1 is live (StartAttempt on a STRICT attempt returns a public key) in the target environment; before shipping Phase 3, manually verify Phase 2 is live (an encrypted submission round-trips end-to-end) in the target environment.
- **Private-key-in-logs prevention is a code-review gate, not an automated one**: acceptable for this project's scale; no lint/annotation tooling is being introduced for this alone.
- **OAEP padding-source (`PSource.PSpecified.DEFAULT`) parity between Java and pointycastle**: expected to match by default on both sides, but Phase 3 Step 9's cross-platform interop test is the actual verification — treat that test, not this note, as the source of truth.
- **listening-exam-policy's actual field name/enum values for `answerIntegrityLevel` should be confirmed against the live codebase** (not just the sibling plan's description) at the start of Phase 1 implementation, in case anything drifted since that plan completed.

---

## Cook Order Recommendation

Phases must be cooked in strict sequence — each phase depends on the prior one being live, not just merged:

1. Phase 1 (`exam-delivery` RSA keypair + StartAttempt exposure) — unblocks Phase 2 and Phase 3
2. Phase 2 (`exam-delivery` conditional routing + decryption) — unblocks Phase 3 end-to-end verification
3. Phase 3 (`pte-app` client-side encryption) — feature complete

Suggested invocation:

```
/ck:cook pte-doc/projects/plans/quang-answer-submission-encryption/phase-01-rsa-keypair-startattempt.md
/ck:cook pte-doc/projects/plans/quang-answer-submission-encryption/phase-02-conditional-routing-decryption.md
/ck:cook pte-doc/projects/plans/quang-answer-submission-encryption/phase-03-client-side-encryption.md
```
