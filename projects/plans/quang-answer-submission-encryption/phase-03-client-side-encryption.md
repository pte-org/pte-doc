# Phase 3: Client-Side Encryption (pte-app, Flutter/Dart)

**Covers:** FR-02, FR-06, FR-07 · User stories: P1 (tamper-evident submission from the student's device), P2 (fresh AES key/IV per submission), P1 (STANDARD-mode students unaffected)
**Depends on:** Phase 1 (public key delivered via StartAttempt), Phase 2 (server accepts and correctly decrypts `EncryptedSubmissionRequest`)

---

## Requirements

`pte-app` generates a fresh random AES-256 key and 96-bit IV for every submission on a STRICT-pinned attempt, encrypts the answer payload with AES-GCM, wraps the AES key with RSA-OAEP using the public key delivered in the `StartAttempt` response (Phase 1), and sends `wrappedKey`/`iv`/`ciphertext` instead of plain `payload`. STANDARD-pinned attempts continue submitting exactly as today — this phase must not add any encryption code to that path. This slots into the existing submission flow in `sync_engine.dart`/`api_client.dart`, not a parallel/replacement submission mechanism.

Maps to: **P1 Story #1 (tamper detection from the client's own encryption), P2 Story #3 (fresh key/IV per submission, verifiably distinct), P1 Story #4 (STANDARD-mode students submit unchanged)**.

---

## Design Constraints

**Preflight (verified against the actual installed `pointycastle: ^3.9.1` source in `pub-cache`, not assumed from generic docs):**

- **`OAEPEncoding` has no 3-arg `(engine, digest, mgf1Digest)` constructor in this version.** Its only constructors are `OAEPEncoding(engine, [encodingParams])` (defaults to SHA-1), `OAEPEncoding.withSHA1(engine, [encodingParams])`, `OAEPEncoding.withSHA256(engine, [encodingParams])`, and `.withCustomDigest(...)`. Critically, `OAEPEncoding.init()` unconditionally sets `mgf1Hash = hash` — **this pointycastle version structurally guarantees MGF1 always matches the OAEP digest**, so the "#1 interop pitfall" from generic research (MGF1 defaulting to SHA-1 independently of the main digest) cannot actually happen here. Use `OAEPEncoding.withSHA256(RSAEngine())` — this alone gives SHA-256 for both digest and MGF1, matching Java's `OAEPWithSHA-256AndMGF1Padding` exactly.
- **RSA public key parsing** (Base64 X.509 SubjectPublicKeyInfo, as Phase 1 outputs): `pointycastle` has no one-line PEM/DER-to-`RSAPublicKey` helper; parse manually via `package:pointycastle/asn1.dart`'s `ASN1Parser`: top-level DER bytes → `ASN1Sequence` → `elements[1]` is an `ASN1BitString` whose `.stringValues` (a `List<int>`, unused-bits byte already stripped) is itself a DER-encoded `ASN1Sequence(modulus INTEGER, publicExponent INTEGER)` → build `RSAPublicKey(modulus, exponent)` from those two `ASN1Integer.integer!` (`BigInt`) values. This is the standard, verified-correct pattern for this package version.
- **AES-GCM**: `GCMBlockCipher(AESEngine())`, initialized with `AEADParameters(KeyParameter(aesKeyBytes), 128, ivBytes, Uint8List(0))` — constructor order is `(parameters, macSize, nonce, associatedData)`, `macSize` in **bits** (128), empty `Uint8List(0)` for associated data (none used here). `.process(plaintextBytes)` returns ciphertext with the GCM tag appended at the end — matching Java's `Cipher.doFinal` convention on the server side exactly, no extra handling needed.
- **RSA-OAEP wrap**: `OAEPEncoding.withSHA256(RSAEngine())`, initialized with `ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey), secureRandom)`, then `.process(aesKeyBytes)` returns the wrapped key bytes.
- **Secure randomness**: `pointycastle`'s `FortunaRandom` requires an explicit 32-byte seed via `.seed(KeyParameter(seedBytes))` before use — it is not self-seeding. Seed it from `dart:math`'s `Random.secure()` (the standard, verified pattern): generate 32 random bytes via `Random.secure().nextInt(256)` in a loop, wrap in `KeyParameter`. Generate the AES key as `random.nextBytes(32)` and the IV as `random.nextBytes(12)` from that same seeded `FortunaRandom` — **12, not pointycastle's block-size default** (AES block size is 16; an unexamined default would produce a 16-byte IV, which Phase 2's server-side validation explicitly rejects).
- **Client wiring points** (verified against current source, not the plan's original generic description): the Dart response type mirroring the server's `AttemptTaskResponse` is `pte-app/lib/features/exam_attempt/domain/task_view.dart`'s `AttemptTaskResponse` class — add `encryptionPublicKey` (nullable `String`) there, parsed from `json['encryptionPublicKey']`. There is **no separate `answerIntegrityLevel` field to add** — the server's `AttemptTaskResponse` only ever sends a non-null `encryptionPublicKey` when the attempt is STRICT-pinned (Phase 1), so its presence alone is the client's signal to encrypt; do not invent a second boolean field. `SyncEngine` (`pte-app/lib/core/sync/sync_engine.dart`) is the single place answers are actually submitted, via its private `_flushOne`, which currently calls `_apiClient.submitAnswer(...)` unconditionally — branch there on whether this `SyncEngine` instance was armed with a public key. `SyncEngine.startSync(attemptPublicId)` is called exactly once, from `pte-app/lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart` line ~95 (`_onSessionResolutionRequested`), immediately after `startOrResumeAttempt` — that call site is where `response.encryptionPublicKey` must be threaded through into `startSync`. `ApiClient.submitAnswer` (`pte-app/lib/core/network/api_client.dart`) is the existing plain-payload call and its 409-remap pattern (`ConflictException` → `NotCurrentTaskException`/`ResponseWindowExpiredException` by inspecting `e.message`) is exactly what the new `submitEncryptedAnswer` method should reuse verbatim — same remap, different endpoint/body. `pte-app/lib/core/storage/tables/answer_outbox_table.dart`'s `payload` column stays the plaintext answer exactly as today (Design Constraints already state this — confirmed no schema change needed); encryption happens transiently in `SyncEngine._flushOne` right before the network call, never persisted encrypted.
- `pointycastle: ^3.9.1` added to `pte-app/pubspec.yaml`; `flutter pub get` already run and resolves cleanly against this repo's existing dependency set (Dio 5.9.2, Drift 2.34.0, etc. — no conflicts).
- File-size limit (300 lines) means the new `EncryptionHelper` belongs in its own file, `pte-app/lib/core/crypto/encryption_helper.dart` (new `core/crypto/` directory, mirroring `core/network/`, `core/storage/` — shared infra, not feature-scoped).


- Use `pointycastle` (verify it's already in `pte-app/pubspec.yaml`; add it if not) — the established Flutter/Dart library for both AES-GCM and RSA-OAEP, mirroring the BouncyCastle model the JVM side effectively uses.
- **RSA-OAEP must explicitly configure SHA-256 for both the OAEP digest and the MGF1 digest**: `OAEPEncoding(RSAEngine(), SHA256Digest(), SHA256Digest())`. Do not rely on `OAEPEncoding`'s default constructor — its implicit default is SHA-1 for MGF1, which will fail to interop with Phase 2's `OAEPWithSHA-256AndMGF1Padding` on every single submission (100% failure, not intermittent).
- **IV must be exactly 12 bytes (96 bits)**, generated fresh per submission via a cryptographically secure random source — do not reuse a 16-byte block-size default from a generic secure-random helper.
- AES key must be exactly 32 bytes (256 bits), generated fresh per submission — never cached, never reused across submissions or retries of the same task.
- Parse the server's public key from the `encryptionPublicKey` field delivered at `StartAttempt` (Base64 X.509 SubjectPublicKeyInfo, per Phase 1's output format) using pointycastle's key-parsing utilities — coordinate the exact parsing approach with however Phase 1 encoded the key if any mismatch surfaces during implementation.
- This logic must only run for STRICT-pinned attempts (checked from the attempt snapshot already held client-side after `StartAttempt`, same place `answerIntegrityLevel`/other pinned policy fields are already consulted for other listening-exam-policy behaviors) — STANDARD-pinned attempts must take a code path that never touches this new encryption logic.
- Encryption failures on the client (e.g., malformed/missing public key) must surface as a clear submission error through the existing sync/retry error-handling path in `sync_engine.dart`, not a silent fallback to plain-`payload` submission — a STRICT attempt must never silently downgrade to STANDARD's wire format.

---

## Steps

1. Confirm `pointycastle` is present in `pte-app/pubspec.yaml`; add it if missing and run the package's normal dependency-install step for this repo.

2. Create an `EncryptionHelper` (or similarly named) utility class in `pte-app/lib/core` with: a method to parse the server's Base64 X.509 public key into a pointycastle `RSAPublicKey`; a method to generate a fresh 32-byte AES key and 12-byte IV via a `SecureRandom` seeded appropriately (pointycastle's `FortunaRandom` or platform-appropriate secure RNG, seeded per pointycastle's documented seeding pattern — do not use a non-cryptographic RNG); a method to AES-GCM-encrypt a plaintext payload given the key/IV, returning ciphertext (with GCM tag appended, matching the convention Phase 2 expects); a method to RSA-OAEP-wrap the AES key with the parsed public key using the explicit SHA-256/MGF1-SHA256 configuration above.

3. Create a Dart-side `EncryptedSubmissionRequest` model (`wrappedKey`, `iv`, `ciphertext`, all Base64 strings) mirroring Phase 2's server-side DTO, with the same field names for direct JSON serialization compatibility.

4. In the code path that currently builds and sends `SubmitAnswerRequest` (in `api_client.dart` and/or `sync_engine.dart`'s flush logic), branch on the current attempt's pinned `answerIntegrityLevel`: STANDARD → existing plain-`payload` request, completely unchanged; STRICT → build `EncryptedSubmissionRequest` via `EncryptionHelper` using the public key already retrieved and stored from `StartAttempt`, then send that instead.

5. Ensure the public key retrieved at `StartAttempt` is stored on whatever client-side model already holds other pinned attempt/policy fields (the same place `answerIntegrityLevel` and other listening-exam-policy pinned fields already live) — do not introduce a separate ad hoc storage location for just this one field.

6. Ensure a missing/unparseable public key on a STRICT-pinned attempt produces a clear, user/ops-visible error through the existing sync error-handling path — not a silent submission failure or fallback.

7. Unit test: `EncryptionHelper` generates a key/IV pair, encrypts a known plaintext, and decrypts it with the same key/IV using the same library (self-consistency check on the Dart side alone).

8. Unit test: assert generated IV is exactly 12 bytes and generated AES key is exactly 32 bytes on every call; assert two consecutive calls produce different keys and different IVs (guards against a reuse regression).

9. **Cross-platform interop test (critical — do not skip)**: using a fixed test RSA keypair shared between the Dart and Java test suites (or a documented equivalent fixture), encrypt a known plaintext in a Dart test and decrypt it in a Java test asserting the plaintext matches (using Phase 2's `SubmissionDecryptionService`); this is the test that would have caught the MGF1 SHA-1-default pitfall had it been missed.

10. Integration test: submit an answer on a STRICT-pinned attempt end-to-end against a running `exam-delivery` (or its test double) and confirm the server accepts and correctly persists the decrypted answer; submit an answer on a STANDARD-pinned attempt and confirm the request body sent is unchanged from pre-Phase-3 behavior (byte-for-byte or field-for-field comparison against the existing plain-payload contract).

---

## Success Criteria

- Two submissions never reuse the same AES key or IV. *(spec success criterion, verbatim — verified by unit test in Step 8)*
- A STRICT-pinned attempt's submission is correctly decrypted end-to-end by the server (Phase 2), confirmed via the cross-platform interop test (Step 9) and integration test (Step 10).
- A STANDARD-pinned attempt's submission is byte-for-byte/field-for-field identical to its pre-Phase-3 request shape.
- No fallback path exists where a STRICT-pinned attempt silently submits in plain-`payload` form on encryption failure.

---

## Quality and Testing State

- Quality: **approved**, 1 BLOCKER found and fixed during gate (report: `quality/phase-03-client-side-encryption-quality-report.json`, receipt: `quality/phase-03-client-side-encryption-receipt.json`). Finding: `_encryptionHelper.encrypt()` inside `_flushOne` could throw uncaught past the `ApiException`-only catch chain, crashing `_flush`'s loop for other pending rows. Fixed via a dedicated `_encryptAnswer` helper that isolates crypto failures, marks the row terminal-rejected (`ENCRYPTION_FAILED`), and never falls back to the plain-payload path.
- Testing: **passed** (TDD RED→GREEN; report: `tests/phase-03-client-side-encryption-test-report.json`, RED artifact: `tests/phase-03-client-side-encryption-tdd-ready.json`). 499/499 tests pass across the full `pte-app` suite, 0 regressions; `flutter analyze` clean on all changed files.

---

## Risks

- **MGF1 default mismatch (see plan.md Risks — HIGH)**: the single most likely implementation mistake in this phase. Mitigated by Step 2's explicit constructor usage and Step 9's cross-platform test — do not consider this phase done until Step 9 passes against a real Phase 2 decryption call, not just a Dart-side mock.
- **IV length default mismatch (see plan.md Risks — HIGH)**: mitigated by Step 8's explicit length assertion and Phase 2's defensive length check; if pointycastle's chosen secure-random helper has an ergonomic default of 16 bytes, Step 2 must explicitly request 12.
- **Public-key parsing format mismatch**: if Phase 1 delivers the public key in a format pointycastle's standard utilities don't directly parse (e.g., raw DER without PEM headers where a PEM parser is used, or vice versa), Step 2 will need custom parsing glue. Mitigation: coordinate the exact expected format with Phase 1 before starting this phase's implementation; write Step 9's interop test early enough to surface format mismatches before the rest of the phase is built on top of a wrong assumption.
- **Sync/retry interaction with fresh-key-per-attempt semantics**: `sync_engine.dart`'s existing retry logic may re-send a previously-queued submission after a failure; if the retry re-sends the exact same serialized request (same key/IV) rather than regenerating, that's fine (it's the same submission, not a new one) — but if retry logic reconstructs the request from scratch, it must still not regenerate a *different* ciphertext for what the user perceives as "the same submission," since server-side replay/uniqueness handling (Phase 2, Step 10) was only verified against exact-duplicate encrypted requests, not two different valid encryptions of the same plaintext. Mitigation: confirm during implementation whether `sync_engine.dart` caches the serialized request or rebuilds it per retry attempt, and document the chosen behavior explicitly in code comments at the retry call site.
