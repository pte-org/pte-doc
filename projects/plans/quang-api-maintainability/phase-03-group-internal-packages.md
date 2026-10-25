# Phase 3: Gom exception và DTO nội bộ

## Requirements

Dời file trong các thư mục `internal/` đông nhất vào package con theo khái niệm nghiệp vụ. Chỉ dời, không sửa logic.

## Design Constraints

- Chỉ `internal/**`. Package công khai có `@NamedInterface` (`*/dto/response`, `*/dto/event`, `*/domain/enums`...) giữ phẳng.
- Exception giữ nguyên `code`, HTTP status, message; `GlobalExceptionHandler` không đổi hành vi.
- Mỗi package con ≥ 3 file.

## Đề xuất gom (cook chốt lại khi làm)

**`session/internal/exception` (55 file):**

| Package con | Exception (ví dụ) |
|---|---|
| `attendance/` | `AttendanceConflictException`, `AttendanceIdempotencyConflictException`, `AttendanceReasonRequiredException`, `AttendanceReceiptNotFoundException`, `AttendanceWindowClosedException` |
| `audience/` | `AudienceSource*`, `ExamAudience*`, `ClassAssignment*` |
| `draft/` | `ExamDraft*`, `ExamSchedule*`, `ExamPublishBlockedException`, `GenerationNotReadyException`, `InvalidPolicyPatchException`, `PolicyLockedException`, `InvalidLockdownModeException`, `LegacySessionCreateRequiresNewWorkflowException` |
| `enrollment/` | `AlreadyEnrolledException`, `EnrollmentNotFoundException`, `EnrolledStudentAlreadyStartedException`, `NotEntitledException`, `InvalidSessionCodeException` |
| `lifecycle/` | `SessionNotOpenToClose`, `SessionNotReadyToOpen`, `SessionNotStarted`, `SessionClosed`, `SessionNotCancellable`, `SessionNotClosedFor*`, `ExamCloseTimeNotExtendedException` |
| `capacity/` (hoặc `subscription/`) | `SessionCapacity*`, `SessionSubscription*`, `SessionWindowOutsideSubscriptionException`, `SubscriptionRevocationScopeConflictException`, `SessionTimeConflictException`, `InvalidSessionWindowException`, `InvalidTimezoneException` |
| `staff/` | `AlreadyAssignedException`, `ProctorAssignmentNotFoundException`, `ProctorNotAssignedException`, `InvalidProctorScopeException`, `HostContextRequiredException` |
| gốc | `SessionNotFoundException` (dùng khắp module) |

**`billing/internal/exception` (20):** `plan/` (`Plan*`), `license/` (`LicenseCode*`, `InvalidLicenseKeyRevealPasswordException`, `RequestedCodeAlreadyUsedException`), `order/` (`Order*`, `PayOs*`, `PaymentWebhookException`), `application/` (`TenantApplication*`, `ApplicationNotPendingException`, `RequestedName/TaxCodeAlreadyUsedException`), `setting/` (`PlatformSetting*`), `subscription/` (`Subscription*`).

**Các thư mục khác > 15 file trong `internal/`** (`attempt/internal/exception` 18, `scoring/internal/exception` 17, `itembank/internal/exception` 16, `assessment/internal/exception` 15, `billing/internal/dto/request` 18, `identity/internal/dto/request` 16, `session/internal/dto/request|response`, `overview/internal/dto/response` 15): gom theo cùng nguyên tắc.

## Steps

1. Với từng thư mục: chốt bảng gom, dời file (giữ lịch sử git: người dùng commit bằng `git mv` hoặc git tự nhận rename), sửa `package`/`import`.
2. Xoá thư mục khỏi allowlist của `PackageDensityTest`.

## Success Criteria

- Không còn thư mục `internal/**` nào > 15 file (trừ các package `service/` lớn sẽ gom ở phase 5–6).
- Suite xanh; `ModuleStructureTest` xanh; số endpoint vẫn 260; mã lỗi các test exception không đổi.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Risks

- Import wildcard (`import ...exception.*`) không còn bắt được package con: sửa thành import rõ ràng.
