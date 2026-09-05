# Phase 2: Conditional Submission Routing & Server-Side Decryption

**Covers:** FR-02, FR-03, FR-04, FR-05, FR-06 · User stories: P1 (tamper rejection), P1 (private key never crosses network), P2 (fresh key per submission verifiable), P1 (STANDARD unaffected)
**Depends on:** Phase 1 (RSA keypair + public key exposure at StartAttempt)

---

## Requirements

`exam-delivery` accepts a new `EncryptedSubmissionRequest` shape (`wrappedKey`, `iv`, `ciphertext`, all Base64) for STRICT-pinned attempts, alongside the existing plain-`payload` `SubmitAnswerRequest` shape for STANDARD-pinned attempts. The submission endpoint routes by the attempt's pinned `answerIntegrityLevel`, rejecting a request whose shape doesn't match the pinned level (a STRICT attempt submitting plain `payload`, or a STANDARD attempt submitting the encrypted shape, are both rejected). For STRICT submissions: unwrap the AES key with the private key (RSA-OAEP, SHA-256/MGF1-SHA256), decrypt+verify with AES-GCM (128-bit tag, 96-bit IV); any RSA-unwrap failure, IV-length mismatch, or GCM auth-tag failure is rejected with a 4xx **before** any `AttemptAnswer` row is persisted or `AnswerSubmittedEvent` emitted. Decrypted plaintext flows into the exact same persistence/event path STANDARD submissions already use — no change to `AttemptAnswer.payload` storage format or `AnswerSubmittedEvent`'s contract.

Maps to: **P1 Story #1 (tamper detection via auth-tag failure), P1 Story #2 (private key stays server-side), P2 Story #3 (fresh key/IV verifiable per submission — this phase enables verification, actual freshness is a client-side/Phase 3 guarantee), P1 Story #4 (STANDARD-mode attempts unaffected)**.

---

## Design Constraints

**Preflight:** `AttemptController.submitAnswer` binds `@RequestBody SubmitAnswerRequest` as a fixed record type — Spring cannot dynamically deserialize one endpoint into two different shapes, so route by **two distinct endpoints** as this phase file already anticipated: existing `POST /attempts/{publicId}/answers` (plain, STANDARD) stays as-is but must now also reject if the attempt's pinned level is STRICT; new `POST /attempts/{publicId}/answers/encrypted` accepts `EncryptedSubmissionRequest` and rejects if the attempt's pinned level is STANDARD. **Correction to the DTO shape**: `EncryptedSubmissionRequest` must also carry `pinnedItemPublicId` (`@NotNull UUID`, same as `SubmitAnswerRequest`) — the original Step 1 description omitted it, but the server needs it for the same current-task/timer validation `submitAnswer` already does; without it there's no way to know which task the encrypted answer is for. Both endpoints funnel into a shared private `processAnswer(attempt, pinnedItemPublicId, payload)` helper in `AttemptService` (refactored out of today's `submitAnswer` body) so the timer/current-task/response-window/persist/advance logic is written once. **Replay protection is already solved**: `AttemptAnswerRepository`'s existing DB unique constraint on `(attempt, pinned_item)` throws `DataIntegrityViolationException` on a duplicate insert, caught in `AnswerSubmitService.persist()` and rethrown as `AnswerAlreadySubmittedException` (409) — this applies transparently to decrypted plaintext exactly as it does to today's plain submissions; Phase 2's replay/idempotency test cases (Steps 10, 10a) verify this existing behavior holds, they do not add new uniqueness logic. **Exception/message convention**: `DomainException(HttpStatus, String code)` — the `code` string passed to `super()` IS what `GlobalExceptionHandler` returns verbatim as the client-facing `ApiResponse.error(...)` message (see `AnswerAlreadySubmittedException`: `super(HttpStatus.CONFLICT, "ANSWER_ALREADY_SUBMITTED")`). Never pass a raw JCE exception message or any request-field value into that `code` string — always a short constant from `ExamDeliveryConstants`. New exceptions needed: `SubmissionDecryptionException` (maps to 400/`BAD_REQUEST`, code `SUBMISSION_DECRYPTION_FAILED`, no-arg, discards the underlying JCE exception entirely — matches this codebase's existing no-cause-chaining exception style) and `AnswerIntegrityLevelMismatchException` (maps to 409/`CONFLICT` per this codebase's convention for state-mismatch exceptions like `AttemptAlreadyCompleteException`/`AnswerAlreadySubmittedException`, code `ANSWER_INTEGRITY_LEVEL_MISMATCH`). Uncaught exceptions fall through to `GlobalExceptionHandler`'s catch-all → 500 — every JCE exception in the decrypt path (Base64 `IllegalArgumentException`, `InvalidKeyException`, `NoSuchAlgorithmException`, `InvalidAlgorithmParameterException`, `IllegalBlockSizeException`, `BadPaddingException` — note `AEADBadTagException` IS-A `BadPaddingException`, one catch clause covers both unwrap and GCM-tag failures) must be caught and rethrown as `SubmissionDecryptionException` before it can reach that catch-all.


- Do not change `AttemptAnswer`'s storage format or `AnswerSubmittedEvent`'s payload contract — decrypted plaintext is indistinguishable from a STANDARD submission's plaintext once past the decryption boundary.
- Request-shape routing is server-decided by the pinned `answerIntegrityLevel`, never client-chosen — a STRICT-pinned attempt cannot opt out by sending plain `payload`, and vice versa. This is a security boundary, not a convenience default.
- RSA-OAEP unwrap must use `OAEPParameterSpec("SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT)` explicitly — do not rely on any implicit/default padding parameters.
- AES-GCM decrypt must use a 128-bit auth tag and validate the decoded IV is exactly 12 bytes (96 bits) before attempting decryption — reject immediately (4xx) if not, rather than passing a malformed IV into `Cipher.init` and handling whatever exception falls out.
- Catch `AEADBadTagException` (GCM auth failure) and any RSA/key-unwrap exception (`InvalidKeyException`, `BadPaddingException`, etc.) explicitly and map both to a 4xx response — never let either surface as a 500, and never persist or emit anything before decryption succeeds.
- Do not log the wrapped key, IV, ciphertext, unwrapped AES key, or decrypted plaintext at any log level in a failure path — exception messages must not embed request payload content.
- Verify (do not assume) whether `exam-delivery` already enforces submission uniqueness per `attempt_id` + `item_id` (upsert-on-retry or reject-on-duplicate); add a test confirming that behavior is unaffected by this phase's changes. If no such constraint exists, document it as a pre-existing gap in this phase's Risks — do not silently add new uniqueness logic outside this spec's scope.

---

## Steps

1. Create `EncryptedSubmissionRequest` as a validated record: `wrappedKey` (`@NotBlank String`), `iv` (`@NotBlank String`), `ciphertext` (`@NotBlank String`) — all Base64-encoded, matching the existing plain-record DTO style used elsewhere in `exam-delivery`.

2. Create a `SubmissionDecryptionService` (or similarly named component) with a method that takes an `EncryptedSubmissionRequest` and the service's `PrivateKey` (from Phase 1's `EncryptionKeyProvider`) and returns decrypted plaintext, or throws a dedicated `SubmissionDecryptionException` on any failure.

3. Inside that method: Base64-decode `wrappedKey`, `iv`, `ciphertext`; catch `IllegalArgumentException` from `Base64.getDecoder().decode()` (malformed Base64 input) and rethrow as `SubmissionDecryptionException` immediately — do not let a decode failure surface as an unhandled exception; validate decoded `iv.length == 12` and throw `SubmissionDecryptionException` immediately if not; unwrap the AES key via `Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")` in `UNWRAP_MODE` with the explicit `OAEPParameterSpec` above; decrypt via `Cipher.getInstance("AES/GCM/NoPadding")` in `DECRYPT_MODE` with `GCMParameterSpec(128, iv)`; wrap the entire decode→unwrap→decrypt sequence so it also catches `NullPointerException` (e.g. a decoded field unexpectedly empty after validation) and `InvalidKeyException`/`BadPaddingException`/`IllegalBlockSizeException` (unwrap-stage failures) and `AEADBadTagException` (GCM-stage failures), rethrowing all as `SubmissionDecryptionException` with a message that does not embed any request field values. No exception path in this method may escape as an unmapped 500.

4. Map `SubmissionDecryptionException` to a 4xx HTTP response (400 or 422 — match whatever status code convention `exam-delivery`'s existing exception-handling/`@ControllerAdvice` uses for client-input rejections) via the existing global exception handler, not a new one-off handler.

5. In `AttemptController`'s submit-answer endpoint, branch on the attempt's pinned `answerIntegrityLevel`: STANDARD → existing plain-`payload` path unchanged; STRICT → accept `EncryptedSubmissionRequest`, decrypt via `SubmissionDecryptionService`, then feed the resulting plaintext into the exact same downstream call the STANDARD path already uses (same `AttemptAnswer` persistence, same `AnswerSubmittedEvent` emission) — do not duplicate that downstream logic, extract/reuse it if it isn't already a shared method.

6. Add the shape-mismatch rejection: if a STRICT-pinned attempt's request body doesn't match `EncryptedSubmissionRequest` (e.g., arrives as plain `payload`) or a STANDARD-pinned attempt's request body doesn't match the plain shape (e.g., arrives with `wrappedKey`/`iv`/`ciphertext`), reject with 4xx before attempting to process either path. This is most naturally done by having two distinct endpoint methods/content-shapes routed by a check against the pinned level read before deserialization-dependent logic runs, or by a single endpoint that inspects which fields are present and cross-checks against the pinned level.

7. Integration test — happy path: valid `EncryptedSubmissionRequest` for a STRICT-pinned attempt decrypts correctly and results in the same `AttemptAnswer`/`AnswerSubmittedEvent` state a STANDARD submission with equivalent plaintext would produce.

8. Integration test — tamper rejection: flip a bit in `ciphertext` (or `wrappedKey`, or `iv`) and confirm the submission is rejected with 4xx and **no** `AttemptAnswer` row is written and **no** event is emitted.

9. Integration test — shape mismatch: STRICT-pinned attempt submits plain `payload` → rejected; STANDARD-pinned attempt submits the encrypted shape → rejected.

10. Integration test — replay/uniqueness: submit the same valid encrypted request twice for the same `attempt_id`/`item_id`; confirm behavior matches whatever the existing (pre-encryption) STANDARD-path retry/uniqueness semantics already are (document the observed behavior in the test itself if no explicit constraint is found).

10a. Integration test — retry with re-encryption: submit the *same plaintext answer* twice for the same `attempt_id`/`item_id`, but as two independently-encrypted requests (different fresh AES key/IV each time, per FR-06 — simulating `pte-app` regenerating the request on retry rather than resending the identical bytes). Confirm the outcome (upsert-on-duplicate, reject-on-duplicate, or accept-both-idempotently) is identical to what two identical STANDARD plain-`payload` retries would already produce today. Document the observed behavior explicitly in the test — uniqueness must be enforced on `(attempt_id, item_id)` identity, not on encrypted-bytes equality, since encrypted bytes are never expected to repeat (FR-06).

---

## Success Criteria

- A submission with a tampered ciphertext, wrapped key, or IV is rejected before any `AttemptAnswer` is persisted. *(spec success criterion, verbatim)*
- Existing scoring/reporting consumers of `AnswerSubmittedEvent` require zero changes. *(spec success criterion, verbatim)*
- STANDARD-pinned attempts continue to accept plain-`payload` submissions unchanged; only STRICT-pinned attempts require the encrypted request shape.
- RSA-unwrap failure and GCM auth-tag failure both map to 4xx, never 500, in all test cases above.

---

## Quality and Testing State

- Quality: **approved**, 0 findings (report: `quality/phase-02-conditional-routing-decryption-quality-report.json`, receipt: `quality/phase-02-conditional-routing-decryption-receipt.json`).
- Testing: **passed** (TDD RED→GREEN; report: `tests/phase-02-conditional-routing-decryption-test-report.json`, RED artifact: `tests/phase-02-conditional-routing-decryption-tdd-ready.json`). 41/41 tests pass in the `exam-delivery` module, 0 regressions.

---

## Risks

- **Shape-routing bypass**: if the branch-by-pinned-level check is implemented after Spring has already attempted to deserialize the request body into a fixed DTO type, a mismatched shape may 400 for the wrong reason (JSON binding error) rather than the intended explicit rejection — acceptable as a 4xx either way, but the test in Step 6/9 should assert on status code, not on a specific error message, to avoid over-fitting to incidental Spring behavior.
- **Auth-tag failure vs. unwrap failure error-message leakage**: JCE exception messages can sometimes embed partial input state in stack traces (not the plaintext, but occasionally byte-length or algorithm details). Mitigation: the global exception handler must return a generic client-facing message for `SubmissionDecryptionException` (e.g., "submission could not be verified") and rely on server-side structured logging (without payload/key fields) for diagnosis.
- **Pre-existing replay/uniqueness gap**: if Step 10's investigation finds no existing uniqueness constraint on `attempt_id` + `item_id`, that is a pre-existing condition unrelated to encryption (plain-`payload` submissions today would have the identical exposure). Do not add new uniqueness enforcement in this phase — document the finding in the phase's completion notes and flag it as a candidate for a separate, explicitly-scoped fix.
