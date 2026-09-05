# Spec: Answer Submission Encryption

**Date:** 2026-08-27
**Status:** Ready

---

## Problem Statement

Task 20 requires that a student's submitted answer cannot be modified via sophisticated technical means (proxy interception, rooted device with TLS pinning bypassed) before it reaches the server. Because the threat model explicitly includes an attacker who has already defeated TLS on their own device, any scheme relying on a shared secret transmitted over that same TLS channel is compromised by the same attacker. A symmetric, server-derived-and-transmitted key was considered and rejected for exactly this reason.

---

## User Stories

- **[P1]** As a student, my submitted answer cannot be silently altered between leaving my device and being persisted, so that the exam result reflects what I actually chose — even if I (or someone with access to my device) has broken TLS locally.
  Accepted when: any bit-level modification of the encrypted submission after it leaves the client causes `exam-delivery` to reject it (auth tag verification failure), not silently accept a different answer.

- **[P1]** As `exam-delivery`, I decrypt submissions using a private key that never crosses the network in either direction, so that a compromised TLS session on the student's device cannot expose or forge answers.
  Accepted when: the client only ever holds the server's RSA **public** key; the private key never leaves the server.

- **[P2]** As a security reviewer, I can confirm the AES key wrapped per submission is freshly generated each time (not reused across submissions), so that a compromised single submission doesn't expose others.
  Accepted when: each `SubmitAnswerRequest` carries its own RSA-wrapped AES key and GCM IV, verifiably distinct per submission.

- **[P1]** As a student in a PRACTICE-mode (STANDARD integrity) session, I submit answers exactly as today, so that this feature doesn't add client complexity where the host didn't ask for it.
  Accepted when: an attempt pinned with `answerIntegrityLevel == STANDARD` continues to accept plain-`payload` submissions unchanged; only STRICT-pinned attempts require the encrypted request shape.

- **[P3]** _(out of scope)_ At-rest encryption of `payload` in the `attempt_answers` table, and the plaintext `correctAnswerText`/`optionsJson` leak in `AnswerSubmittedEvent` — separate, already-flagged confidentiality gap, not this spec's fix.

---

## Functional Requirements

1. FR-01: `exam-delivery` (or a shared internal key-management point) holds one RSA keypair. The private key stays server-side (config/env now, Vault later per the project's already-decided infra rollout).
2. FR-02: Per submission, the client generates a fresh random AES-256 key, encrypts `payload` with AES-GCM (fresh 96-bit IV), then wraps the AES key with RSA-OAEP using the server's public key.
3. FR-03: This scheme is **conditional on the pinned `answerIntegrityLevel` (from the listening-exam-policy feature's `ExamPolicy`)**, not universal: when the attempt's pinned `answerIntegrityLevel == STRICT`, `SubmitAnswerRequest` must carry `wrappedKey` (base64 RSA-OAEP output), `iv` (base64, 96-bit), and `ciphertext` (base64 AES-GCM output including auth tag) instead of a plain `payload` string. When pinned `answerIntegrityLevel == STANDARD`, the existing plain-`payload` contract is unchanged. `exam-delivery` rejects a STRICT-pinned attempt's submission that arrives in plain-`payload` form (and vice versa) — the request shape must match the pinned level, not be client-chosen.
4. FR-04: `exam-delivery` unwraps the AES key with its private key, then decrypts and verifies `ciphertext` with AES-GCM; on RSA-unwrap failure or GCM auth-tag failure, rejects the submission (4xx) without persisting an `AttemptAnswer` row.
5. FR-05: Decrypted plaintext is what gets persisted to `AttemptAnswer.payload` and emitted in `AnswerSubmittedEvent` — unchanged from today's plaintext contract for storage and downstream consumers.
6. FR-06: Every submission uses its own freshly generated AES key and IV — never reused across submissions, even for the same task retried after a rejected attempt.
7. FR-07: The server's RSA public key is exposed to the client via the `StartAttempt` response — present only when the pinned `answerIntegrityLevel == STRICT` — not bundled at client build time. This reuses the existing pattern of resolving everything needed for the attempt once at `StartAttempt` (matches how `ExamPolicy`/audio URLs are already delivered), and allows the server-side keypair to rotate without requiring a new client app release.

---

## Non-Functional Requirements

- Security: AES-256-GCM + RSA-OAEP (2048-bit minimum) only; no custom/home-grown crypto construction.
- Security: reject rather than "best-effort accept" on any unwrap or auth-tag verification failure.
- Security: the scheme's confidentiality/integrity guarantees must not depend on TLS being intact on the client's device — TLS remains defense-in-depth, not the sole protection.
- Compatibility: this spec does not change `AttemptAnswer`'s storage format or `AnswerSubmittedEvent`'s payload contract — only the wire format between client and `exam-delivery` for `SubmitAnswerRequest`.

---

## Success Criteria

- [ ] A submission with a tampered ciphertext, wrapped key, or IV is rejected before any `AttemptAnswer` is persisted.
- [ ] The private RSA key never appears in any client-facing response, log, or event.
- [ ] Existing scoring/reporting consumers of `AnswerSubmittedEvent` require zero changes.
- [ ] Two submissions never reuse the same AES key or IV (verifiable in code review / test).

---

## Out of Scope

- At-rest encryption of `payload` in the database.
- Fixing the plaintext `correctAnswerText`/`optionsJson` leak in `AnswerSubmittedEvent` (separate finding).
- Any change to `answerIntegrityLevel`'s STANDARD behavior (this spec only defines STRICT).
- Key rotation policy for the server's RSA keypair (assumed static for the scope of this capstone).

---

## Assumptions

- The threat this spec defends against is a student-controlled client editing the request before it leaves the device (proxy interception, modified app, TLS pinning bypass), not a fully malicious client that reimplements the entire encryption routine correctly around a tampered answer.
- The server's public key can be safely distributed to the client without secrecy requirements, per standard asymmetric-crypto assumptions.
- Attempts are short-lived (a single exam session), so RSA keypair rotation mid-attempt is not a practical concern.
- Depends on the listening-exam-policy feature's `ExamPolicy.answerIntegrityLevel` field already being pinned onto the attempt at `StartAttempt` (delivered in that feature's Phase 1/4) — this spec consumes that field, it does not define it.

**Status:** all clarifications resolved — see FR-03 (conditional on pinned `answerIntegrityLevel`) and FR-07 (public key delivered via `StartAttempt`, not build-time embedded).
