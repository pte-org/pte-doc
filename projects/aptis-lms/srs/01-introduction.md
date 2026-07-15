# Software Requirements Specification
## APTIS LMS — Hệ thống triển khai thi thử APTIS
### Section 1: Introduction

**Document Version:** 1.0  
**Date:** 2026-06-16  
**Status:** DRAFT  
**Classification:** Internal — Development Use

---

## 1.1 Purpose

This Software Requirements Specification (SRS) defines the complete functional and non-functional requirements for **APTIS LMS** (Hệ thống triển khai thi thử APTIS), a multi-tenant B2B2C Software-as-a-Service platform for deploying, administering, and analyzing APTIS (Assessment of Professional English) practice examinations.

This document is authoritative for:

- **Backend and Frontend (Flutter) development teams:** All system behavior described herein constitutes the implementation contract. Features not described in this SRS are out of scope for v1.
- **QA and test engineers:** Every Functional Requirement (FR) includes Given/When/Then acceptance criteria that define testable pass/fail conditions.
- **TechLead and system architect:** Non-functional requirements (NFRs), design constraints (§3.5), and system attributes (§3.6) define the architectural envelope within which the system must be designed.
- **Product owner and Vendor stakeholders:** This document records the agreed v1 scope. Changes require formal revision with version increment.

This SRS does **not** contain wireframes, implementation code, deployment scripts, or marketing content. Those artifacts are maintained separately.

---

## 1.2 Scope

### 1.2.1 System Name

**APTIS LMS** — Hệ thống triển khai thi thử APTIS đa bên (Multi-tenant B2B2C SaaS)

### 1.2.2 Problem Statement

Schools and training centers in Vietnam preparing students for the APTIS examination (Assessment of Professional English — British Council) currently lack a dedicated platform that simultaneously delivers:

1. **Authentic APTIS simulation** — a practice environment that faithfully replicates the timing, audio, microphone recording, and interface of the real APTIS exam.
2. **Integrated learner management** — bulk account creation, class grouping, enrollment, and exam scheduling from a single administrative interface.
3. **Actionable analytics** — per-student band progression, class-level weakness analysis, item-level quality metrics, all accessible by teachers, coordinators, and administrators without external data exports.

### 1.2.3 Solution

APTIS LMS is a three-sided SaaS platform:

| Side | Actor Group | Core Function |
|---|---|---|
| **Vendor Portal** | Vendor staff (Super Admin, Content Manager, Support, Sales) | Manage all tenants and licenses; maintain the APTIS question bank |
| **Tenant Portal** | School/center staff (Tenant Admin, Teacher, Coordinator, Viewer) | Manage learners, schedule exams, review AI-scored responses, analyze results |
| **Exam Client** | Learners (Students, Guests) | Take full APTIS practice exams on Flutter cross-platform clients |

Each school or training center is an isolated **tenant** with its own subdomain (`{slug}.aptis-lms.vn`), its own user base, and strictly isolated data.

### 1.2.4 In-Scope Features

| Feature Cluster | Priority |
|---|---|
| F-01: Authentication & Access (email/JWT/RBAC multi-role/subdomain isolation) | Essential |
| F-02: APTIS Question Bank (4 skills × 16 parts, audio/image, templates, item analysis) | Essential |
| F-03: Exam Simulation — Full Mode (server timer, audio player, speaking recorder, writing counter) | Essential |
| F-04: Scoring System (auto-score + hybrid AI+human for Writing/Speaking) | Essential |
| F-05: Exam Scheduling & Deployment (create, publish, live monitor, intervene) | Essential |
| F-06: Learner Management (enrollment, CSV import, bulk credential export, groups) | Essential |
| F-07: Analytics & Reporting (student, class, tenant dashboard, item analysis) | Essential |
| F-08: Vendor Management (tenant lifecycle, seat-based license, alerts) | Essential |
| F-09: Sales Team Portal (customer list, license create/renew/adjust) | Essential |
| F-10: Notification System (email + optional push) | Essential |
| F-11: Guest / Trial Flow (limited exam, no account) | Conditional |
| F-12: Exam Integrity / Anti-cheat (shuffle, kiosk, violation detection and logging) | Essential |
| F-13: Exam Continuity — cross-cutting (server timer, per-answer persist, resume, audio buffer) | Essential |

### 1.2.5 Out-of-Scope Features

| Feature | Reason | Future Version |
|---|---|---|
| Payment / Billing automation | Sales handles payments manually outside the system | v2.0 |
| Video proctoring (camera monitoring) | Complexity and privacy concerns; kiosk + tab detection sufficient for v1 | v3.0 |
| APTIS official certificate issuance | System is not a British Council authorized center | Not applicable |
| Standalone mobile native app (separate from Flutter) | Flutter cross-platform covers all platforms | Not applicable |
| External LMS integration (Moodle / Canvas / Google Classroom) | No tenant requirement at v1 | v2.0 |
| Question marketplace (inter-tenant buying/selling) | Different business model | v3.0+ |

### 1.2.6 Disclaimer

APTIS LMS is a **practice and simulation platform**. It is not affiliated with, authorized by, or endorsed by British Council. Scores and band estimates produced by this system are approximations for learning purposes and do not constitute official APTIS results.

---

## 1.3 Definitions, Acronyms, and Abbreviations

Complete definitions are provided in Appendix A (Glossary). The following terms are critical to reading this document correctly:

| Term | Brief Definition |
|---|---|
| **APTIS** | Assessment of Professional English — British Council's standardized English test |
| **Band** | APTIS/CEFR proficiency level: A1, A2, B1, B2, C |
| **Tenant** | A school or training center using APTIS LMS under a purchased license |
| **Slug** | URL-safe tenant identifier used as subdomain (e.g., `hanoi-english`) |
| **Seat** | One license unit = one active student account in a tenant |
| **Exam Session** | A scheduled exam deployment with defined participants and time window |
| **Attempt** | One student's single execution of an exam session |
| **Part** | A sub-section of an APTIS skill (e.g., Listening Part A) |
| **STT** | Speech-to-Text — AI service converting Speaking audio to transcript |
| **LLM** | Large Language Model — AI model scoring Writing and Speaking |
| **RBAC** | Role-Based Access Control |
| **JWT** | JSON Web Token — stateless authentication token |
| **FR** | Functional Requirement |
| **NFR** | Non-Functional Requirement |
| **GWT** | Given / When / Then — acceptance criteria format |
| **TBD** | To Be Determined — requires resolution before FINAL status |

---

## 1.4 References

| Reference | Document |
|---|---|
| [IEEE 830-1998] | IEEE Recommended Practice for Software Requirements Specifications |
| [APTIS-FORMAT] | APTIS Test Format documentation — British Council (public) |
| [CEFR] | Common European Framework of Reference for Languages — Council of Europe |
| [ND13-2023] | Nghị định 13/2023/NĐ-CP — Vietnamese Personal Data Protection Decree |
| [BRAINSTORM] | `projects/aptis-lms/brainstorm.md` — source brainstorm |
| [SPEC] | `projects/aptis-lms/spec.md` — source specification |
| [PLAN-00] | `projects/aptis-lms/plan/00-overview.md` — plan master map |

---

## 1.5 Document Overview

This SRS is organized as follows:

| Section | Content |
|---|---|
| §1 Introduction | Purpose, scope, definitions, references (this section) |
| §2 Overall Description | System context, high-level functions, user characteristics, constraints, assumptions, feature apportioning |
| §3.1 External Interfaces | User interfaces (per screen), hardware, software APIs, communication protocols |
| §3.2 Functional Requirements | All 111 FRs in shall + GWT format, organized by feature cluster |
| §3.3 Performance | All 14 NFRs in ISO/IEC 25023 Quality Attribute Scenario format |
| §3.4 Database | Entity definitions, data volumes, PII fields, retention policy |
| §3.5 Design Constraints | Non-negotiable technology and compliance constraints |
| §3.6 System Attributes | Reliability, availability, security, maintainability, portability, usability |
| §3.7 Other Requirements | i18n, legal, operational, training, transition |
| Appendix A | Complete glossary of domain and technical terms |
| Appendix B | All open items (TBDs) with owner and impact |

Every "**shall**" statement in §3.2 is a binding requirement. "**Should**" denotes non-binding guidance. "**May**" denotes optional capability permitted but not required.
