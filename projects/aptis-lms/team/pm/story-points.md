# Story Points — APTIS LMS

## Velocity Estimate

**Assumed velocity:** 44 story points per sprint
**Basis:** Senior team (×0.75 SP multiplier), 110% nominal capacity. M=2 pts, L=4 pts, XL=6 pts. Sprint load includes infra and testing tasks which consume 20–25% of sprint capacity alongside story work.
**Sprint count:** 11 sprints
**Duration:** 22 weeks (~5.5 months)
**Total story points:** 482 pts (456 story pts across 111 stories + 26 infra/QA pts across TASK-001–003, TASK-073, and Sprint 11 QA tasks)

---

## Story Points Summary

| Story | Title | Priority | Size | Points | Sprint | Tasks |
|---|---|---|---|---|---|---|
| US-001 | Email/credential login | Essential | M | 2 | 1 | TASK-004, TASK-006 |
| US-002 | JWT access + refresh token issuance | Essential | M | 2 | 1 | TASK-004 |
| US-003 | Host-based tenant resolution | Essential | M | 2 | 1 | TASK-005 |
| US-004 | Multi-role RBAC union enforcement | Essential | M | 2 | 1 | TASK-004 |
| US-005 | Credential reset via email link | Essential | M | 2 | 1 | TASK-004, TASK-006 |
| US-006 | Force credential change on first login | Essential | M | 2 | 1 | TASK-004, TASK-006 |
| US-007 | Logout + token invalidation | Essential | M | 2 | 1 | TASK-004, TASK-006 |
| US-008 | Guest/Trial exam entry point | Conditional | M | 2 | 3 | TASK-029 |
| US-009 | Question CRUD with all APTIS content fields | Essential | L | 4 | 2 | TASK-008, TASK-013 |
| US-010 | Audio upload for Listening questions | Essential | L | 4 | 2 | TASK-009, TASK-013 |
| US-011 | Image upload for Speaking questions | Essential | L | 4 | 2 | TASK-009, TASK-013 |
| US-012 | Exam template builder (skill + part composition) | Essential | L | 4 | 2 | TASK-010, TASK-013 |
| US-013 | Question bank preview mode | Conditional | L | 4 | 2 | TASK-011, TASK-013 |
| US-014 | Question versioning with immutability guard | Essential | L | 4 | 2 | TASK-008, TASK-013 |
| US-015 | Bulk question import via CSV/Excel | Conditional | L | 4 | 9 | TASK-060 |
| US-016 | Item analysis — p-value and discrimination index | Optional | L | 4 | 9 | TASK-053, TASK-062 |
| US-017 | Eligibility check before attempt creation | Essential | XL | 6 | 5 | TASK-030 |
| US-018 | Pre-exam checks (mic test, fullscreen, instructions ack) | Essential | XL | 6 | 5 | TASK-031, TASK-035 |
| US-019 | Server-authoritative part timers with sync endpoint | Essential | XL | 6 | 5 | TASK-032, TASK-033 |
| US-020 | Reading parts A–D renderer with answer capture | Essential | XL | 6 | 5 | TASK-036 |
| US-021 | Writing parts A–C with live word count | Essential | XL | 6 | 6 | TASK-037 |
| US-022 | Listening parts A–D with CDN audio auto-play | Essential | XL | 6 | 5 | TASK-036 |
| US-023 | Speaking parts A–E 5-stage flow | Essential | XL | 6 | 6 | TASK-038 |
| US-024 | Part transition screen between skills | Essential | XL | 6 | 5 | TASK-035 |
| US-025 | Ordered skill sequencing (Reading → Listening → Writing → Speaking) | Essential | XL | 6 | 5 | TASK-030, TASK-035 |
| US-026 | Exam final submission with attempt finalization | Essential | XL | 6 | 6 | TASK-039 |
| US-027 | Auto-score Reading/Listening raw score computation | Essential | XL | 6 | 7 | TASK-043 |
| US-028 | Band mapping from raw score to APTIS band | Essential | XL | 6 | 7 | TASK-044 |
| US-029 | Results available within 2 minutes of submission | Essential | XL | 6 | 7 | TASK-043 |
| US-030 | Speaking audio → STT transcript pipeline | Essential | XL | 6 | 7 | TASK-045 |
| US-031 | Writing/Speaking LLM scoring with canonical draft schema | Essential | XL | 6 | 7 | TASK-046 |
| US-032 | Teacher scoring queue with AI draft display | Essential | XL | 6 | 7 | TASK-048, TASK-052 |
| US-033 | Teacher score confirmation (AI draft → confirmed final) | Essential | XL | 6 | 8 | TASK-049 |
| US-034 | Student results dashboard with attempt history | Essential | XL | 6 | 8 | TASK-051 |
| US-035 | Four-skill band profile summary per attempt | Essential | XL | 6 | 8 | TASK-051 |
| US-036 | Teacher written feedback visible on student result | Conditional | XL | 6 | 8 | TASK-049, TASK-051 |
| US-037 | Schedule an exam session | Essential | L | 4 | 3 | TASK-021 |
| US-038 | Edit session schedule and send reminders | Conditional | L | 4 | 3 | TASK-021, TASK-028 |
| US-039 | Live exam monitor dashboard with real-time student status | Essential | L | 4 | 4 | TASK-023, TASK-026 |
| US-040 | Extend time for individual student | Essential | L | 4 | 4 | TASK-024, TASK-026 |
| US-041 | Force-submit student attempt | Essential | L | 4 | 4 | TASK-024 |
| US-042 | Close exam session early | Essential | L | 4 | 4 | TASK-024 |
| US-043 | Approve student retake | Conditional | L | 4 | 4 | TASK-024 |
| US-044 | Create course | Essential | M | 2 | 3 | TASK-016, TASK-020 |
| US-045 | Create group and assign teacher | Essential | M | 2 | 3 | TASK-016, TASK-020 |
| US-046 | Enroll individual student into group | Essential | M | 2 | 3 | TASK-018, TASK-020 |
| US-047 | Bulk student import via CSV/Excel | Conditional | M | 2 | 3 | TASK-017, TASK-020 |
| US-048 | Export student credentials after import | Conditional | M | 2 | 3 | TASK-017 |
| US-049 | View and edit student profile | Conditional | M | 2 | 3 | TASK-020 |
| US-050 | Search and filter student list | Conditional | M | 2 | 3 | TASK-020 |
| US-051 | Remove student from group | Conditional | M | 2 | 3 | TASK-018, TASK-020 |
| US-052 | Student individual band progression over time | Conditional | L | 4 | 8 | TASK-054 |
| US-053 | Per-skill score history charts | Conditional | L | 4 | 8 | TASK-054 |
| US-054 | Class average band per skill per group | Conditional | L | 4 | 9 | TASK-055, TASK-058 |
| US-055 | Attempt count and completion rate by group | Conditional | L | 4 | 9 | TASK-055, TASK-058 |
| US-056 | Score distribution histogram per skill | Conditional | L | 4 | 9 | TASK-055, TASK-058 |
| US-057 | Comparative class performance over time | Conditional | L | 4 | 9 | TASK-055, TASK-058 |
| US-058 | Teacher analytics dashboard (all groups) | Conditional | L | 4 | 9 | TASK-055, TASK-058 |
| US-059 | Tenant-level aggregate analytics for Admin | Conditional | L | 4 | 9 | TASK-056, TASK-058 |
| US-060 | License utilization analytics | Conditional | L | 4 | 9 | TASK-056, TASK-058 |
| US-061 | Export student analytics to Excel/CSV | Conditional | L | 4 | 10 | TASK-057, TASK-066 |
| US-062 | Export class analytics report | Conditional | L | 4 | 10 | TASK-057, TASK-066 |
| US-063 | Export tenant analytics summary | Conditional | L | 4 | 10 | TASK-057, TASK-066 |
| US-064 | Item analysis per question visualized | Optional | L | 4 | 10 | TASK-062, TASK-066 |
| US-065 | Auto-flag low-discrimination questions | Optional | L | 4 | 10 | TASK-062 |
| US-066 | Item analysis trends over question versions | Optional | L | 4 | 10 | TASK-062 |
| US-067 | Schedule and download analytics report on demand | Conditional | L | 4 | 11 | TASK-057, TASK-066 |
| US-068 | Analytics dashboard date range filter | Conditional | L | 4 | 11 | TASK-066 |
| US-069 | Tenant Admin custom analytics view config | Optional | L | 4 | 11 | TASK-066 |
| US-070 | Analytics notification when report ready | Optional | L | 4 | 11 | TASK-061, TASK-066 |
| US-071 | Create and activate tenant | Essential | M | 2 | 2 | TASK-014, TASK-025 |
| US-072 | Edit tenant settings and subdomain | Essential | M | 2 | 2 | TASK-014, TASK-025 |
| US-073 | Issue seat license to tenant | Essential | M | 2 | 2 | TASK-015, TASK-025 |
| US-074 | License expiry monitoring and alerts | Conditional | M | 2 | 2 | TASK-015 |
| US-075 | View license seat utilization | Conditional | M | 2 | 2 | TASK-015, TASK-025 |
| US-076 | Deactivate and reactivate tenant | Conditional | M | 2 | 2 | TASK-014, TASK-025 |
| US-077 | Support staff read-only tenant access | Conditional | M | 2 | 3 | TASK-022, TASK-020 |
| US-078 | Sales team view tenant pipeline | Optional | M | 2 | 3 | TASK-025 |
| US-079 | Impersonation log entry on support access | Conditional | M | 2 | 3 | TASK-022 |
| US-080 | Support staff impersonation flow | Conditional | M | 2 | 4 | TASK-022 |
| US-081 | Vendor admin audit log view | Conditional | M | 2 | 4 | TASK-022, TASK-025 |
| US-082 | Sales team exam usage report | Optional | M | 2 | 4 | TASK-025 |
| US-083 | Session invitation email to participants | Essential | L | 4 | 4 | TASK-027, TASK-028 |
| US-084 | Session reminder T-24h email | Conditional | L | 4 | 4 | TASK-027, TASK-028 |
| US-085 | Session reminder T-1h email | Conditional | L | 4 | 4 | TASK-027, TASK-028 |
| US-086 | Score-ready notification to student | Essential | L | 4 | 4 | TASK-050, TASK-061 |
| US-087 | Bulk notification to group | Optional | L | 4 | 4 | TASK-027, TASK-061 |
| US-088 | Guest creates anonymous trial session | Conditional | M | 2 | 9 | TASK-029, TASK-059 |
| US-089 | Trial exam execution with subset of question bank | Conditional | M | 2 | 9 | TASK-029, TASK-059 |
| US-090 | Trial results with upgrade prompt | Conditional | M | 2 | 9 | TASK-059 |
| US-091 | Lead capture form on trial completion | Optional | M | 2 | 9 | TASK-059 |
| US-092 | Trial session expiry and cleanup | Optional | M | 2 | 9 | TASK-029 |
| US-093 | Deterministic question/option shuffle seed stored on attempt | Essential | XL | 6 | 5 | TASK-034 |
| US-094 | Answer option shuffle within questions per attempt | Essential | XL | 6 | 6 | TASK-034, TASK-040 |
| US-095 | Fullscreen enforcement and exit detection | Essential | XL | 6 | 6 | TASK-040, TASK-042 |
| US-096 | Tab-switch and focus-loss detection | Essential | XL | 6 | 6 | TASK-040, TASK-042 |
| US-097 | Violation warning at configurable threshold | Essential | XL | 6 | 6 | TASK-040, TASK-042 |
| US-098 | Auto-terminate attempt on violation threshold breach | Essential | XL | 6 | 6 | TASK-040, TASK-042 |
| US-099 | Proctor notification on violation threshold breach | Essential | XL | 6 | 7 | TASK-041, TASK-027 |
| US-100 | Violation audit report per session | Essential | XL | 6 | 7 | TASK-041 |
| US-101 | Session integrity summary for Exam Coordinator | Essential | XL | 6 | 8 | TASK-041 |
| US-102 | Exam Coordinator intervention log per session | Essential | XL | 6 | 8 | TASK-022 |
| US-103 | Tenant Admin overall integrity report | Conditional | XL | 6 | 8 | TASK-041 |
| US-104 | Resume interrupted attempt from last saved answer | Essential | XL | 6 | 10 | TASK-063 |
| US-105 | Timer continuity on reconnect (server re-validates remaining time) | Essential | XL | 6 | 10 | TASK-064 |
| US-106 | Network disconnect detection and reconnect handler | Essential | XL | 6 | 10 | TASK-064 |
| US-107 | Answer state restored from server on reconnect | Essential | XL | 6 | 10 | TASK-063, TASK-064 |
| US-108 | Speaking audio retry on upload failure | Essential | XL | 6 | 11 | TASK-065, TASK-067 |
| US-109 | Partial audio upload recovery from IndexedDB buffer | Essential | XL | 6 | 11 | TASK-065 |
| US-110 | STT retry queue for failed transcripts | Essential | XL | 6 | 11 | TASK-067 |
| US-111 | Pending-upload status visible to teacher until resolved | Essential | XL | 6 | 11 | TASK-067, TASK-052 |

---

## Task Points Detail

| Task | Title | Type | Size | Points | Sprint |
|---|---|---|---|---|---|
| TASK-001 | Monorepo scaffold | DevOps | XL | 6 | 1 |
| TASK-002 | PostgreSQL + Prisma + RLS | Database | XL | 6 | 1 |
| TASK-003 | Redis + BullMQ + Docker + CI | DevOps | L | 4 | 1 |
| TASK-004 | IAM module — User/JWT/RBAC | Backend | XL | 6 | 1 |
| TASK-005 | Tenancy middleware | Backend | L | 4 | 1 |
| TASK-006 | Auth UI Flutter | Frontend | L | 4 | 1 |
| TASK-007 | Auth integration tests | Testing | M | 2 | 1 |
| TASK-008 | Question CRUD + versioning | Backend | XL | 6 | 2 |
| TASK-009 | Asset presigned upload | Backend | L | 4 | 2 |
| TASK-010 | Exam template API | Backend | XL | 6 | 2 |
| TASK-011 | Preview API | Backend | M | 2 | 2 |
| TASK-012 | Vendor Portal FE scaffold | Frontend | L | 4 | 2 |
| TASK-013 | Question editor + template builder UI | Frontend | XL | 6 | 2 |
| TASK-014 | Tenant CRUD API | Backend | L | 4 | 2 |
| TASK-015 | License management API | Backend | L | 4 | 2 |
| TASK-016 | Course + Group API | Backend | L | 4 | 3 |
| TASK-017 | Bulk student import worker | Backend | L | 4 | 3 |
| TASK-018 | Enrollment API | Backend | L | 4 | 3 |
| TASK-019 | Tenant Portal FE scaffold | Frontend | L | 4 | 3 |
| TASK-020 | Enrollment + student mgmt UI | Frontend | L | 4 | 3 |
| TASK-021 | Exam scheduling API | Backend | XL | 6 | 3 |
| TASK-022 | Support staff + audit log API | Backend | M | 2 | 3 |
| TASK-023 | Live monitor WebSocket | Backend | XL | 6 | 4 |
| TASK-024 | Intervention API | Backend | L | 4 | 4 |
| TASK-025 | Vendor + license mgmt UI | Frontend | L | 4 | 4 |
| TASK-026 | Scheduling + monitor UI | Frontend | XL | 6 | 4 |
| TASK-027 | Notification module | Backend | L | 4 | 4 |
| TASK-028 | Session reminder scheduler | Backend | L | 4 | 4 |
| TASK-029 | Guest/Trial session API | Backend | M | 2 | 4 |
| TASK-030 | ExamAttempt state machine | Backend | XL | 6 | 5 |
| TASK-031 | Pre-exam check API | Backend | L | 4 | 5 |
| TASK-032 | Part timer service | Backend | XL | 6 | 5 |
| TASK-033 | Per-answer persistence + idempotency | Backend | XL | 6 | 5 |
| TASK-034 | Shuffle seed | Backend | M | 2 | 5 |
| TASK-035 | Exam client FE scaffold | Frontend | L | 4 | 5 |
| TASK-036 | Reading + Listening UI | Frontend | XL | 6 | 5 |
| TASK-037 | Writing UI | Frontend | XL | 6 | 6 |
| TASK-038 | Speaking UI — 5-stage + IndexedDB | Frontend | XL | 6 | 6 |
| TASK-039 | Exam submission + outbox | Backend | XL | 6 | 6 |
| TASK-040 | Integrity module — detection + log + threshold | Backend | XL | 6 | 6 |
| TASK-041 | Violation monitor API | Backend | L | 4 | 6 |
| TASK-042 | Integrity UI | Frontend | L | 4 | 6 |
| TASK-043 | Auto-scoring worker | Backend | XL | 6 | 7 |
| TASK-044 | Band mapping service | Backend | L | 4 | 7 |
| TASK-045 | STT pipeline worker | Backend | XL | 6 | 7 |
| TASK-046 | LLM scoring pipeline | Backend | XL | 6 | 7 |
| TASK-047 | Provider-neutral ports | Backend | L | 4 | 7 |
| TASK-048 | Teacher scoring queue API | Backend | L | 4 | 7 |
| TASK-049 | Score confirmation | Backend | XL | 6 | 8 |
| TASK-050 | Results-ready notification trigger | Backend | M | 2 | 8 |
| TASK-051 | Student results FE | Frontend | XL | 6 | 8 |
| TASK-052 | Teacher scoring queue UI | Frontend | XL | 6 | 8 |
| TASK-053 | Item analysis read model job | Backend | L | 4 | 8 |
| TASK-054 | Student analytics API | Backend | L | 4 | 8 |
| TASK-055 | Class analytics API | Backend | L | 4 | 8 |
| TASK-056 | Tenant analytics API | Backend | L | 4 | 9 |
| TASK-057 | Analytics export worker | Backend | L | 4 | 9 |
| TASK-058 | Analytics UI | Frontend | XL | 6 | 9 |
| TASK-059 | Guest/Trial UI | Frontend | L | 4 | 9 |
| TASK-060 | Bulk QB import | Backend | L | 4 | 9 |
| TASK-061 | Notification delivery polish | Backend | L | 4 | 9 |
| TASK-062 | Item analysis advanced | Backend | XL | 6 | 10 |
| TASK-063 | Exam resume endpoint | Backend | XL | 6 | 10 |
| TASK-064 | Network recovery backend | Backend | XL | 6 | 10 |
| TASK-065 | Exam audio retry FE | Frontend | XL | 6 | 10 |
| TASK-066 | Analytics export + advanced UI | Frontend | XL | 6 | 11 |
| TASK-067 | Speaking audio continuity worker | Backend | XL | 6 | 11 |
| TASK-068 | Security hardening | Backend | L | 4 | 11 |
| TASK-069 | Performance + load tests | Testing | L | 4 | 11 |
| TASK-070 | E2E regression suite | Testing | L | 4 | 11 |
| TASK-071 | Observability setup | DevOps | L | 4 | 11 |
| TASK-072 | Deployment runbook | DevOps | M | 2 | 11 |
| TASK-073 | OpenAPI codegen | Backend | M | 2 | 1 |

---

## Sprint Totals

| Sprint | Story Points | Tasks | Task Count |
|---|---|---|---|
| Sprint 1 | 32 (14 story + 18 infra) | TASK-001–007, TASK-073 | 8 |
| Sprint 2 | 36 | TASK-008–015 | 8 |
| Sprint 3 | 32 | TASK-016–022 | 7 |
| Sprint 4 | 46 | TASK-023–029 | 7 |
| Sprint 5 | 48 | TASK-030–036 | 7 |
| Sprint 6 | 48 | TASK-037–042 | 6 |
| Sprint 7 | 48 | TASK-043–048 | 6 |
| Sprint 8 | 50 | TASK-049–055 | 7 |
| Sprint 9 | 46 | TASK-056–061 | 6 |
| Sprint 10 | 48 | TASK-062–065 | 4 |
| Sprint 11 | 48 (40 story + 8 infra) | TASK-066–072 | 7 |
| **Total** | **482** | **All tasks** | **73** |

---

## Story Distribution by Priority

| Priority | Count | Story Points | % of Total |
|---|---|---|---|
| Essential | 62 | ~318 pts | 70% |
| Conditional | 36 | ~106 pts | 23% |
| Optional | 13 | ~32 pts | 7% |
| **Total** | **111** | **456 story pts** | **100%** |

## Story Distribution by Bounded Context

| Bounded Context | Stories | Sprint(s) |
|---|---|---|
| IAM | US-001–007 | 1 |
| Question Bank | US-009–016 | 2, 9 |
| Exam Delivery | US-017–026, US-093–098, US-104–111 | 5, 6, 10, 11 |
| Scoring | US-027–036, US-099–103 | 7, 8 |
| Learning | US-044–053 | 3, 8 |
| Exam Operations | US-037–043 | 3, 4 |
| Tenancy | US-071–082 | 2, 3, 4 |
| Notifications | US-083–087 | 4, 9 |
| Analytics | US-054–070 | 9, 10, 11 |
| Integrity | US-094–103 | 6, 7, 8 |
| Guest/Trial | US-008, US-088–092 | 3, 9 |
| Audit | US-079, US-100–103 | 3, 7, 8 |
