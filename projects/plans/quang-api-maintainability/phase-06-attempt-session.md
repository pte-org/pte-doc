# Phase 6: attempt + session

## Requirements

| File | Dòng |
|---|---|
| `attempt/internal/service/AttemptLifecycleService.java` | 597 |
| `attempt/internal/service/CapabilityNegotiationService.java` | 520 |
| `session/internal/service/ProctorMonitoringQueryService.java` | 344 |
| `session/SessionService.java` (facade công khai) | 319 |

Kèm gom `session/internal/service` (30 file) và `attempt/internal/service` (17).

## Đề xuất gom

**`session/internal/service`:**

| Package con | Lớp |
|---|---|
| `attendance/` | `Attendance*`, `StoredAttendanceReceipt`, `IdentityVerificationService` |
| `audience/` | `AudienceResolver`, `ExamAudienceService`, `SessionClassSourceService` |
| `draft/` | `ExamDraftService`, `ExamPublishService`, `ExamSkillSelection`, `SessionExamPreviewService`, `SessionCodeGenerator` |
| `enrollment/` | `EnrollmentService`, `EntitlementService`, `SessionEntryGate` |
| `staff/` | `ProctorAssignmentService`, `ProctorMonitoringQueryService`, `SessionStaffAssignmentQueryService`, `StaffScheduleQueryService` |
| gốc / `lifecycle/` (đã có) | `SessionLifecycleService`, `SessionOperationGuardService`, `SessionGradingService`, `ExamSessionAccess` |

**`attempt/internal/service`:** `query/` (các `Attempt*QueryService`, `SubmittedAnswerQueryService`), `capability/` (`CapabilityNegotiationService` sau khi tách), giữ gốc cho lifecycle/submit/timer.

## Design Constraints

- `AttemptLifecycleService`: tách start / resume / submit / force-submit; giữ khoá dòng và idempotency như cũ (test Postgres `EnrollmentConcurrency*` phải xanh).
- `CapabilityNegotiationService`: tách phần so khớp manifest (thuần, dễ unit test) khỏi phần gọi entitlement/assessment.
- `SessionService` là facade: giữ chữ ký, chuyển thân vào `internal`.
- `pte-app` gọi các route attempt/preflight: không đổi JSON.

## Steps

1. Dời file vào package con (commit riêng).
2. Tách 4 file lớn.
3. Cập nhật allowlist.

## Success Criteria

- Bốn file ≤ 300 dòng; hai thư mục service gốc ≤ 15 file.
- Suite + test Postgres xanh; Docker gate: `seed-local-exam-ready.ps1` chạy hết (preflight học viên, bắt đầu, nộp bài).

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Risks

- Luồng làm bài là luồng P1 của `pte-app`: kiểm thêm bằng `pte-app` thật nếu người dùng có thể chạy.
