# Plan: Host Mini Console (pte-app) — Milestone 1

Status: 🟡 In Progress
Date: 2026-07-28
Mode: Hard, --tdd
Created by: Hung (Member 3)
Target platform: Desktop (Windows primary)

## Overview

Extend `pte-app/dev` with the Host-facing Milestone-1 workflow while preserving
Member 2's student flow: shared login and role-aware application entry; question
authoring for `MC_READING_SINGLE`, `READ_ALOUD`, and `WRITE_ESSAY`; blueprint and
immutable snapshot publication; full/practice session composition; enrollment
and proctor assignment; score request, essay review, and result publication;
notification and violation audits; and an optional live proctor console.

Implementation follows the current feature-first Clean Architecture and consumes
`pte-api` only through gateway paths. The work is split into vertical phases so
each phase produces a usable, reviewable capability. Phase 00–01 are the first
approved implementation slice; Phase 02–09 remain planned and must not be
started before the preceding phase review.

## Phases

- [x] Phase 0: API Compatibility & Host Shell — central
  `{success,data,message}` envelope handling, distinct 401/403 failures, shared
  login page, Host role gate, and minimal Host workspace
- [x] Phase 1: MC Reading Single Authoring — accessible question list plus
  tenant-private `MC_READING_SINGLE` create form with exactly one correct option
- [x] Phase 2: Read Aloud & Write Essay — backend-aligned text-prompt
  `READ_ALOUD` plus reference-answer/word-count `WRITE_ESSAY` forms
- [x] Phase 3: Blueprint & Immutable Snapshot — blueprint list/create/detail,
  question composition, and one-way snapshot publication
- [x] Phase 4: Session & Composition — full/practice session creation, list,
  detail, snapshot composition, and backend-valid lifecycle actions
- [ ] Phase 5: Enrollment & Proctor Assignment — admin-only user lookup,
  student enrollment, proctor assignment, and permission-aware UI
- [ ] Phase 6: Scoring Review & Publish — score request, new paginated pending
  essay-review query, individual review approval, and result publication
- [ ] Phase 7: Notification & Violation Audit — notification delivery log and
  per-session immutable violation audit views
- [ ] Phase 8: Live Proctor Console — authenticated session-scoped STOMP
  monitoring, reconnect/state recovery, and runtime verification (stretch)
- [ ] Phase 9: QA Gate — standards/architecture sweep, full Flutter regression,
  backend contract evidence, required-path runtime check, and final uncommitted
  handoff review

## Research Summary

1. **App integration baseline:** `pte-app/dev` contains Member 2's current
   student implementation and 37 Flutter test files (28 unit, 8 widget, 1
   integration). `pte-app/main` is an older scaffold and is not the source
   baseline for Member 3.
2. **Architecture baseline:** `pte-app/CLAUDE.md` and
   `pte-app/docs/CODING_STANDARDS_APP.md` require feature-first
   `data/domain/presentation`, repository abstractions, sealed BLoC events,
   separate immutable state classes, GetIt feature modules, resource disposal,
   mounted checks, no hardcoded strings/colors, a 300-line file limit, and
   `flutter analyze`/`flutter test` verification.
3. **Gateway convention:** `ApiClient` base URL is
   `http://localhost:8080` without `/api`; call sites supply full gateway paths
   such as `/api/authoring/questions`.
4. **Envelope mismatch:** backend controllers consistently return
   `ApiResponse<T>{success,data,message}`, while existing Flutter repositories
   read `response.data` as the inner payload. Current repository tests mock the
   already-unwrapped payload, so they do not detect the real runtime mismatch.
   Phase 0 fixes the mismatch centrally at the Dio boundary.
5. **Auth reuse:** `AuthBloc`, `AuthRepository`, `TokenStore`,
   `TokenRefreshInterceptor`, and `JwtClaims` already exist. The root app is
   still a placeholder, so Member 3 adds shared login/root branching without
   rewriting auth internals.
6. **Role model:** Host entry allows `HOST_ADMIN` and `HOST_AUTHOR`; Host claims
   are used only for UI branching. IAM user lookup, proctor assignment, scoring
   request, and result publication are backend-admin operations, so the Host
   author UI must not expose them as available actions.
7. **Authoring contract:** `authoring-service` supports question list/detail and
   create for `MC_READING_SINGLE`, `READ_ALOUD`, and `WRITE_ESSAY`, with
   `SHARED`/`PRIVATE` visibility. Hosts can read shared plus their own private
   content, but Host writes must be `PRIVATE`.
8. **Media and snapshot contracts:** `media-service` already supports
   presign/complete for Host authoring. `authoring-service` already supports
   blueprint list/create/detail and immutable snapshot publish/detail.
9. **Scheduling contract:** session list/detail/create, composition, open,
   close, score, and publish exist. Enrollment and proctor assignment currently
   expose POST commands only; no new list endpoints are justified until Phase 5
   UI evidence requires them.
10. **Confirmed backend gap:** scoring has an individual review command and a
    repository query by session/status, but no controller query for pending
    reviews. Phase 6 adds one tenant-scoped pageable GET endpoint in the scoring
    service.
11. **Audit contracts:** notification list and session violation list already
    exist. The proctor service also contains STOMP code, but the live runtime
    path has not been verified; it remains Phase 8 stretch scope.
12. **Testing boundary:** Flutter has an established test convention and new
    Host features continue it. `pte-api` declares test dependencies but has no
    current Java test-source convention; backend additions require
    compile/package and documented contract verification rather than a broad
    retrofit.
13. **Git/process constraint:** Hung requested that new work remain uncommitted
    until the completed approved slice is reviewed. No push, merge, rebase, or
    branch switch is authorized by this plan.

## Dependencies

- `pte-app/dev` as the Flutter source baseline.
- `pte-api/main` running through the gateway at `http://localhost:8080` for
  runtime contract checks.
- Existing Flutter dependencies: `flutter_bloc`, `dio`, `get_it`,
  `flutter_secure_storage`, `bloc_test`, `mocktail`, and the shared core
  network/storage/widgets.
- Existing backend services: `iam`, `authoring`, `media`, `scheduling`,
  `scoring`, `notification`, and `proctor`.
- `pte-doc/projects/plans/hung-host-mini-console/spec.md` as the canonical
  requirement contract.
- `pte-api/plans/hung-host-mini-console/quality/` for Phase-6 backend
  quality reports/receipts only after backend source is implemented and
  reviewed; no duplicate plan is kept in the implementation repository.
- Phase order: every phase consumes the accepted interfaces of earlier phases;
  Phase 6 additionally depends on approval to modify `scoring-service`.

## Risks

- **HIGH:** Central envelope handling has a cross-feature blast radius because
  auth, exam attempt, sync, media, and reporting all share `ApiClient`.
  Mitigation: request JSON as dynamic at the Dio boundary, preserve typed
  `Response<T>` metadata, retain raw/unwrapped compatibility, and run the full
  existing Flutter suite before Phase 1 begins.
- **HIGH:** `HOST_AUTHOR` can reach some scheduling commands but cannot list IAM
  users or perform admin-only proctor/scoring/publish operations. A UI that
  assumes one uniform Host role will fail at runtime. Mitigation: central pure
  Host role predicates plus per-action backend-aligned gates.
- **MEDIUM:** Backend contracts were transcribed from controller/DTO/service
  source rather than OpenAPI. Mitigation: each phase performs a focused
  controller/DTO contract re-check and records any runtime mismatch before
  changing source.
- **MEDIUM:** Question list, notification list, and some management resources
  are currently non-pageable. Mitigation: consume the current contract for
  Milestone 1; add pagination only where a confirmed backend requirement exists
  (pending essay reviews).
- **MEDIUM:** Runtime verification requires the complete local microservice
  stack, database, Redis, MinIO, and gateway. Mitigation: unit/widget tests
  remain deterministic; blocked runtime checks are recorded as residual items,
  never silently marked passed.
- **MEDIUM:** Keeping all changes uncommitted until Hung's review increases the
  size of the working tree and reduces easy rollback granularity. Mitigation:
  stop at every phase gate, record `git diff --stat` and verification output,
  and do not begin the next phase when the current diff is not understood.
- **LOW:** Windows desktop behavior for secure storage, file selection, audio
  recording, and direct presigned upload can differ from mobile examples.
  Mitigation: Phase 0 reuses the already-tested Windows auth baseline; Phase 2
  includes an early Windows media smoke check.
- **LOW:** Live STOMP code may exist without a fully operable local broker or
  gateway upgrade path. Mitigation: keep Phase 8 isolated and optional; required
  Host delivery does not depend on it.
