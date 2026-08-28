# Phase 1: RSA Keypair Provisioning & StartAttempt Public Key Exposure

**Covers:** FR-01, FR-07 · User stories: P1 (private key never crosses the network)
**Depends on:** none (first phase); consumes the already-completed `answerIntegrityLevel` field from `quang-listening-exam-policy`

---

## Requirements

`exam-delivery` provisions and holds one RSA-2048 (minimum) keypair of its own — not borrowed from `iam`'s `RsaKeyProvider`, since that would require a synchronous cross-service call at request time, which this project's architecture avoids for `exam-delivery`. The private key never leaves the server in any response, log, or event. The public key is exposed to the client exclusively via the existing `StartAttempt` response, and only when the attempt's pinned `answerIntegrityLevel == STRICT` — STANDARD-pinned attempts get no public key field (or a null one), matching today's behavior.

Maps to: **P1 Story #2 ("As exam-delivery, I decrypt submissions using a private key that never crosses the network")**.

---

## Design Constraints

**Preflight:** `AttemptTaskResponse` (`dto/response/AttemptTaskResponse.java`) is a SHARED record returned by `startAttempt`, `getNextTask`, `submitAnswer`, and `submitAttempt` alike, built via `AttemptMapper.toTaskResponse(...)`/`toCompletedResponse(...)`. There is no dedicated `StartAttemptResponse` type — add `encryptionPublicKey` as a new field on `AttemptTaskResponse`, but only populate it from the `createAndPin` (StartAttempt) code path in `AttemptService`; every other caller of `toTaskResponse`/`toCompletedResponse` (`advanceUntilLiveOrComplete`, `advanceAfterCurrent`, `toCompletedResponse`) must pass/produce `null` for it — add a new `AttemptMapper.toTaskResponse(...)` overload taking the extra `String encryptionPublicKey` param used only by `createAndPin`, keep the existing overload (delegating with `null`) for the other three call sites, so their signatures don't need to change. Config values use Spring's `@Value("${x.y:default}")` bound directly in a `@Configuration`/`@Component` class (see `InternalClientConfig`, `TaskTimingConfig`), with `application.yml` env-var placeholders (`${ENV_VAR:dev-default}`) grouped under a new top-level `encryption:` key mirroring the existing `internal:` block's style (inline comment on the dev-default placeholder warning it must be set in real deployments). Exceptions extend `com.pte.common.exception.DomainException(HttpStatus, String code)` with the code sourced from a new constant in `ExamDeliveryConstants` — `GlobalExceptionHandler` (pte-common) maps these automatically, no local `@ExceptionHandler` needed. Entities use Lombok `@Getter @Setter @NoArgsConstructor` (see `PinnedExamSnapshot`); DTOs are plain records with `jakarta.validation` annotations. No BouncyCastle dependency exists in `exam-delivery`'s `pom.xml` — this phase uses only JDK-native `javax.crypto`/`java.security`, consistent with the plan's locked approach; do not add a new dependency for Phase 1.


- Do not call `iam`'s `RsaKeyProvider` or any other service synchronously for key material — `exam-delivery` generates/loads its own keypair, independent of `iam`'s JWK signing keys (different purpose, different lifecycle).
- Key source is environment/config-driven for production (PEM strings via env var or mounted secret), with an ephemeral in-memory generated keypair acceptable for local/dev when no config is present — never generate a fresh keypair per request or per instance restart in a way that breaks already-pinned attempts (see Risks).
- Ephemeral generation must be actively blocked outside dev: if no PEM config is present and the active Spring profile is not `dev`/`local` (or equivalent), fail startup with a clear fatal error rather than silently falling back to an ephemeral keypair. This must be a runtime guard, not documentation alone — a misconfigured prod/staging environment must not boot into a state where every restart invalidates all STRICT-pinned attempts' public keys.
- The public key must be encoded in a self-describing, standard format (X.509 SubjectPublicKeyInfo, PEM or Base64-DER) — not a raw modulus/exponent pair — so the Dart client can parse it with standard library support (pointycastle's `RSAKeyParser`/PEM utilities expect this format).
- `StartAttemptResponse` gets exactly one new field for this phase (e.g. `encryptionPublicKey: String?`), populated only when pinned `answerIntegrityLevel == STRICT`; do not add unrelated fields.
- No behavior change for STANDARD-pinned attempts — the new field must be absent/null and every existing STANDARD-path test must remain green.

---

## Steps

1. Add an `EncryptionKeyProvider` (or similarly named) component in `exam-delivery` responsible for supplying the service's RSA keypair. Load from config (e.g. `exam-delivery.encryption.private-key-pem` / `public-key-pem` env-backed properties) if present; otherwise generate an in-memory `KeyPairGenerator.getInstance("RSA")` (2048-bit) keypair once at startup for environments with no config (local/dev only — document this clearly in the class and in config sample files).

2. Implement PEM/DER parsing for the configured case: private key via `PKCS8EncodedKeySpec` + `KeyFactory.getInstance("RSA").generatePrivate(...)`, public key via `X509EncodedKeySpec` + `generatePublic(...)`. Normalize PEM input by stripping `-----BEGIN...-----`/`-----END...-----` headers and all whitespace variants (`\r\n`, `\n`, spaces) before Base64-decoding — env vars commonly retain literal `\r\n` or escaped newlines, which breaks naive header-strip logic.

2a. Add the startup guard from the Design Constraints above: if PEM config is absent and the active profile isn't dev/local, throw a fatal startup exception naming the missing config property.

3. Expose a method to retrieve the public key as a Base64-encoded X.509 SubjectPublicKeyInfo string (i.e., `Base64.getEncoder().encodeToString(publicKey.getEncoded())`), ready to drop directly into the `StartAttemptResponse` field.

4. Add `encryptionPublicKey` (nullable `String`) to `StartAttemptResponse`.

5. In `AttemptService`'s `StartAttempt` flow (wherever the pinned `answerIntegrityLevel` is already read for other Phase-4-of-listening-exam-policy purposes), populate `encryptionPublicKey` from `EncryptionKeyProvider` only when the pinned level is `STRICT`; leave it null otherwise.

6. Add a config sample/documentation entry (e.g. in `application.yml.example` or equivalent) showing the expected env var names for private/public key PEM, without committing any real key material.

7. Unit test: `EncryptionKeyProvider` loads a keypair from a test PEM fixture and round-trips (encrypt with the public key parsed via `X509EncodedKeySpec`, decrypt with the private key parsed via `PKCS8EncodedKeySpec`, confirm plaintext matches) — this is a self-consistency check, not the cross-platform interop test (that lives in Phase 2/3 once both sides exist). Also add a unit test using a PEM fixture with `\r\n` line endings to confirm the normalization in Step 2 handles it.

7a. Before Phase 3 begins, verify this phase's Base64 X.509 SubjectPublicKeyInfo output is actually parseable by pointycastle's key-parsing utilities on the Dart side — write a small standalone Dart script/test that decodes this phase's test fixture's Base64 public key output and confirms pointycastle parses it into an `RSAPublicKey` without error. Do not let Phase 3 discover a format mismatch after it has already been built around an assumption; resolve any mismatch here, in Phase 1, since it ships first.

8. Integration test: `StartAttempt` on a STRICT-pinned attempt returns a non-null, non-empty `encryptionPublicKey`; `StartAttempt` on a STANDARD-pinned attempt returns null/absent for that field and all other existing StartAttempt assertions still pass unchanged.

---

## Success Criteria

- `StartAttemptResponse.encryptionPublicKey` is populated (valid Base64 X.509 SubjectPublicKeyInfo) exactly when the attempt's pinned `answerIntegrityLevel == STRICT`.
- `StartAttemptResponse.encryptionPublicKey` is null/absent for STANDARD-pinned attempts, with zero change to any other field or existing STANDARD-path behavior.
- The private key never appears in any HTTP response, log statement, or exception message — verified in code review per this plan's Risks section.
- Acceptance criterion from spec (FR-07 / success criteria): "The private RSA key never appears in any client-facing response, log, or event."

---

## Quality and Testing State

- Quality: **approved**, 0 findings (report: `quality/phase-01-rsa-keypair-startattempt-quality-report.json`, receipt: `quality/phase-01-rsa-keypair-startattempt-receipt.json`).
- Testing: **passed** (TDD RED→GREEN; report: `tests/phase-01-rsa-keypair-startattempt-test-report.json`, RED artifact: `tests/phase-01-rsa-keypair-startattempt-tdd-ready.json`). 29/29 tests pass in the `exam-delivery` module, 0 regressions.

---

## Risks

- **Keypair instability across restarts (dev/ephemeral mode)**: if `exam-delivery` regenerates a fresh in-memory keypair on every restart with no config present, any STRICT-pinned attempt whose `StartAttempt` happened before a restart will have handed the client a public key that no longer matches the post-restart private key — all subsequent submissions for that attempt fail decryption. Mitigation: document ephemeral mode as dev-only and unsuitable for any environment with attempt lifetimes crossing a deploy/restart; production must always set the config-backed PEM keys.
- **PEM parsing edge cases**: PEM strings pasted into env vars sometimes retain literal `\n` escapes or Windows line endings, breaking naive header-strip logic. Mitigation: normalize (strip `-----BEGIN...-----`/`-----END...-----`, strip all whitespace/newline variants) before Base64-decode; add a unit test with a PEM fixture containing `\r\n` line endings.
- **Wrong key format for Dart parsing**: if the public key is exposed as a raw modulus/exponent pair instead of X.509 SubjectPublicKeyInfo, pointycastle's standard PEM/key-parsing utilities on the Dart side (used in Phase 3) won't parse it without custom logic. Mitigation: confirm the exact encoding expected by Phase 3's chosen Dart parsing utility before finalizing this phase's output format — coordinate with Phase 3 implementation, adjust here first since this phase ships first.
