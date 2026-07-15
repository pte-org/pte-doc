# Phase 3 (Track 4): Certificate Pinning + Rotation Procedure

**Track:** 4 — Payload Security & Audit
**Covers:** FR-10 · User story: P1 (encryption/pinning, security half)
**Depends on:** Phase 2 (payload encryption) — pinning is the second layer of the same anti-interception requirement.
**Week 1 scope: mobile (Flutter) pinning only.** Web pinning and the full rotation-runbook polish are deferred to Week 2+ backlog per the 1-week timeline — aptis-web has no live exam-delivery UI yet, so web pinning has no real endpoint to protect this week. Ship a minimal rotation note (which key is pinned, who to notify before rotating) rather than the full ops runbook; expand it before production rollout.

---

## Design Constraints

- Pin the **public key** (or a rotation-friendly set: current + next intermediate/root), not a single leaf certificate — pinning a single leaf cert makes every renewal a forced app update, which is an operational trap. This is the single biggest risk flagged by research: a coordinated cert rotation without a client update path will hard-fail every pinned client.
- Must produce a **documented rotation runbook** before this ships to production — not optional polish, it's the mitigation for the risk above.
- Apply on both Flutter (mobile) and Next.js/web (once web has exam delivery) — pinning only on mobile leaves the same attack surface open on web.
- Pin validation failure must fail closed (reject the connection), not silently fall back to unpinned TLS.

## Files to Touch

- `aptis-app/lib/core/security/certificate_pinning.dart` — new: pin validation using `dio`'s `badCertificateCallback` or a dedicated pinning package, checked against a small set of allowed public-key hashes (current + next).
- `aptis-web/apps/tenant-web/lib/certificate-pinner.ts` — new: pin validation for web (HPKP is deprecated in browsers — likely implemented via a service-worker-level check or a documented acceptance that browser-side pinning is best-effort; confirm actual feasibility for Next.js/browser context and adjust design accordingly, don't assume HPKP works).
- `docs/` (or wherever ops runbooks live in this org) — new certificate rotation runbook.

## Implementation Steps

1. Generate/identify the public-key hash(es) to pin for aptis-api's certificate chain (current + next planned, if a rotation is already scheduled).
2. Implement Flutter-side pin validation, failing closed on mismatch, with a clear user-facing error (not a silent hang) if pinning fails.
3. Investigate and implement the most reliable available mechanism for web-side pinning given that HPKP is deprecated in modern browsers — document the actual guarantee achieved (may be weaker than mobile; be honest about this in the runbook rather than overclaiming).
4. Write the certificate rotation runbook: how to add a new pin ahead of rotation, minimum lead time before the old cert expires, how to verify all client versions in the field have the new pin before flipping the server cert.
5. Tests: pinned client rejects a connection presenting an unpinned/different certificate (simulate via a test MITM proxy); pinned client accepts the real pinned cert.

## Acceptance Criteria

- [ ] Mobile client rejects connections failing certificate pin validation, verified by test with a simulated MITM proxy.
- [ ] Certificate rotation runbook is written and reviewed before production rollout.
- [ ] Web-side pinning mechanism is implemented to the extent feasible in a browser context, with honest documentation of its actual guarantee level.
- [ ] Maps to spec success criterion: "Exam payload captured via network proxy... is not human-readable plaintext, even with a user-installed CA (cert pinning holds)."

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
