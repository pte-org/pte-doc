# Phase 02: Backend projections and profile

**Status:** Completed
**Stories:** US-02..06, US-08
**Depends on:** Phase01 approved contract

## Goal

Thêm API Host tenant-scoped, thuần đọc, phục vụ schedule và tracking mà không impersonate staff.

## Work items

1. Identity: safe staff account lookup public facade, complete role set; thêm profile update whitelist mới transaction/validation, normalized case-insensitive email uniqueness và duplicate conflict mapping.
2. Session: inverse ProctorAssignment query paged theo tenant/proctor; join scoped nondeleted session/exam; batch summary metadata theo public contract. Không dùng ProctorSession monitoring làm schedule source.
3. Scoring: aggregate committed ExaminerAttemptAssignment theo examiner/session. Preaggregate submitted ExaminerAnswerScore để join không nhân count, dùng eligible snapshot và distinct attempts/batches.
4. Tách work status/session/publication, giữ published sessions. Trả totals đồng bộ predicate; không broad exclude terminal history theo personal queue.
5. Thêm bounded examiner-session pages và totalByStatus cho board/table. Counts áp dụng base date/session/exam/publication filters; status selector dùng chọn column/page, documented rõ count domain.
6. examstaff composition: controller HOST_ADMIN + service-level scope, public facades only. GET detail/overview/work endpoints đúng contract, không expire previews/tạo report hay gọi repositories xuyên module.
7. Overview dates/filter contract giống work sections, count ca distinct; Proctor buckets lifecycle/schedule rõ ràng, no fake attendance; optional next session dùng bounded query.
8. Filter date optional bằng dynamic predicates; absent bound không tạo SQL null-typed parameter. Validate reversed bounds/invalid timezone IDs/status/page; define max page size.
9. Kiểm query plan/index needs khi dữ liệu representative; chỉ add index/migration đúng repo convention sau evidence, không thêm entity assignment mới.

## Design Constraints

Preflight: existing public module facades delegate to internal services; response records use named DTO interfaces; DomainException carries stable codes and HTTP status; repository-owned queries preserve tenant/deleted scope. Applicable: authorization, ownership, single source, bounded pagination, no N+1, explicit unavailable fields, data-layer email uniqueness. No exceptions authorized.

- No cross-module repository imports, no dependency cycle.
- Scope mọi session/assignment trước metadata projection kể cả historical malformed references.
- Chỉ profile endpoint được mutation; GET side-effect-free.
- Không sửa broader assignment creation command trong phase này.

## Focused verification

- Fixtures unrelated answer scores, duplicated answer rows, absent eligible snapshot và out-of-range counts không được làm completed giả; UNAVAILABLE pages/counts reconcile với ALL table và overview.
- Focused repository/service/controller tests: tenant IDOR, role/suspended/combined roles, field tampering, email conflict.
- Scoring fixtures committed vs preview, supplementary batches, zero eligible, mixed states, duplicate submission joins, published/deleted/inconsistent data.
- Date absent/from-only/to-only/both, overlap exact boundaries, paging stable, board counts match table filter; UTC zone conversion.
- No writes during workspace GET; module verification nếu repo có; PostgreSQL nullable-filter execution tách khỏi H2 evidence.

## Quality and Testing State

- Implementation: implemented; production compile passed with tests explicitly skipped.
- Quality: APPROVED after independent verification of both remediations; report `quality/phase-02-backend-projections-and-profile-quality-report.json`, receipt `quality/phase-02-backend-projections-and-profile-receipt.json` verified VALID. This is static review and compilation evidence, not live database/API proof.
- Testing: not_started; user declined writing/running tests. Compile/build remain required.
- User checkpoint: user authorized automatic continuation through all phases, with manual UI review at the end.
- Không ghi completed/approved chỉ từ static review hay phase trước.
- Additional user-requested SessionLifecycleService refactor was implemented and independently approved separately; see `session-lifecycle-refactor.md`. It does not close this phase's findings or approve the remaining feature phases. Frontend phases have not started.

## Files

All paths relative to pte-api/app/src/main. New Java files under com/pte/examstaff/, identity/ExamStaffIdentityService.java, identity/dto/response/ExamStaffAccountView.java, identity/internal/controller/ExamStaffProfileController.java, identity/internal/dto/request/UpdateExamStaffProfileRequest.java, identity/internal/service/ExamStaffAccountService.java, session/StaffScheduleService.java, session/StaffSessionFilter.java, session/dto/response/StaffSessionView.java, session/internal/service/StaffScheduleQueryService.java, scoring/StaffScoringService.java, scoring/dto/response/ExaminerProgressView.java, scoring/internal/service/StaffAttemptProgress.java, scoring/internal/service/StaffSessionProgress.java, scoring/internal/service/StaffScoringQueryService.java.
Modified repositories: identity/internal/repository/UserRepository.java, session/internal/repository/ExamSessionRepository.java, scoring/internal/repository/ExaminerAttemptAssignmentRepository.java, scoring/internal/repository/ExaminerAnswerScoreRepository.java, scoring/internal/repository/ScoringAnswerRepository.java, scoring/internal/repository/ScoringSessionStateRepository.java. Modified scoring/internal/service/ScoringEligibilityQueryService.java.
Additive resources/db/migration/V92__tenant_canonical_email_uniqueness.sql and V93__staff_schedule_lookup_indexes.sql. No live migration executed.

Quality remediation adds Attempt-owned scalar batch context: attempt/AttemptStaffContextService.java, attempt/dto/response/AttemptStaffContextView.java, attempt/internal/service/AttemptStaffContextQueryService.java and modifies attempt/internal/repository/ExamAttemptRepository.java. Scoring closed scalar projections: scoring/internal/repository/StaffAssignmentRow.java, StaffAnswerRow.java, StaffScoreRow.java, StaffPublicationRow.java. Canonical attempt references are excluded when missing/deleted/outside the assignment session; pinned context validates eligible counts including zero-work completion. Session scan uses scalar Criteria tuples, not managed entities. Batch totals count only validated assignments in deterministic batch-id order.

## Acceptance / Blocking gate

Contract tests/authorization checks có evidence; API counts không N+1 và ownership review không blockers.
