# Vision — APTIS LMS

## Problem Statement

Schools and training centres in Vietnam preparing students for the APTIS exam (British Council) lack a dedicated platform that simultaneously covers three needs: a high-fidelity simulation of the official exam environment, centralised learner management with batch enrollment and result tracking, and deep skill-level analytics for teachers to adjust instruction. No existing SaaS in the Vietnamese market combines all three in a scalable multi-tenant architecture.

## Solution Summary

APTIS LMS is a multi-tenant B2B2C SaaS platform with three subsystems:

| Subsystem | Users | Core function |
|-----------|-------|---------------|
| Vendor Portal | Super Admin, Content Manager, Support Staff, Sales Team | Global administration, question bank management, tenant/license management |
| Tenant Portal | Tenant Admin, Teacher, Exam Coordinator, Viewer | Student management, exam scheduling, live proctoring, scoring review, analytics |
| Exam Client | Student, Guest | Full 4-skill APTIS simulation; cross-platform Flutter |

Each tenant (school or training centre) is an isolated namespace under its own subdomain (`slug.aptis-lms.vn`). The Vendor controls the shared question bank; tenants run exams from Vendor-provided templates. Writing and Speaking are scored by an AI pipeline (STT + LLM) with mandatory Teacher confirmation before results reach students.

## Success Metrics

| Metric | Target |
|--------|--------|
| Exam session completion rate (no data loss) | ≥ 95% |
| Auto-score latency (Reading / Listening) | ≤ 2 minutes post-submit |
| System uptime during active exam sessions | ≥ 99.9% |
| Tenant activation rate (≥ 1 exam session within 30 days of license) | ≥ 80% |
| Student band progression (improvement after ≥ 2 attempts) | Baseline to be measured after 3 months live |

## Constraints

1. **Exam continuity is #1 priority** — per-answer state is persisted server-side; the server-authoritative timer never resets on reconnect; no data loss is acceptable under any network condition within the exam window.
2. **AI scoring is draft-only** — AI scores for Writing and Speaking are never shown to students without Teacher confirmation (BR-13). The system cannot auto-confirm.
3. **Data compliance pending** — NĐ 13/2023/NĐ-CP applicability must be confirmed by Legal before cloud region and data retention periods can be decided (OI-07). This is the single longest-lead item on the pre-development critical path.
