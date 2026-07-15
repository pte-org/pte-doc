# SRS Master Index
## APTIS LMS — Hệ thống triển khai thi thử APTIS
**Version:** 1.0 | **Date:** 2026-06-17 | **Status:** DRAFT

---

## Document Map

| File | Section | Description |
|------|---------|-------------|
| [01-introduction.md](01-introduction.md) | §1 Introduction | Purpose, scope (IN/OUT), definitions, references, document overview |
| [02-overall-description.md](02-overall-description.md) | §2 Overall Description | System context diagram, product functions, user characteristics (10 actors), constraints, assumptions (A-01–A-10), feature apportioning |
| [03-01-external-interfaces.md](03-01-external-interfaces.md) | §3.1 External Interfaces | 10 UI screens (UI-01–UI-10), hardware interfaces (HW-01–04), software APIs (SI-01–06), communication protocols (CI-01–04) |
| [03-02-functional-requirements.md](03-02-functional-requirements.md) | §3.2 Functional Requirements | All 111 FRs in IEEE 830 format (shall clause + Actor/Precondition/Trigger/Source table + full GWT) across 13 feature clusters |
| [03-03-performance.md](03-03-performance.md) | §3.3 Performance Requirements | 14 NFRs in ISO/IEC 25023 Quality Attribute Scenario format; 5 confirmed, 9 TBD |
| [03-04-database.md](03-04-database.md) | §3.4 Database Requirements | 22 entity definitions with full column specs, data volume estimates, PII field summary, retention and purge policy |
| [03-05-design-constraints.md](03-05-design-constraints.md) | §3.5 Design Constraints | 12 non-negotiable design constraints (DC-01–DC-12) with rationale and implementation implications |
| [03-06-system-attributes.md](03-06-system-attributes.md) | §3.6 System Attributes | Reliability, Availability, Security, Maintainability, Portability, Usability attributes (SA-REL/AVL/SEC/MNT/PRT/USA) |
| [03-07-other-requirements.md](03-07-other-requirements.md) | §3.7 Other Requirements | i18n (OR-I18N-01–06), Legal (OR-LGL-01–04), Operational (OR-OPS-01–06), Transition (OR-TRN-01–03), Training (OR-TRN-04–06) |
| [appendix-a-glossary.md](appendix-a-glossary.md) | Appendix A — Glossary | 45 domain and technical terms defined alphabetically |
| [appendix-b-open-issues.md](appendix-b-open-issues.md) | Appendix B — Open Items | 8 primary open items (OI-01–OI-08) + 9 inline TBDs; each with owner, blocking FRs/NFRs, and resolve-by milestone |

---

## FR Summary

**Total FRs: 111**

| Priority | Count | FR Range |
|----------|-------|----------|
| Essential | 104 | FR-01–FR-29, FR-37–FR-75, FR-77–FR-82, FR-83 (partial), FR-85–FR-87, FR-93–FR-111 |
| Conditional | 7 | FR-08 (Guest session), FR-76 (Impersonation), FR-84 (Push notifications), FR-88–FR-92 (Guest/Trial), FR-102 (Kiosk mode) |
| Optional | 0 | — |

**FR Distribution by Cluster:**

| Cluster | FRs | Count |
|---------|-----|-------|
| F-01: Authentication & Access | FR-01–FR-08 | 8 |
| F-02: Question Bank Management | FR-09–FR-16 | 8 |
| F-03: Exam Simulation — Full Mode | FR-17–FR-26 | 10 |
| F-04: Scoring System | FR-27–FR-36 | 10 |
| F-05: Exam Scheduling & Deployment | FR-37–FR-43 | 7 |
| F-06: Learner Management | FR-44–FR-51 | 8 |
| F-07: Analytics & Reporting | FR-52–FR-70 | 19 |
| F-08: Vendor Management | FR-71–FR-76 | 6 |
| F-09: Sales Team Portal | FR-77–FR-82 | 6 |
| F-10: Notification System | FR-83–FR-87 | 5 |
| F-11: Guest / Trial Flow | FR-88–FR-92 | 5 (Conditional) |
| F-12: Exam Integrity / Anti-cheat | FR-93–FR-103 | 11 |
| F-13: Exam Continuity | FR-104–FR-111 | 8 |
| **Total** | | **111** |

---

## NFR Summary

**Total NFRs: 14**

| ID | Characteristic | Response Measure | Status |
|----|----------------|-----------------|--------|
| NFR-01 | API Response Time (p95) | TBD (suggested: < 500ms) | TBD — OI-05 |
| NFR-02 | Overall Availability | TBD (suggested: ≥ 99.5%/month) | TBD — OI-05 |
| NFR-03 | Exam Hour Availability | ≥ 99.9% during active sessions | **Confirmed** |
| NFR-04 | Concurrent Exam Takers | TBD (suggested: ≥ 500) | TBD — OI-05 |
| NFR-05 | Auto-score Latency | ≤ 2 minutes from submission | **Confirmed** |
| NFR-06 | Exam State Write Latency (p95) | TBD (suggested: < 300ms) | TBD — OI-05 |
| NFR-07 | Speaking Audio Upload | TBD (suggested: ≤ 5 min total) | TBD — OI-05 |
| NFR-08 | Listening CDN Delivery (TTFB) | TBD (suggested: ≤ 500ms) | TBD — OI-05 |
| NFR-09 | AI Scoring Pipeline | TBD (suggested: ≤ 15 min) | TBD — OI-02, OI-05 |
| NFR-10 | Exam Record Retention | TBD — pending Legal (OI-07) | TBD — OI-07 |
| NFR-11 | Audio Recording Retention | TBD — pending Legal (OI-07) | TBD — OI-07 |
| NFR-12 | Password Hashing | bcrypt cost ≥ 12 | **Confirmed** |
| NFR-13 | JWT Token Lifetime | Access ≤ 15 min; Refresh ≤ 7 days rotating | **Confirmed** |
| NFR-14 | Exam Data Integrity | 0% answer data loss rate | **Confirmed (#1 priority)** |

**Confirmed: 5 | TBD: 9**

---

## Open Items Summary

**Total open items: 8 primary (OI-01 to OI-08) + 9 inline TBDs**

| OI | Description | Owner | Status |
|----|-------------|-------|--------|
| OI-01 | Flutter platform split (Web / Desktop / Mobile per subsystem) | TechLead | OPEN |
| OI-02 | AI provider selection (STT + LLM) | TechLead | OPEN |
| OI-03 | Writing/Speaking scoring SLA definition | Vendor Business | OPEN |
| OI-04 | Anti-cheat default violation thresholds | Vendor Business | OPEN |
| OI-05 | NFR numeric targets (API latency, availability, capacity, etc.) | TechLead | OPEN |
| OI-06 | Guest trial scope and lead capture policy | Vendor Marketing | OPEN |
| OI-07 | Data retention periods and NĐ 13/2023 compliance | PM + Legal | OPEN |
| OI-08 | Exam continuity edge cases (audio, crash, power-off) | TechLead + Vendor | OPEN |

**All 8 OI-XX items must be resolved before this SRS can be promoted from DRAFT to FINAL status.**

---

## Design Constraints Summary

| ID | Constraint | Status |
|----|-----------|--------|
| DC-01 | Flutter mandated as sole client framework | Confirmed |
| DC-02 | Multi-tenant subdomain architecture | Confirmed |
| DC-03 | HTTPS only (TLS 1.2+) | Confirmed |
| DC-04 | Server-authoritative exam timer | Confirmed |
| DC-05 | Per-answer server-side persistence | Confirmed |
| DC-06 | AI scoring via third-party APIs only (no custom ML) | Confirmed |
| DC-07 | No payment processing in-system | Confirmed |
| DC-08 | Cloud hosting only (no on-premise) | Confirmed |
| DC-09 | RBAC must support multi-role per user (tenant side) | Confirmed |
| DC-10 | Violation events and audit logs are immutable | Confirmed |
| DC-11 | Disclaimer required on all result screens | Confirmed |
| DC-12 | Passwords never stored in plaintext | Confirmed |

---

## Business Rules Summary

| ID | Rule |
|----|------|
| BR-01 | Tenant-side users can hold multiple roles simultaneously; permissions = union of roles |
| BR-02 | All data is strictly scoped to `tenant_id`; cross-tenant access is forbidden |
| BR-03 | Teacher access is limited to students in their assigned groups |
| BR-04 | Exam timers are server-authoritative; client cannot manipulate them |
| BR-05 | Enrollment blocked when `seats_used ≥ seat_count` |
| BR-06 | One attempt per student per session; retakes require explicit approval |
| BR-07 | Retakes require approval by Teacher or Exam Coordinator |
| BR-08 | Exam sessions can only be created within an active course |
| BR-09 | Students can only start exam attempts within the course's active date window |
| BR-10 | Tenants with no active license or expired license are in read-only mode |
| BR-11 | Seat quota alerts are sent at 80% and 90% usage; license expiry alerts at 30 and 7 days |
| BR-12 | Questions used in completed sessions are version-controlled and immutable |
| BR-13 | AI draft scores are not visible to students until confirmed by a Teacher |
| BR-14 | Question and MCQ answer order is shuffled per attempt using a stored random seed |
| BR-15 | Violation events are immutable; no application-layer DELETE is permitted |

---

## Document Status

| Attribute | Value |
|-----------|-------|
| Current status | DRAFT |
| Sections complete | 11/11 section files + Master Index |
| Open items blocking FINAL | 8 (OI-01 through OI-08) |
| Inline TBDs blocking FINAL | 9 |
| Total requirements | 111 FR + 14 NFR + 12 DC + 15 BR |
| Next action | Resolve OI items → promote to FINAL |

---

## Suggested Next Steps

1. **Resolve OI-01** (Flutter platform split) — unblocks frontend architecture and FR-18, FR-95, FR-97, FR-102
2. **Resolve OI-02** (AI provider) — unblocks FR-30, FR-31, NFR-09; a short PoC evaluation is recommended
3. **Resolve OI-07** (retention + NĐ 13 compliance) — must be completed before cloud region selection (DC-08)
4. **Resolve OI-05** (NFR targets) — requires OI-01 and load model input from Vendor; unblocks infrastructure sizing
5. **Resolve OI-03, OI-04, OI-06, OI-08** — can proceed in parallel with the above

Once all OI items are resolved, run `/sr:validate` to validate the SRS against IEEE 830-1998 and promote status to FINAL.
