# Phase 02: Atomic attendance commands and lifecycle

Status: pending; dependency01. P1 presence/correction/concurrency. FR03–09.

## Design Constraints

Read authority precedes receipt disclosure; new mutation requires current lifecycle/enrollment/role. Same shared session mutex before attendance lock. Attendance has no side effects on attempts, eligibility, grade, cohort or publication.

## Files and steps

- [x] Add session/internal/service/AttendanceCommandService, AttendanceReadQueryService/AttendancePolicy and public SessionService facade methods. Reuse local session/assignment/enrollment ownership checks rather than importing Proctoring internals. Proctor and Host caller contexts are explicit, not whichever role happens to be checked first.
- [x] Add an attendance-specific tenant-scoped session lock/capability path through actual session lifecycle/operation guard classes. Clock injection uses existing ClockConfig; boundary inclusive opensAt-30minutes, exclusive closesAt. Missing/invalid times fails closed. SCHEDULED/OPEN only for new Proctor write; Host SCHEDULED/OPEN/CLOSED with reason; CANCELLED other preparatory states read-only.
- [x] Align EnrollmentService.unenroll with findOwnedWithLock; verify enroll/bulk-enroll/class-unassign/close/cancel/unassignProctor locks. Use same mutex for assignProctor/updateProctorRole too without changing role privileges/delete behavior. Resolve lock matrix from source; do not take subscription lock after session.
- [x] Transaction: lock session; verify current actor/tenant and assigned Proctor or Host read access; check target current enrollment generation (Host history receipt may reference past generation explicitly); lookup scoped immutable receipt. Match fingerprint/actor/target/key exactly before mutable cutoff/version checks. Wrong intent/key returns409; no score-like normalized-fingerprint compatibility fallback.
- [x] For a new command validate policy, exact enrollment UUID and expectedVersion; lock/read current row under mutex. Version0 only means no row; first write version1. Existing old-generation row displays effective UNMARKED with its monotonic version; new-generation write records old/new generation context and increments, without mutation on GET.
- [x] Validate reason: first UNMARKED→PRESENT/ABSENT optional note; PRESENT↔ABSENT or marked→UNMARKED requires nonblank reason; every Host command requires reason. Trim and length bounds before the same canonical fingerprint is used for storage/replay. Initial ABSENT is never automatic.
- [x] Apply change + append command atomically. Same-status exact current-version command produces changed=false receipt, no version increment/no duplicated transition history. Same request replay returns saved receipt; response includes separately labelled latest current snapshot/version. Commit before client success.
- [x] Conflict/read-only/revoked/removed-generation responses must be definitive failures; network/lost response stays unknown. Unique receipt conflicts map only the known constraint, never catch every integrity error as retry success. No continuation in rollback-only transaction.
- [x] Add history reads with safe actor display projection, past enrollment generation, chronological stable pagination. Never delete old records on reset/unenroll; no background absent marking, no grading disposition event.

## Acceptance evidence

Exactly opensAt-30m permits; one instant earlier denies; closesAt denies. CLOSED Proctor cannot create a change, exact authorized old receipt is read-only recovery; revoked Proctor cannot replay/disclose. Host correction needs reason. Two first-write expectedVersion0 commands result in one mutation and one conflict. Reset/re-enrollment cannot cause ABA. Close/revocation/unenroll serialization does not permit a mutation after the competing operation commits.

## Quality and Testing State

Quality not evaluated; testing not started; prior skip retained. Compile planned; transaction/race/SQL behavior not established by compilation. No tests/E2E added automatically.
