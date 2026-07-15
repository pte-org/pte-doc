# Requirements — APTIS MVP (Host-Driven Exam Distribution)

## Executive Summary

APTIS MVP is a 1-week, drastically scoped-down slice of the full APTIS LMS. It validates a single end-to-end flow: an Admin builds exam content, an Admin onboards a Host (a customer's center manager), the Host bulk-imports a student roster via Excel, the system auto-provisions one login per student and hands the Host a downloadable Excel of credentials, and each student logs in and sits the assigned exam with an immediate score. The goal is to prove the credential-distribution and exam-taking loop works end-to-end, not to deliver the full APTIS test format or AI scoring.

## Problem Statement

Training centers (Hosts) need a fast way to get a batch of students into an online exam without manual account creation per student, and without waiting on the platform vendor to provision anything. Today there is no system at all: content is built ad hoc and student access is arranged manually. The cost of not solving this is that centers cannot run timed assessments at scale without slow, error-prone manual account setup, and Admin has no controlled way to hand off exam access to a customer without sharing platform-wide credentials.

## Requirements

REQ-01: The system shall allow Admin to log in with an email and a credential to access the Admin area.
REQ-02: The system shall allow Admin to create, read, update, and delete exam questions (text, options for multiple-choice, correct-answer flag).
REQ-03: The system shall allow Admin to group questions into a named Exam.
REQ-04: The system shall prevent an Exam with zero questions from being assignable to students.
REQ-05: The system shall allow Admin to create a Host account (organization name, contact email) and issue that Host a login credential.
REQ-06: The system shall allow Host to log in using the credential issued by Admin.
REQ-07: The system shall allow Host to upload an Excel (.xlsx) file containing a student roster (full name, unique student code or email).
REQ-08: The system shall validate every row of an uploaded roster (required fields present, no duplicate identifier within the Host's organization) and return a per-row error report for invalid rows without creating accounts for them.
REQ-09: The system shall create one Student account per valid roster row, generating a unique username and a random credential for each.
REQ-10: The system shall allow Host to select an existing Exam and assign it to the batch of students just imported.
REQ-11: The system shall generate a downloadable Excel file listing, for each imported student: full name, username, generated credential, and assigned Exam name.
REQ-12: The system shall restrict download of a generated-credentials file to the Host who triggered that import, via an authenticated session.
REQ-13: The system shall allow Student to log in using the username and credential issued to them.
REQ-14: The system shall present the Student with their assigned Exam's questions and capture each answer as the student progresses.
REQ-15: The system shall allow Student to submit the Exam exactly once and shall reject any further submission attempt for that attempt.
REQ-16: The system shall auto-score objective question types (multiple-choice) immediately upon submission and display the result to the Student.
REQ-17: The system shall scope all Host and Student data access to the Host's own organization, so one Host can never see another Host's students, exams assignments, or credential exports.
REQ-18: The system shall allow Admin to view a list of all Hosts together with each Host's student count and exam-assignment status.
REQ-19: The system shall store all account credentials as salted hashes and never write a plaintext credential to logs or persistent storage outside the one-time generated export file.

## Actors

| Actor | Role | Technical Proficiency | Frequency of Use | Data Access |
|---|---|---|---|---|
| Admin | Platform owner / content manager | Intermediate | Weekly | Admin (all exams, all hosts) |
| Host | Customer-side center manager | Basic | Occasional (per exam batch) | Write (own organization's students/exams) |
| Student | Exam-taker | Basic | Occasional (single exam sitting) | Read/Write (own attempt only) |

## In Scope

- Admin authentication and CRUD on exam questions and exams (flat list, multiple-choice question type)
- Admin-created Host accounts with issued login credentials
- Host authentication
- Host Excel roster upload with row-level validation and error reporting
- Automatic Student account + credential generation per valid roster row
- Host-triggered selection of an Exam to assign to an imported batch
- Excel export of generated usernames/credentials for Host download
- Student authentication using issued credentials
- Student exam-taking UI: view questions, capture answers, single submission
- Immediate auto-scoring for multiple-choice questions
- Organization-level data isolation between Hosts (application-layer scoping, not full DB RLS)
- Admin view of Host list with basic activity counts

## Out of Scope

- Full APTIS 4-skill test format (Listening/Reading/Writing/Speaking with audio, timers per part, shuffle seeds)
- AI-assisted scoring or teacher score-confirmation workflow for subjective answers (Writing/Speaking)
- Real-time exam monitoring, integrity/violation detection, fullscreen/tab-switch guards
- Automated email delivery of credentials to students (Host receives one Excel file; manual distribution from there)
- Multi-tenant PostgreSQL Row-Level Security (deferred — MVP uses host_id-scoped queries at the application layer only)
- Notifications (reminders, results-ready alerts)
- Analytics dashboards, item analysis, score trend reporting
- License/billing management, vendor-portal richness beyond Admin login
- Guest/trial anonymous exam flow
- Password reset / forgot-credential self-service flow for Student or Host
- Mobile app (Flutter); MVP is web-only
- Bulk question-bank import via Excel for Admin (manual CRUD only)
- Exam retake support (one attempt per generated account)

## Assumptions

Assumption 1: "Exam" for the MVP is a flat set of multiple-choice questions only, with no audio/speaking content and no per-part timer. — Risk if wrong: if the stakeholder expects the real APTIS 4-skill format with audio in this 1-week build, the entire question/exam model and scoring engine would need to be rebuilt; this MVP would not be reusable for that purpose without rework.

Assumption 2: Credential delivery to students is entirely via the Excel file the Host downloads; the platform does not email or SMS credentials directly to students. — Risk if wrong: if Host expects the system to notify students directly, an extra distribution step (and the channel for it) must be added, which is currently unscoped.

Assumption 3: One Host account represents one organization with no sub-roles (no separate "teacher" login under a Host). — Risk if wrong: if a center has multiple staff needing independent access, the single shared Host login becomes a bottleneck and a security/audit gap (shared credential).

Assumption 4: Each generated Student account gets exactly one Exam assignment and one allowed attempt; there is no mechanism in this MVP to reassign a different exam or grant a retake. — Risk if wrong: any Host request for "redo the exam for this student" requires a manual data fix outside the product in week 1.

Assumption 5: Application-layer host_id scoping (rather than full DB Row-Level Security) is acceptable for the MVP's data-isolation requirement. — Risk if wrong: a missed `WHERE host_id = ?` filter in any query is a cross-tenant data leak; this is an explicit risk accepted to hit the 1-week timeline, and should be flagged for hardening before this MVP is shown to more than one paying customer.

## Conflicts Detected

None detected. This MVP intentionally narrows the scope of the existing `aptis-lms` project (111 FRs / 25 BRs / 11-sprint roadmap) down to a single end-to-end flow; it is a separate, parallel artifact set and does not modify or conflict with the full-scope requirements already on file for `aptis-lms`.

## Flags from Previous Agents

No flags detected.
