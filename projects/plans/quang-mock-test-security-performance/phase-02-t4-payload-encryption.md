# Phase 2 (Track 4): Application-Layer Payload Encryption (AES-256-GCM)

**Track:** 4 — Payload Security & Audit
**Covers:** FR-05 · User story: P1 (encrypted exam content)
**Depends on:** Phase 1 (audit table — tamper/decryption-failure events should be logged there).

---

## Design Constraints

- This is **in addition to** TLS, not a replacement — don't let anyone "simplify" this away mid-implementation; it's an explicit stakeholder requirement to protect exam content against interception by proxy/inspection tools even when TLS is technically intact (e.g. user-installed CA on a rooted/jailbroken device).
- Use **Google Tink** on the Spring Boot side (`AES256_GCM` template) — misuse-resistant, handles nonce/IV correctly, avoids common hand-rolled-crypto mistakes.
- **Key distribution (fixes red-team CRITICAL finding — this is now the committed design, not an open option):**
  - Server generates a random 256-bit AES key via Tink at `ExamAttempt` creation time (not derived from `sessionToken` — a key derived from a value the client already knows, like `sessionToken`, gives the client no more protection than not encrypting at all, since anyone who captures `sessionToken` could re-derive the key).
  - **[Week 1 revision]** Server stores the key server-side in **Postgres** (new `encryption_key` column on `exam_attempt`, populated at attempt creation), not Redis — Redis is not currently available in infra and adding it is out of scope for the 1-week timeline. Key lifetime is enforced by the attempt's own lifecycle (cleared/ignored once `SUBMITTED`/`FLAGGED_STOPPED`/expired), not a cache TTL. Revisit Redis later if a shared, evictable cache is needed for scale.
  - The key is transmitted to the client **exactly once**, in the attempt-start response body, over the existing TLS channel. This one-time bootstrap exchange relies on TLS confidentiality (acceptable: the app-layer encryption's purpose is to defend the exam *content* payloads against interception even if TLS is later compromised on the client side via a user-installed CA — the initial key handshake itself is a standard TLS-protected exchange, no different from how JWTs are issued today).
  - All subsequent question-fetch/answer-submit payloads are encrypted/decrypted using this key; the key is never re-transmitted after the initial exchange.
  - **This key-derivation/distribution approach requires explicit security-reviewer sign-off before Phase 2 code is merged** (not just before "finalizing" informally) — track this as a named checklist item, not an implicit assumption.
- Scope the encryption to what actually matters: exam question content (GET response) and answer submission (POST body). Don't encrypt unrelated admin/roster endpoints — that's out of scope and adds needless overhead.
- Performance budget: encryption/decryption overhead must not meaningfully threaten Track 3's p95 < 1s target — measure this phase's overhead and flag it to Track 3 if significant.

## Files to Touch

- `aptis-api/pom.xml` — add Tink dependency.
- `aptis-api/src/main/java/com/aptis/common/crypto/PayloadEncryptionService.java` — new: encrypt/decrypt using session-scoped AES-256-GCM key.
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/controller/ExamAttemptController.java` — wrap question-fetch response and answer-submit request bodies with encryption/decryption.
- `aptis-app/lib/core/crypto/` — new: AES decrypt for question payloads, encrypt for answer submissions (using the `encrypt`/`pointycastle` Dart package or platform-native crypto).
- `aptis-web/apps/tenant-web/lib/` — new: equivalent encrypt/decrypt utility using Web Crypto API (`SubtleCrypto`) if/when web gets exam delivery.

## Implementation Steps

1. Implement `PayloadEncryptionService` using Tink's `AES256_GCM` template — server-generated random key per `ExamAttempt`, stored in a new Postgres `encryption_key` column on `exam_attempt` (Week 1 revision — see Design Constraints), transmitted to the client once in the attempt-start response.
2. Wrap exam-delivery question-fetch and answer-submit request/response bodies with encrypt/decrypt, keeping the outer HTTP/JSON envelope structure predictable (e.g. `{ "encryptedPayload": "..." }`). Explicitly in scope: `GET` question-content response, `POST` answer-submission request/response. Explicitly out of scope: attempt metadata endpoints and the final `submit-exam` status endpoint (encrypt only what carries exam content/answers, not status/metadata).
3. Implement matching decrypt logic on Flutter using the session key negotiated at attempt start.
4. Implement matching logic on Next.js/web (Web Crypto API) for future exam-delivery web UI — build now even if not yet wired to a live screen.
5. Log decryption failures (tampered/corrupted payload) via `AuditLogService` as a security-relevant event, don't just 500.
6. Measure and document the added latency per request; report to Track 3 owner if it threatens the p95 < 1s budget.
7. Tests: round-trip encrypt/decrypt correctness; tampered ciphertext is rejected and logged; a captured request (simulated via a test proxy) is not human-readable plaintext.

## Acceptance Criteria

- [ ] Encryption key is server-generated (never client-derived or client-supplied), stored server-side with TTL, and transmitted to the client exactly once at attempt start.
- [ ] Security-reviewer has signed off on the key-generation/distribution approach in writing before this phase's code is merged (not just before "finalizing" informally).
- [ ] Exam question and answer-submission payloads are encrypted at the application layer with a session-scoped key.
- [ ] A network capture of the encrypted traffic is not human-readable plaintext.
- [ ] Decryption failures are logged as a security event, not silently swallowed.
- [ ] Maps to spec success criterion: "Exam payload captured via network proxy... is not human-readable plaintext" (encryption half; Phase 3 adds the cert-pinning half).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
