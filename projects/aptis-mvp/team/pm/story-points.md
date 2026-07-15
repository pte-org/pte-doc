# Story Points — APTIS MVP (Host-Driven Exam Distribution)

## Velocity Estimate
**Assumed velocity:** ~75 nominal pts in Sprint 1 (≈ 56 senior-adjusted) across 4 full-stack devs
**Basis:** Level `senior` calibration — SP ×0.75, sprint capacity 110%. The team is 4 full-stack
generalists, each owning a vertical slice end-to-end, with heavy framework reuse (NestJS DI/Guards,
Prisma codegen, Next.js conventions, Tailwind) that compresses build time. Sprint 1 is deliberately
aggressive (~19 nominal pts/dev in one week, ~14 adjusted) because the scope is a single linear flow
and Day 1 is a shared-foundation kickoff. The 3-day Sprint 2 is a hardening/QA buffer, not new feature load.
**Sprint count:** 2 (1-week core + 3-day tail)

> **Risk flag (PM):** Sprint 1 at 75 pts/week for 4 devs is at the top of feasible. The two largest
> risks to the schedule are the **shared foundation** (T-001…T-003 must land Day 1 or the whole team
> stalls) and the **cross-tenant isolation correctness** (ADR-003 #1 risk — pushed entirely onto code
> review + T-023 tests since there is no DB RLS). Both are sequenced early/explicit on purpose.

## Story Points Summary
| Story | Title | Priority | Points | Sprint | Tasks |
|---|---|---|---|---|---|
| US-001 | Admin login | Essential | 1 | 1 | TASK-003, TASK-004 |
| US-002 | Create exam questions | Essential | 3 | 1 | TASK-005, TASK-006 |
| US-003 | Edit/delete exam questions | Essential | 3 | 1 | TASK-005, TASK-006 |
| US-004 | Group questions into an Exam | Essential | 3 | 1 | TASK-007, TASK-008 |
| US-005 | Create Host account | Essential | 3 | 1 | TASK-009, TASK-010 |
| US-006 | Host login | Essential | 1 | 1 | TASK-011 |
| US-007 | Upload student roster Excel | Essential | 5 | 1 | TASK-013, TASK-015 |
| US-008 | Roster row validation report | Essential | 3 | 1 | TASK-014, TASK-015 |
| US-009 | Assign Exam to imported batch | Essential | 3 | 1 | TASK-016, TASK-018 |
| US-010 | Download generated credentials Excel | Essential | 5 | 1 | TASK-017, TASK-018 |
| US-011 | Student login | Essential | 1 | 1 | TASK-019, TASK-022 |
| US-012 | View and answer exam questions | Essential | 5 | 1 | TASK-020, TASK-022 |
| US-013 | Submit exam (single attempt) | Essential | 3 | 1 | TASK-021, TASK-022 |
| US-014 | View immediate score | Essential | 3 | 1 | TASK-021, TASK-022 |
| US-015 | Admin Host activity overview | Conditional | 3 | 2 | TASK-012 |

**Story points (feature stories only):** 45

## Task Points Detail
| Task | Title | Type | Owner | Size | Points | Sprint |
|---|---|---|---|---|---|---|
| TASK-001 | Monorepo scaffolding & local dev infra | DevOps | D1 | L | 5 | 1 |
| TASK-002 | Prisma schema + initial migration | Database | D1 | L | 5 | 1 |
| TASK-003 | Auth core — JWT, RBAC Guard, host-scoped repo | Backend | D1 | L | 5 | 1 |
| TASK-004 | Admin login page (FE) | Frontend | D1 | S | 1 | 1 |
| TASK-005 | Question CRUD API + validation | Backend | D1 | M | 3 | 1 |
| TASK-006 | Question editor UI | Frontend | D1 | M | 3 | 1 |
| TASK-007 | Exam grouping API | Backend | D1 | M | 3 | 1 |
| TASK-008 | Exam builder UI | Frontend | D1 | M | 3 | 1 |
| TASK-009 | Host provisioning API | Backend | D2 | M | 3 | 1 |
| TASK-010 | Admin Host management UI | Frontend | D2 | M | 3 | 1 |
| TASK-011 | Host login + dashboard shell | Backend+Frontend | D2 | M | 3 | 1 |
| TASK-012 | Admin Host activity overview | Backend+Frontend | D2 | M | 3 | 2 |
| TASK-013 | Roster upload + Excel parse API | Backend | D3 | L | 5 | 1 |
| TASK-014 | Per-row validation + student provisioning | Backend | D3 | L | 5 | 1 |
| TASK-015 | Roster import UI + validation report | Frontend | D3 | M | 3 | 1 |
| TASK-016 | Exam assignment to batch API | Backend | D3 | M | 3 | 1 |
| TASK-017 | Credential export generation + download API | Backend | D3 | L | 5 | 1 |
| TASK-018 | Exam assignment + export/download UI | Frontend | D3 | M | 3 | 1 |
| TASK-019 | Student login + assigned-exam resolution | Backend | D4 | S | 1 | 1 |
| TASK-020 | Exam-taking API (load, answer, resume) | Backend | D4 | L | 5 | 1 |
| TASK-021 | Submit + scoring API | Backend | D4 | M | 3 | 1 |
| TASK-022 | Student exam-taking UI (full flow) | Frontend | D4 | L | 5 | 1 |
| TASK-023 | Cross-tenant isolation test suite | Testing | D2 | M | 3 | 2 |
| TASK-024 | End-to-end happy-path test | Testing | D3 | M | 3 | 2 |
| TASK-025 | Unit tests — scoring/validation/auth (≥80%) | Testing | D4 | M | 3 | 2 |
| TASK-026 | Pilot deployment (PaaS) | DevOps | D1 | M | 3 | 2 |
| TASK-027 | PR descriptions, README & DoD checklist | Documentation | D2 | S | 1 | 2 |

> Task points total **91** > story points total **45** because tasks include shared
> foundation (scaffolding, schema, auth = 15 pts) plus testing/devops/docs (16 pts) not tied to a single story.

**Sprint totals:**
| Sprint | Story Points | Tasks |
|---|---|---|
| Sprint 1 | 75 | 21 |
| Sprint 2 | 16 | 6 |
| **Total** | **91** | **27** |

**Per-developer totals (full-stack ownership):**
| Dev | Vertical | Points | Tasks |
|---|---|---|---|
| D1 | Platform & Admin Content (Lead) | 28 | 9 |
| D2 | Host & Admin Console | 16 | 6 |
| D3 | Roster Import & Credential Export | 27 | 7 |
| D4 | Student Exam Experience & QA | 18 | 5 |
| **Total** | | **89*** | **27** |

> *D1/D3 carry the two critical-path verticals and are heaviest by design; the per-dev sum (89) differs
> slightly from the 91 task total because TASK-011 and TASK-012 are single fullstack tasks spanning BE+FE
> counted once under their owning dev. Day-1 foundation is a shared kickoff to keep D1 off the solo critical path.
