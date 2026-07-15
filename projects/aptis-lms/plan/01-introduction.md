# Plan File 01 — Introduction (SRS §1)
Project: APTIS LMS  
Date: 2026-06-16

---

## §1.1 Purpose

**What to write in SRS:**

This document specifies the software requirements for **APTIS LMS** (Hệ thống triển khai thi thử APTIS), a multi-tenant B2B2C SaaS platform for simulating and managing APTIS (Assessment of Professional English) practice examinations.

The intended audience for this SRS is:
- **Development team (TechLead, Backend, Frontend/Flutter engineers):** complete, unambiguous implementation specification
- **QA engineers:** testable requirements with Given/When/Then acceptance criteria
- **Product owner / Vendor stakeholders:** agreement on what will be built in v1
- **TechLead agent:** input for architecture design decisions

This document covers all three subsystems: Vendor Portal, Tenant Portal, and Exam Client (Flutter cross-platform).

---

## §1.2 Scope

**What to write in SRS:**

### System Name
APTIS LMS — Hệ thống triển khai thi thử APTIS đa bên

### What the system does
APTIS LMS enables:
1. **Vendors** to manage content (APTIS question bank, 4 skills × 16 parts), tenants, and licenses
2. **Schools and training centers (Tenants)** to manage learners, deploy practice exams, and analyze results
3. **Students (Learners)** to take full APTIS practice exams in a simulated environment identical to the real exam

### IN Scope — full table

| Feature Cluster | Priority |
|---|---|
| F-01: Authentication & Access (email/JWT/RBAC multi-role/subdomain multi-tenant) | Essential |
| F-02: APTIS Question Bank Management (16 parts, audio, images, templates, item analysis) | Essential |
| F-03: Exam Simulation — Full Mode (timer, audio player, speaking recorder, writing counter) | Essential |
| F-04: Scoring System (auto + hybrid AI+human for Speaking/Writing) | Essential |
| F-05: Exam Scheduling & Deployment (create, publish, monitor, intervene) | Essential |
| F-06: Learner Management (enrollment, CSV import, bulk account+password export, groups) | Essential |
| F-07: Analytics & Reporting (4 views: student, class, tenant, item analysis) | Essential |
| F-08: Vendor Management (tenant lifecycle, seat-based license, alerts) | Essential |
| F-09: Sales Team Portal (customer list, license create/renew/adjust) | Essential |
| F-10: Notification System (email + push) | Essential |
| F-11: Guest / Trial Flow (limited exam, no account) | Conditional |
| F-12: Exam Integrity / Anti-cheat (shuffle, kiosk, violation tracking) | Essential |
| F-13: Exam Continuity — cross-cutting (server timer, per-answer persist, resume, audio buffer) | Essential |

### OUT of Scope — full table

| Feature | Reason | Future Version |
|---|---|---|
| Payment / Billing automation | Sales handles manually outside system | v2.0 |
| Video proctoring (camera monitoring) | Complexity + privacy; kiosk+tab detection sufficient for v1 | v3.0 |
| APTIS official certification issuance | Not a British Council partner | Never |
| Separate standalone mobile native app | Flutter cross-platform replaces this | N/A |
| External LMS integration (Moodle/Canvas/Google Classroom) | No tenant requirement at v1 | v2.0 |
| Question marketplace (inter-school buying/selling) | Different business model | v3.0+ |

### What the system does NOT claim
- APTIS LMS is a **simulation/practice platform only**. It does not issue official APTIS certificates.
- Scores and band estimates are approximate indicators, not official British Council results.
- The system does not replace the real APTIS exam administered by British Council.

---

## §1.3 Definitions, Acronyms, and Abbreviations

**What to write in SRS:** Full glossary table. Reference Appendix A for complete definitions. Summary of critical terms:

| Term | Definition |
|---|---|
| APTIS | Assessment of Professional English — standardized English proficiency test by British Council |
| Band | APTIS proficiency level: A1, A2, B1, B2, C (aligned with CEFR) |
| Tenant | A school or training center that has purchased an APTIS LMS license |
| Tenant Slug | URL-safe identifier for a tenant, used as subdomain (e.g., `hanoi-english-center`) |
| Seat | One license unit = one active student account in a tenant |
| Exam Session | A scheduled instance of an exam with defined participants and time window |
| Attempt | One student's execution of an exam session (one attempt per session per student by default) |
| Part | A sub-section of a skill in the APTIS exam (e.g., Listening Part A) |
| STT | Speech-to-Text — AI service that converts spoken audio to text transcript |
| LLM | Large Language Model — AI model used for evaluating Writing and Speaking responses |
| RBAC | Role-Based Access Control — permission system where users hold roles that grant permissions |
| JWT | JSON Web Token — stateless authentication token |
| SRS | Software Requirements Specification — this document |
| FR | Functional Requirement |
| NFR | Non-Functional Requirement |
| CDN | Content Delivery Network — for low-latency audio/image delivery |
| GWT | Given / When / Then — acceptance test stub format |
| TBD | To Be Determined — items requiring resolution before development |

Full definitions: see `appendix-a-glossary.md`

---

## §1.4 References

**What to write in SRS:**

| Reference | Description |
|---|---|
| IEEE Std 830-1998 | IEEE Recommended Practice for Software Requirements Specifications |
| APTIS Test Format (British Council) | Official APTIS exam structure — 4 skills, time allocations, part descriptions |
| CEFR (Council of Europe) | Common European Framework of Reference for Languages — A1–C2 scale |
| Nghị định 13/2023/NĐ-CP | Vietnamese Personal Data Protection Decree — compliance reference |
| `projects/aptis-lms/brainstorm.md` | Source brainstorm document for this SRS |
| `projects/aptis-lms/spec.md` | Specification document — source of all requirements |
| `projects/aptis-lms/plan/` | This plan directory — blueprints for each SRS section |

---

## §1.5 Overview

**What to write in SRS:**

Structure of this SRS document:
- **§1 Introduction** (this section): purpose, scope, definitions, references
- **§2 Overall Description**: system context, high-level functions, user characteristics, operating constraints, assumptions
- **§3 Specific Requirements:** detailed FRs (§3.2), NFRs (§3.3), database (§3.4), design constraints (§3.5), system attributes (§3.6), other requirements (§3.7)
- **Appendix A:** Complete glossary
- **Appendix B:** Open issues requiring resolution

The requirements in §3.2 use the following format:
```
FR-NN [Priority]: {Requirement ID}
Requirement: The system shall {precise obligation}.
Given: {precondition state}
When: {trigger event}
Then: {expected outcome}
```

Every "shall" statement is a binding requirement. "Should" statements are non-binding guidance. "May" statements are optional enhancements.
