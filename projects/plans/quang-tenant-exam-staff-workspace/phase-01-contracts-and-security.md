# Phase 01: Contracts and security

**Status:** Completed — quality APPROVED; human checkpoint confirmed by request to implement all remaining phases
**Stories:** US-01..06, US-08
**Depends on:** Product validation trong plan.md đã xác nhận; contract kỹ thuật đã được chuẩn bị và rà soát, chờ human checkpoint

## Goal

Đóng băng quyền, dữ liệu và semantics trước khi sửa production code.

## Work items

1. Đối chiếu UserService/manageable roles, UserController, ProctorAssignment, ExaminerAttemptAssignment/AnswerScore, session lifecycle/timestamps và module dependency graph. Ghi source path/method vào contract notes.
2. Chốt cả role checks cho target lẫn caller. HOST_ADMIN current tenant, suspended read allowed, nonstaff/deleted/cross-tenant ID xử lý không lộ tồn tại; combined privileged roles vẫn theo existing management policy.
3. Chốt account field whitelist/required/max length/date constraints. Email canonical uniqueness trong tenant, giữ username/roles immutable; xác định PATCH identity-owned mới không đổi Student patch.
4. Chốt staff DTO, overview/count semantics, filter options APIs, bounded page/size và stable ordering. Role không phù hợp work tab: contract 4xx cụ thể, không silently fake empty.
5. Chốt Proctor interval overlap, timezone, missing schedules và canceled lifecycle. Không date-filter ca unscheduled nếu không có timestamps; không gọi count ended là attendance.
6. Chốt Examiner eligible/submitted counts, zero-work và unavailable, duplicate/out-of-range handling, committed-only batches, publication retention và per-column count/page response.
7. Xác định new examstaff composition module convention/metadata và public Session/Scoring/Identity facades; không reverse identity -> scoring.
8. Đối chiếu staff credential send-email + confirmation; không thay bằng Student generation. Validate 3 product choices trong master, ghi decision log trước phase02.

## Design Constraints

Preflight: conventions verified in IdentityService, SessionService, ScoringService, UserController and UserProvisioningHelper. DomainException carries HTTP status/stable code; public facades hide internal repositories; entities referenced by UUID; public DTOs live in named response interfaces. Applicable rules: SEC_SERVER_SIDE_AUTHZ, OWN_NO_CIRCULAR_DEPENDENCY, DOM_SINGLE_SOURCE, CONST_MESSAGE_VS_CODE_SEPARATED, API_PAGINATION_BOUNDED, PERF_NO_N_PLUS_ONE, TXN_RACE_HANDLED_AT_DATA_LAYER. No exceptions authorized.
- Examiner date filtering dùng session schedule overlap giống Proctor; đóng băng predicate chung cho overview/board/table/totals, không fallback assignment/submission time.
- Ghi authoritative eligibility source, submitted predicate, soft-delete và eligible answer deduplication key; các score không thuộc eligible assigned attempt không góp progress.
- Đóng băng technical UNAVAILABLE query bucket/page/total riêng và total reconciliation; không persist workflow state mới.
- Không implementation/migration trước khi chốt contract.
- Không thay lifecycle permissions hiện hành, không hardcode task eligibility.
- Không reuse personal queue hoặc mutating batch GET.
- Unknown score/assignment data không được coi là zero.

## Focused verification

- Bảng acceptance matrix gồm Host own tenant/other tenant, unauthorized role, missing/nonstaff/deleted/suspended targets và dual roles.
- Fixtures cho empty assignments, supplemental batches, zero eligibility, mixed progress, published session, null schedule và dates DST.
- Map từng DTO/count với nguồn dữ liệu và predicate; no N+1/no GET write.

## Quality and Testing State

- Implementation: contract prepared in contract.md; no production code changed.
- Quality: approved by independent ck:quality --verify; 0 blocking/advisory/noted findings. [Report](quality/phase-01-contracts-and-security-quality-report.json), [receipt](quality/phase-01-contracts-and-security-receipt.json); receipt verified VALID against current contract.md/spec.md.
- Testing: not_started — user declined writing/running tests for all phases. Compilation/lint/typecheck/build remain applicable to production phases.
- User checkpoint: confirmed; user requested all remaining phases without intermediate pauses.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

Product validation và contract ownership được ghi rõ; không còn quyết định critical để suy đoán.
