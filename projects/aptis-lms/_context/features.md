# Features — APTIS LMS

## IN Scope (v1.0)

| Feature | Priority | Key FRs | Notes |
|---------|----------|---------|-------|
| F-01: Authentication & Access Control | Essential | FR-01 – FR-08 | JWT (access 15 min / refresh 7 days rotating), RBAC multi-role, subdomain tenant routing, guest anonymous session |
| F-02: APTIS Question Bank Management | Essential | FR-09 – FR-16 | 4 skills × 16 parts; audio/image asset management; exam template builder; version control; bulk import; item analysis view |
| F-03: Exam Simulation — Full Mode | Essential | FR-17 – FR-29 | Full 4-skill APTIS simulation; server-authoritative timer; Reading/Writing/Listening/Speaking interfaces; part sequencing; auto-submit on timeout |
| F-04: Scoring System | Essential | FR-30 – FR-36 | Auto-score (R/L); AI pipeline STT + LLM (W/S draft); Teacher review queue; score finalization; result dashboard; feedback narrative |
| F-05: Exam Scheduling & Deployment | Essential | FR-37 – FR-43 | Session creation; publish + notify; live monitor (WebSocket/SSE); time extension; force submit; retake approval |
| F-06: Learner Management (LMS) | Essential | FR-44 – FR-52 | Course + group management; manual enroll; CSV bulk import; bulk account export (with plain-text password — one-time only); seat quota tracking |
| F-07: Analytics & Reporting | Essential | FR-53 – FR-70 | Student dashboard (history, progression chart, skill breakdown); class report; tenant admin dashboard; item analysis (difficulty + discrimination index) |
| F-08: Vendor Management | Essential | FR-71 – FR-78 | Tenant lifecycle; per-tenant config; license management; quota alerts (80%/90%); tenant usage monitoring; read-only impersonation |
| F-09: Sales Team Portal | Essential | FR-79 – FR-82 | Customer list; create/renew/adjust license; license history; expiry alert dashboard |
| F-10: Notification System | Essential | FR-83 – FR-87 | 10 email trigger types (session publish, results, SLA reminder, quota, license expiry); delivery logging; preference opt-out; bilingual templates (Vi/En) |
| F-11: Guest / Trial Flow | **Conditional** | FR-88 – FR-92 | Trial landing page; limited exam; basic result + CTA; optional lead capture; data purge — scope TBD (OI-06) |
| F-12: Exam Integrity (Anti-cheat) | Essential | FR-93 – FR-103 | Question/answer shuffle; fullscreen enforcement; tab-switch/focus-loss detection; copy-paste block; navigation block; configurable violation thresholds; kiosk mode (Desktop — Conditional FR-102) |
| F-13: Exam Continuity | Essential (#1 priority) | FR-104 – FR-111 | Server timer; per-answer persistence; resume on reconnect; offline indicator; Speaking audio buffer + retry; partial audio recovery; microphone fail handling; crash recovery |

## OUT of Scope (v1.0 — Deferred)

| Feature | Reason | Target version |
|---------|--------|---------------|
| Payment / Billing automation | Sales manages invoices manually outside the system; no ROI for payment gateway at launch | v2.0 |
| Video proctoring | Storage/privacy costs; browser anti-cheat (F-12) sufficient for v1 | v3.0 |
| Issuing official APTIS certificates | No British Council authorization; platform is simulation only | Never |
| LMS external integrations (Moodle, Canvas, Google Classroom) | No tenant demand at launch; CSV import (FR-47) serves as manual bridge | v2.0 |
| Tenant-authored question banks | Vendor owns all content in v1 (Assumption A-04); `questions` schema has no `tenant_id` | v2.0 |
| Flutter Mobile Exam Client | Desktop + Web covers supervised exam; mobile expands independent study use case | v1.5 |
| Marketplace for exam content | Business model and quality control not ready | v3.0+ |
