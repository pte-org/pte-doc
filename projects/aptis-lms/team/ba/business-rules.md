# Business Rules — APTIS LMS

## Business Rules

### BR-001: Tenant role union

**Rule:** Tenant-side effective permissions shall equal the union of all active assigned roles; revoking one role shall not revoke permissions granted by another active role.
**Applies to:** US-004 and all tenant-authorized stories
**Rationale:** Supports real users acting as Teacher and Coordinator simultaneously.

### BR-002: Strict tenant isolation

**Rule:** Every tenant-scoped read and write shall be constrained by the tenant resolved from the request host; request-supplied tenant identifiers shall never override that context.
**Applies to:** All tenant-scoped stories
**Rationale:** Cross-tenant access is a Critical security defect.

### BR-003: Teacher group scope

**Rule:** Teachers shall access learners, attempts, reviews, and analytics only for groups to which they are actively assigned.
**Applies to:** US-045, US-049, US-052–US-061
**Rationale:** Protects student privacy and delegated administration boundaries.

### BR-004: Server-authoritative timing

**Rule:** Only server timestamps and persisted part timers shall determine remaining exam time and part closure.
**Applies to:** US-019, US-040, US-104
**Rationale:** Prevents timer manipulation and inconsistent recovery.

### BR-005: Per-answer persistence

**Rule:** An answer is considered saved only after server acknowledgement; final submission shall finalize metadata rather than carry the primary answer payload.
**Applies to:** US-020–US-026, US-105–US-107
**Rationale:** Prevents end-of-exam data loss.

### BR-006: Monotonic answer ordering

**Rule:** Answer updates shall carry a monotonically increasing per-question sequence number, and the server shall reject updates older than the latest accepted sequence.
**Applies to:** US-105–US-107
**Rationale:** Prevents network reordering from restoring stale answers.

### BR-007: Seat quota enforcement

**Rule:** Enrollment shall be rejected when active counted enrollment equals or exceeds the active license seat count.
**Applies to:** US-046–US-051, US-073–US-080
**Rationale:** Enforces the commercial seat model.

### BR-008: Single attempt and approved retakes

**Rule:** A student shall have one attempt per session unless a Teacher or Exam Coordinator records an explicit retake approval with a reason.
**Applies to:** US-017, US-043, US-093
**Rationale:** Protects fairness and auditability.

### BR-009: Active course and session windows

**Rule:** Exam sessions and attempt starts shall occur only while their course and session windows permit them.
**Applies to:** US-017, US-037–US-044
**Rationale:** Prevents unscheduled access.

### BR-010: Expired license read-only

**Rule:** A tenant with no active license shall be read-only and shall not create sessions, enroll learners, or start attempts.
**Applies to:** US-003, US-044–US-051, US-071–US-082
**Rationale:** Preserves access to history while enforcing license validity.

### BR-011: Immutable content versions

**Rule:** A question or band mapping used by a completed attempt shall never be mutated; changes shall create a new version.
**Applies to:** US-014, US-027–US-028
**Rationale:** Preserves historical scoring reproducibility.

### BR-012: Band mapping completeness

**Rule:** A publishable band mapping shall cover the entire valid raw-score range without gaps or overlaps and shall identify its version on every derived result.
**Applies to:** US-028, US-034–US-035
**Rationale:** Prevents global scoring corruption.

### BR-013: AI draft human confirmation

**Rule:** AI-generated Writing and Speaking scores shall remain hidden from students until an authorized Teacher confirms or overrides them.
**Applies to:** US-030–US-036
**Rationale:** AI is assistive, not the final authority.

### BR-014: Invalid AI output fallback

**Rule:** Malformed, incomplete, out-of-range, or permanently failed AI output shall be flagged for priority human review and shall never be finalized automatically.
**Applies to:** US-030–US-033
**Rationale:** Avoids publishing probabilistic provider failures as scores.

### BR-015: Deterministic shuffle

**Rule:** Question and option order shall be generated from an attempt-specific stored seed and restored identically after resume.
**Applies to:** US-093–US-094, US-106
**Rationale:** Maintains integrity without breaking continuity.

### BR-016: Immutable integrity and intervention logs

**Rule:** Violation, coordinator intervention, impersonation, and license history records shall not be updated or deleted by application roles.
**Applies to:** US-040–US-043, US-076, US-081, US-096–US-103
**Rationale:** Prevents tampering with operational evidence.

### BR-017: Idempotent jobs

**Rule:** Notification, scoring, purge, analytics, and lifecycle jobs shall use idempotency keys so retries do not duplicate externally visible effects.
**Applies to:** US-027–US-031, US-038, US-067–US-070, US-074, US-083–US-092
**Rationale:** Queues provide at-least-once delivery and must tolerate retries.

### BR-018: Credential secrecy

**Rule:** Passwords, raw refresh tokens, API keys, signing keys, and connection strings shall never be stored in plaintext source, database records, logs, or persistent exports.
**Applies to:** US-001–US-007, US-048
**Rationale:** Security baseline and downstream code-generation constraint.

### BR-019: One-time generated password exposure

**Rule:** A generated temporary password may appear only in the immediate controlled credential handoff and shall not be reconstructable or re-exportable later.
**Applies to:** US-006, US-046–US-048
**Rationale:** Balances bulk onboarding with password security.

### BR-020: No PII in logs

**Rule:** Application and infrastructure logs shall exclude passwords, tokens, answer contents, transcripts, audio payloads, and unnecessary personal identifiers.
**Applies to:** All stories
**Rationale:** Reduces privacy and incident impact.

### BR-021: Private media access

**Rule:** Audio and image objects containing restricted content shall remain private and be accessed only through short-lived scoped URLs or authenticated service proxies.
**Applies to:** US-010–US-011, US-022–US-023, US-030, US-108–US-110
**Rationale:** Protects exam content and student voice data.

### BR-022: Violation thresholds

**Rule:** Warning and termination thresholds shall be validated before session start, frozen after start, and applied exactly once at each crossing.
**Applies to:** US-037, US-095–US-103
**Rationale:** Ensures predictable anti-cheat enforcement.

### BR-023: No payment processing

**Rule:** The system shall not collect card data, initiate payments, issue invoices, or infer payment status; Sales shall manage licenses manually.
**Applies to:** US-071–US-082
**Rationale:** Explicit v1 scope boundary.

### BR-024: Non-official result disclaimer

**Rule:** Every result and trial surface shall display the legally approved non-official APTIS simulation disclaimer.
**Applies to:** US-034–US-036, US-088–US-090
**Rationale:** Avoids misleading certification claims.

### BR-025: No hardcoded secrets in generated code

**Rule:** Generated or committed artifacts shall not contain real credentials, API keys, passwords, tokens, or production connection strings.
**Applies to:** All implementation tasks
**Rationale:** Mandatory security rule for downstream agents.
