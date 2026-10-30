# Phase 6: attempt + session

## Requirements

> **Quyết định khi cook phase-06-attempt-session (2026-10-25):** session/internal/service gom attendance/audience/draft/enrollment/staff (+lifecycle) và attempt/internal/service/query; AttemptLifecycleService 600->243 (AttemptAccess, AttemptTaskProgression, AttemptStartFlow, AttemptAnswerRecorder, AttemptAudioPlayback, tạo bằng new trong bean), CapabilityNegotiationService 520->168 chuyển sang capability/ (+Evaluator, Normalizer, 2 record), ProctorMonitoringQueryService 344->280 (+ProctorSessionViews), SessionService 319->300 (SessionAttendanceOperations gom 4 service attendance; constructor 9->6 phụ thuộc, chữ ký public giữ nguyên). Mở public tối thiểu cho các lớp dùng chéo package.

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

- Quality gate: approved (xem quality/phase-06-attempt-session-quality-report.json)
- Testing: passed (xem tests/phase-06-attempt-session-test-report.json)

## Risks

- Luồng làm bài là luồng P1 của `pte-app`: kiểm thêm bằng `pte-app` thật nếu người dùng có thể chạy.
