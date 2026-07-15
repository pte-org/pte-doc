# Session Notes — APTIS LMS

## Key Decisions Made

1. **Platform:** Flutter (Dart) for all client targets. Vendor Portal and Tenant Portal on Flutter Web. Exam Client on Flutter Desktop (Windows primary, macOS secondary) + Flutter Web. Flutter Mobile deferred to v1.5 (OI-01 baseline — pending TechLead confirmation).
2. **Multi-tenancy model:** Subdomain-based (`{slug}.aptis-lms.vn`). Tenant isolation enforced at API gateway and database (tenant_id column strategy). Vendor Portal on `admin.aptis-lms.vn`.
3. **AI scoring is draft-only, always:** AI scores for Writing and Speaking are NEVER shown to students without explicit Teacher confirmation (BR-13). No auto-confirm path exists.
4. **Exam continuity is #1 priority:** Per-answer state persisted to server on every answer change (BR-03). Server-authoritative timer never resets on reconnect (BR-02). Speaking audio buffered locally with retry (BR-11).
5. **AI provider: no decision yet.** STT and LLM provider evaluation is OI-02 (proof-of-concept required). The STT provider adapter must be swappable via configuration change only (SI-05).
6. **Scoring SLA: no decision yet.** OI-03 is pure business decision; suggested defaults: T+24h reminder, T+48h escalation to Tenant Admin, no auto-confirm.
7. **Anti-cheat thresholds: no decision yet.** OI-04 suggested defaults: `warning_threshold = 3`, `terminate_threshold = 5`, configurable range [1, 20].
8. **Data retention and compliance: not decided.** OI-07 (NĐ 13/2023 legal review) is the single longest-lead item. Blocks cloud region, CDN placement, storage budget, and purge job implementation. Legal consultation must start immediately.
9. **Payment is out of scope permanently at v1.** Billing handled entirely outside the system by Sales team.
10. **British Council disclaimer required in UI** (DC-11, OR-LGL-01): "This is a practice simulation, not an official APTIS exam."
11. **Guest trial is Conditional (F-11).** Can be cut entirely from v1 if OI-06 is not resolved before dev.
12. **Kiosk mode (FR-102) is Conditional.** Desktop-only; Flutter Desktop has more OS control than Web.

## Assumptions

| ID | Assumption | Invalidation risk |
|----|-----------|-----------------|
| A-01 | All students have a device capable of running Flutter (Desktop or Web) and a working microphone for Speaking | Medium — schools using old hardware may have issues |
| A-02 | APTIS exam structure (4 skills, 16 parts, question types) does not change during v1 product lifetime | Low — British Council rarely changes structure |
| A-03 | Each tenant has enough Teachers available to review Writing/Speaking within an acceptable SLA | **HIGH** — if Teachers are unavailable, scores are indefinitely pending. No system escalation to Vendor. Needs T+72h Super Admin alert (see improvement-report.md §6.5) |
| A-04 | Vendor controls the entire question bank; tenants do not create their own questions in v1 | Low risk for v1; data model must not block v2 tenant-authored questions |
| A-05 | Network at exam venue is stable enough for Speaking audio upload within a few minutes after recording | Medium — rural schools may have poor connectivity; F-13 handles short drops, not full-session outages |
| A-06 | Payment between Vendor and Tenant is handled entirely outside the system | Confirmed by design decision |
| A-07 | One subdomain = one tenant; 1-1 mapping is immutable | Low risk |
| A-08 | Content Manager has sufficient APTIS domain knowledge to create pedagogically valid questions | Low — system validates structure only, not content quality |
| A-09 | Speaking audio stored on cloud is consented to via tenant contract (no in-app consent flow needed) | Medium — depends on OI-07 / NĐ 13/2023 outcome |
| A-10 | Band Mapping Table is the sole authoritative source of band derivation; if misconfigured, all results are wrong | **HIGH** — needs table validation FR (no gaps/overlaps) and version locking. See improvement-report.md §6.6 |

## Open Items

All 8 open items are OPEN as of 2026-06-16. Resolution order (by dependency + lead time):

| Priority | OI | Owner | Blocking | Suggested resolve-by |
|----------|-----|-------|---------|---------------------|
| 1 | **OI-01** Flutter platform split | TechLead | Frontend architecture, FR-18, FR-95, FR-97, FR-102, FR-84, NFR-07 | Before architecture session |
| 1 | **OI-07** NĐ 13/2023 + data retention | PM + Legal | Cloud region, CDN, storage budget, purge jobs, NFR-10/11 | Before architecture (longest lead — start immediately) |
| 3 | **OI-02** AI provider selection | TechLead | FR-30, FR-31, NFR-09 | After OI-01 (platform affects audio format for STT test) |
| 4 | **OI-05** NFR numeric targets | TechLead | NFR-01/02/04/06/07/08/09 | After architecture session |
| 5 | **OI-03** Scoring SLA | Vendor Business | FR-83, student result expectation messaging | Quick win — pure business decision, single meeting |
| 5 | **OI-04** Anti-cheat thresholds | Vendor Business | FR-100, FR-37 defaults | Same session as OI-03 |
| 7 | **OI-06** Guest trial scope | Vendor Marketing | F-11 (Conditional cluster) | Before F-11 dev; or defer by cutting F-11 |
| 8 | **OI-08** Exam continuity edge cases | TechLead + Vendor Product | FR-109/110/111 | Dedicated 2-hour workshop before F-13 dev |

Additional in-SRS inputs needed: FR-28 (band mapping table format), FR-58 (student name anonymization in ranking), FR-59 (weak student band threshold), FR-85 (default language per tenant), OR-OPS-01 (monitoring thresholds), OR-OPS-04 (maintenance window definition), OR-OPS-06 (log retention period).

## Next Steps

1. Initiate Legal consultation for OI-07 (NĐ 13/2023 + cloud region) — longest lead time, blocks the most decisions
2. TechLead resolves OI-01 (Flutter platform split) — can be done unilaterally, no external dependency
3. Schedule business meeting to resolve OI-03 + OI-04 (quick wins — pure business decisions)
4. After OI-01: begin OI-02 proof-of-concept (STT accuracy test with Vietnamese-accented English audio)
5. After OI-01 + OI-07: TechLead architecture session → OI-05 (NFR numeric targets)
6. Schedule OI-08 workshop (2h) with TechLead + Vendor Product + Exam Coordinator before F-13 dev
7. Run tenant walkthrough of FR-32, FR-37, FR-47, FR-58 with at least one real Teacher and Tenant Admin
8. Request security architect review of SRS §3.5 (Design Constraints) and §3.6 (System Attributes) before architecture session
9. After all OIs resolved: re-run `/sr:validate` to promote SRS from DRAFT to FINAL

## SRS Location

```
projects/aptis-lms/srs/   — 11 section files
Master index: projects/aptis-lms/srs/00-master-index.md

projects/aptis-lms/improvement-report.md  — risks, FR gaps, NFR gaps, process recommendations
projects/aptis-lms/plan/                  — 12 section plan files (blueprint for each SRS section)
projects/aptis-lms/spec.md                — full specification (requirements, business rules, actors)
projects/aptis-lms/brainstorm.md          — original brainstorm (all 5 rounds)
projects/aptis-lms/_context/              — this context package (6 files)
```
