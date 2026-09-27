# Brainstorm: Answer Submission Encryption (Task 20)

**Date:** 2026-08-27

## Ideas Explored

- A. Rely on TLS only, no app-layer crypto — sufficient against passive network attackers, but doesn't stop the actual threat model: a student using a proxy tool (Charles/Fiddler, rooted device with SSL pinning bypassed) to view and edit the request before it leaves the client, since the client itself is the attacker in that scenario.
- B. App-layer AES encryption of `payload` only (confidentiality, no authentication) — satisfies the literal wording ("mã hóa đáp án") but doesn't stop tampering by an attacker who controls the client's own encryption routine; encrypting a tampered plaintext still produces a "valid" ciphertext.
- C. Separate HMAC/signature over payload for integrity, layered alongside B — rejected once D is chosen: redundant against an AEAD's built-in auth tag, adds a second verification path that can drift out of sync with the first.
- D. AES-GCM (AEAD) — encryption and authentication in a single primitive. Chosen: satisfies the literal "mã hóa" requirement while actually solving the named threat (tampering), because any bit-flip after encryption fails the auth tag check server-side.
- E. Extra replay/anti-tamper scaffolding (nonce reuse windows, submission timing checks) — found unnecessary: the existing `(attempt_id, pinned_item_id)` unique constraint in `AttemptAnswer` already rejects any repeat submission via `AnswerAlreadySubmittedException`, regardless of payload content.

## User's Direction

Locked on D (AES-GCM) for the payload — no separate integrity layer, since GCM's auth tag already covers that. Confirmed understanding that reusing an IV under the same key is the one implementation detail that must not be gotten wrong (catastrophic for GCM, not just "slightly weaker").

Initially agreed to a server-derived (HKDF), per-attempt symmetric key — then self-corrected while writing the spec: a symmetric key still has to reach the client somehow, and transmitting it over the same TLS channel the threat model assumes is already compromised (rooted device, pinning bypassed) defeats the purpose. Revised to **asymmetric hybrid encryption**: server holds a static RSA keypair, public key distributed to clients (non-secret by design), client wraps a fresh per-submission AES key with RSA-OAEP and encrypts payload with AES-GCM. No shared secret ever crosses the network in either direction, so the scheme holds even against an attacker who has already broken TLS on their own device — directly matching the "CN cao" threat model the task names.

## Open Questions

- Public key distribution mechanism (bundled at build time vs. fetched once at startup) — left open in the spec's NEEDS CLARIFICATION, affects future key-rotation story.
- Decryption happens immediately server-side on receipt in `exam-delivery`; `payload` is stored and forwarded (via `AnswerSubmittedEvent`) in plaintext exactly as today. This spec only protects the client→`exam-delivery` hop, not at-rest storage or downstream event consumers.

## Risks

- IV/nonce reuse under the same AES key breaks GCM's security guarantees entirely (not a minor weakening) — must be enforced by construction (fresh random key + IV per submission, never reused).
- This spec does not fix the separately-discovered plaintext leak of `correctAnswerText`/`optionsJson` in `AnswerSubmittedEvent` (found while reading `AnswerSubmitService` during the listening-exam-policy brainstorm) — flagged as a related but distinct confidentiality gap, out of scope here.
- Private-key-in-env-var is an interim state; if Vault lands later, the key location must be repointed without needing to redistribute a new public key to already-installed clients unless rotation is actually required.
