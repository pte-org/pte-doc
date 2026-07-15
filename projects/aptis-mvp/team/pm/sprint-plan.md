# Sprint Plan — APTIS MVP (Host-Driven Exam Distribution)

> **Team model:** 4 full-stack generalists (D1–D4). Each developer owns a **vertical slice**
> end-to-end (Prisma + NestJS API + Next.js UI + tests), not a horizontal BE/FE split.
> **Calibration:** level `senior` → SP ×0.75, sprint capacity 110%, epic-level tasks.
> **Timeline:** 1-week MVP (Sprint 1) + a short hardening/QA tail (Sprint 2).

## Sprint Overview
| Sprint | Goal | Stories | Story Points | Duration |
|---|---|---|---|---|
| Sprint 1 | Working end-to-end loop: Admin builds content → creates Host → Host imports roster & exports credentials → Student takes exam & sees score | US-001 … US-014 | 75 pts | 1 week (5 working days) |
| Sprint 2 | Add Admin oversight, app-layer isolation tests, full QA + pilot deploy → **DEMO** | US-015 + cross-cutting | 16 pts | 3 days |
| Sprint 3 (post-demo) | Production hardening: PostgreSQL RLS, refresh-token rotation, worker/async migration — then continue on full `aptis-lms` roadmap | hardening | 13 pts | 3–4 days |

**Pre-demo sprints:** 2 (Sprint 1–2) · **Post-demo:** Sprint 3 hardening, then the full `aptis-lms` roadmap
**Total story points:** 104 (91 pre-demo + 13 hardening) · ≈ 78 senior-adjusted (×0.75)
**Estimated duration:** ~8 working days to demo + ~3–4 days hardening
**Demo gate:** end of Sprint 2 — the full E2E loop runs production-correct (DDD layering, repo host-scoping, outbox-ready write path) with hardening (RLS / refresh / worker) deferred as **additive**, per ADR-005 + operator decision (minimal pre-demo, harden right after).

## Developer Ownership (4 full-stack verticals)
| Dev | Vertical (owns BE + FE + tests for these) | Stories | Tasks | Pts |
|---|---|---|---|---|
| **D1 — Platform & Admin Content (Lead)** | Repo scaffolding, full Prisma schema, auth core + RBAC Guard + host-scoped base repo, Admin login, Question/Exam CRUD | US-001, US-002, US-003, US-004 | T-001…T-008, T-026 | 28 |
| **D2 — Host & Admin Console** | Admin-creates-Host, Host login/dashboard, Admin Host overview, cross-tenant tests, deploy/docs | US-005, US-006, US-015 | T-009…T-012, T-023, T-027 | 16 |
| **D3 — Roster Import & Credential Export (Core Flow)** | Excel upload/parse, per-row validation + student provisioning, exam assignment, credential export/download, E2E test | US-007, US-008, US-009, US-010 | T-013…T-018, T-024 | 27 |
| **D4 — Student Exam Experience & QA** | Student login, exam-taking, submit + scoring, result screen, unit/scoring tests | US-011, US-012, US-013, US-014 | T-019…T-022, T-025 | 18 |

> **Load note:** D1 and D3 carry the two critical-path verticals (shared foundation + the Excel-heavy core flow) and are intentionally heaviest. **Day 1 foundation (T-001…T-003) is a whole-team kickoff** — all four pair on schema + auth contract before splitting off, so D1 is never a solo blocker. D2/D4 (lighter owned load) provide pairing support on the critical path during Week 1 and absorb the Sprint-2 hardening tail.

## Critical Path & Integration Contracts
The minimum-time sequence that gates everything else:

```
T-001 scaffold → T-002 Prisma schema → T-003 auth core + host-scoped base repo
        |                                   |
   (unblocks all)                  T-013 -> T-014 (students exist) -> T-019 student login
                                            |                              |
   T-005 -> T-007 (exams exist) -------> T-016 assign -> T-017 export   T-020 -> T-021 (scoring)
```

**Hard handoff contracts to agree on Day 1 (write the DTO/Prisma shapes down before coding):**
1. **Prisma schema (D1 owns, all review)** — single owner per ADR-002 to avoid migration conflicts; frozen by end of Day 1.
2. **Auth/JWT claim shape** (`role`, `hostId`) + `host-scoped base repo` signature — D1 publishes; D2/D3/D4 consume. Enforces BR-005 / ADR-003.
3. **Student-creation output** (D3 → D4): username derivation `{host_slug}-{identifier}` + students carry their assigned `exam_id` via batch — so D4 student login can resolve the assigned exam.
4. **Exam "assignable" contract** (D1 → D3): `EXAM.is_assignable` true only with ≥1 question (BR-006) — D3's assignment list filters on it.

**Cross-dev synchronization points** (BE↔FE within a vertical are same-dev, so the real choke points are cross-dev):
- D1 exam API ⟷ D3 assignment (T-007 → T-016)
- D3 student provisioning ⟷ D4 student login (T-014 → T-019)
- D1 host-scoped base repo ⟷ D2 & D3 every host-scoped query (T-003 → T-009/T-011/T-013/T-017)

## Sprint 1
**Goal:** Deliver the complete vertical slice — an Admin can build an exam and a Host; a Host can import a roster and download credentials; a Student can log in, take the exam, and see an immediate score.

**Stories included:**
- US-001: Admin login [Essential] — 1 pt
- US-002: Create exam questions [Essential] — 3 pts
- US-003: Edit/delete exam questions [Essential] — 3 pts
- US-004: Group questions into an Exam [Essential] — 3 pts
- US-005: Create Host account [Essential] — 3 pts
- US-006: Host login [Essential] — 1 pt
- US-007: Upload student roster Excel [Essential] — 5 pts
- US-008: Roster row validation report [Essential] — 3 pts
- US-009: Assign Exam to imported batch [Essential] — 3 pts
- US-010: Download generated credentials Excel [Essential] — 5 pts
- US-011: Student login [Essential] — 1 pt
- US-012: View and answer exam questions [Essential] — 5 pts
- US-013: Submit exam (single attempt) [Essential] — 3 pts
- US-014: View immediate score [Essential] — 3 pts

**Day-level sequence (5 working days):**
- **Day 1 (all):** T-001 scaffold, T-002 Prisma schema, T-003 auth core — whole-team kickoff, then split.
- **Day 2–3:** D1 → Admin content (T-004…T-008) · D2 → Host (T-009…T-011) · D3 → roster upload+validation (T-013…T-015) · D4 → student login + exam-taking API (T-019, T-020).
- **Day 3–4:** D3 → assignment + export (T-016…T-018) · D4 → submit/scoring + UI (T-021, T-022).
- **Day 5:** Integration of the full loop; bug bash; demo of the end-to-end flow.

**Definition of Done:**
- All acceptance criteria for the included stories pass (per `team/ba/acceptance-criteria.md`).
- Every Host/Student-scoped endpoint routes through the host-scoped base repo (BR-005).
- No plaintext credential persisted outside the `credential_plaintext_pending` window (BR-001).
- Code reviewed by ≥1 peer; no hardcoded secrets (BR-010); `.env.example` complete.
- No critical bugs; end-to-end happy path demoable.

## Sprint 2
**Goal:** Close the residual multi-tenant risk (ADR-003 #1 threat), add the Admin oversight view, reach the senior QA bar, and deploy the pilot.

**Stories included:**
- US-015: Admin Host activity overview [Conditional] — 3 pts

**Tasks:**
- T-012 Admin Host overview (US-015) · T-023 cross-tenant isolation test suite · T-024 E2E happy-path test · T-025 unit tests for scoring/validation/auth (≥80%) · T-026 pilot deployment · T-027 PR/README/DoD docs.

**Definition of Done:**
- Cross-tenant isolation tests prove Host A cannot read/download Host B's batch, students, or export (BR-005, BR-008).
- Test coverage ≥ 80% on core services (auth, validation, scoring) per senior qa-standard.
- Pilot environment (API + Web + managed Postgres) live with TLS; secrets via env only (BR-010).
- US-015 acceptance criteria pass; deactivated hosts remain visible.

## Demo Gate
At the end of Sprint 2 the MVP slice is **demo-ready**: the full Admin→Host→Student loop runs against the production repos, built production-correct (DDD layering, repository host-scoping, outbox-committing write path, refresh-shaped token port). Hardening (RLS / refresh rotation / worker) is intentionally **not** in the demo build — it is additive and scheduled immediately after (Sprint 3), per ADR-005 + the operator's "minimal pre-demo, harden right after" decision.

## Sprint 3 — Post-demo hardening (production-readiness)
**Goal:** Turn the demo-ready slice into a fully hardened production foundation, then continue onto the full `aptis-lms` 111-FR roadmap.
**Tasks:**
- TASK-028 PostgreSQL RLS policies (defense-in-depth atop repository scoping) — D2 / tenancy
- TASK-029 Refresh-token rotation (opaque, rotate-on-use, hashed; iam token port) — D1 / iam
- TASK-030 Migrate scoring + Excel export to `apps/worker` (BullMQ) via outbox events — D4 / scoring + D3 / export

**Definition of Done:**
- RLS enforced at the DB for every Host/Student-scoped table; cross-tenant tests (TASK-023) still green.
- Access tokens ≤15 min + refresh rotation per `aptis-be/RULE.md`; no call-site changes (port was pre-shaped).
- Heavy paths (scoring, export) run in `apps/worker`, idempotent, consuming outbox events; api write path unchanged.
- No remaining ADR-005 deferral open; ready to pick up the full `aptis-lms` roadmap.
```
