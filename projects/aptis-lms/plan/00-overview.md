# Plan File 00 — Master Overview
Project: APTIS LMS  
Date: 2026-06-16  
Source: `projects/aptis-lms/spec.md`

---

## Purpose of This File

Master map for the SRS generation phase. Lists all plan files, FR/NFR totals, actor table, and cross-reference index. SRS generator reads this file first to understand the full scope before writing any section.

---

## Plan Files Index

| File | SRS Section | Content |
|---|---|---|
| `01-introduction.md` | §1 Introduction | Purpose, Scope, Definitions, References, Overview |
| `02-overall-description.md` | §2 Overall Description | System perspective, functions, user characteristics, constraints, assumptions |
| `03-01-external-interfaces.md` | §3.1 External Interfaces | UI screens, hardware, software APIs, communication protocols |
| `03-02-functional-requirements.md` | §3.2 Functional Requirements | All 111 FRs with shall clauses + GWT stubs |
| `03-03-performance.md` | §3.3 Performance | All NFRs with numeric targets or [TBD] |
| `03-04-database.md` | §3.4 Database | Entities, volumes, PII fields, retention |
| `03-05-design-constraints.md` | §3.5 Design Constraints | Imposed tech, compliance-driven constraints |
| `03-06-system-attributes.md` | §3.6 System Attributes | Reliability, availability, security, maintainability, portability, usability |
| `03-07-other-requirements.md` | §3.7 Other Requirements | i18n, legal, operational, training, transition |
| `appendix-a-glossary.md` | Appendix A Glossary | Domain terms with precise definitions |
| `appendix-b-open-issues.md` | Appendix B Open Issues | All [TBD] / [NEEDS USER INPUT] items, owner, resolve-by |

---

## FR / NFR Totals

| Category | Count |
|---|---|
| Total FRs | **111** |
| Essential FRs | **106** (FR-01 – FR-87, FR-93 – FR-111) |
| Conditional FRs | **5** (FR-88 – FR-92, Guest/Trial flow) |
| Optional FRs | **0** |
| Total NFRs | **14** (NFR-01 – NFR-X) |
| Confirmed NFRs | **5** (NFR-03, NFR-05, NFR-12, NFR-13, NFR-X) |
| TBD NFRs | **9** |
| Business Rules | **15** (BR-01 – BR-15) |
| Open Items | **8** (OI-01 – OI-08) |

---

## FR Numbering Map

| FR Range | Feature Cluster | Priority |
|---|---|---|
| FR-01 – FR-08 | F-01: Authentication & Access | Essential |
| FR-09 – FR-16 | F-02: Question Bank Management | Essential |
| FR-17 – FR-26 | F-03: Exam Simulation (Full Mode) | Essential |
| FR-27 – FR-36 | F-04: Scoring System | Essential |
| FR-37 – FR-43 | F-05: Exam Scheduling & Deployment | Essential |
| FR-44 – FR-51 | F-06: Learner Management (LMS) | Essential |
| FR-52 – FR-70 | F-07: Analytics & Reporting | Essential |
| FR-71 – FR-76 | F-08: Vendor Management | Essential |
| FR-77 – FR-82 | F-09: Sales Team Portal | Essential |
| FR-83 – FR-87 | F-10: Notification System | Essential |
| FR-88 – FR-92 | F-11: Guest / Trial Flow | Conditional |
| FR-93 – FR-103 | F-12: Exam Integrity (Anti-cheat) | Essential |
| FR-104 – FR-111 | F-13: Exam Continuity (Cross-cutting) | Essential |

---

## Actor Summary Table

| # | Actor | Side | Access Scope | Channel |
|---|---|---|---|---|
| 1 | Super Admin | Vendor | admin-global | Web (Vendor Portal) |
| 2 | Content Manager | Vendor | write-content | Web (Vendor Portal) |
| 3 | Support Staff | Vendor | read + limited-write | Web (Vendor Portal) |
| 4 | Sales Team | Vendor | write-tenant | Web (Sales Portal) |
| 5 | Tenant Admin | Tenant | admin-tenant | Web (Tenant Portal) |
| 6 | Teacher / Instructor | Tenant | write-class | Web (Tenant Portal) |
| 7 | Exam Coordinator | Tenant | write-exam | Web / Flutter Desktop |
| 8 | Viewer / Report Only | Tenant | read | Web (Tenant Portal) |
| 9 | Student (registered) | Learner | write-own | Flutter (Desktop/Web/Mobile — TBD) |
| 10 | Guest / Trial Taker | Public | limited | Web (Trial Landing) |
| S1 | Email/Notification Service | External System | outbound integration | API (SendGrid/FCM) |

**RBAC Note:** Users 5–8 can hold multiple roles simultaneously. Permissions = union of all assigned roles. Managed by Tenant Admin.

---

## System Subsystems

| Subsystem | Description | Primary Actors |
|---|---|---|
| Vendor Portal | Web app for Vendor-side operations | Super Admin, Content Manager, Support Staff, Sales Team |
| Tenant Portal | Web app for school/center operations | Tenant Admin, Teacher, Exam Coordinator, Viewer |
| Exam Client | Flutter cross-platform app for taking exams | Student, Guest |
| Backend API | REST API + WebSocket server | All (indirect) |
| AI Scoring Pipeline | Async queue: STT + LLM scoring | System (automated) |
| Notification Service | Email + push outbound | System (automated) |

---

## Assumptions Summary (from spec §8)

| ID | Assumption |
|---|---|
| A-01 | Students have compatible device + working microphone |
| A-02 | APTIS exam structure stable for v1 lifetime |
| A-03 | Tenants have teachers available to review Speaking/Writing |
| A-04 | Vendor manages all question bank content (tenants do not create questions in v1) |
| A-05 | Network at exam location stable enough for audio upload within minutes |
| A-06 | Payment handled entirely outside the system |
| A-07 | One subdomain maps 1-1 to one tenant |
| A-08 | Content Manager has APTIS pedagogical expertise |
| A-09 | Audio storage on cloud approved by users via contract (no in-app consent flow needed) |
| A-10 | Band mapping table (raw score → APTIS band) provided by Vendor, configured statically |

---

## Open Items Requiring Resolution Before SRS Generation

| ID | Topic | Blocking Which FRs/NFRs |
|---|---|---|
| OI-01 | Flutter platform split (which side on which platform) | FR-17 to FR-26, FR-93 to FR-111 (exam client platform) |
| OI-02 | AI provider selection (STT + LLM) | FR-30, FR-31 |
| OI-03 | Speaking/Writing scoring SLA | FR-83 (review SLA notification), NFR-09 |
| OI-04 | Anti-cheat default thresholds | FR-100 |
| OI-05 | NFR numeric targets (performance, scale) | NFR-01, NFR-02, NFR-04, NFR-06, NFR-07, NFR-08, NFR-09 |
| OI-06 | Guest trial limits + lead capture policy | FR-88 to FR-92 |
| OI-07 | Data retention policy + compliance | NFR-10, NFR-11, FR-92 |
| OI-08 | Exam continuity edge cases (deep dive) | FR-104 to FR-111 |
