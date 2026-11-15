# Phase 1: Audit ghi đúng vai trò người giải quyết sự cố

Status: Completed

## Requirements

- `resolveIssue` (chỉ `HOST_ADMIN` gọi được) ghi `actorRole = HOST_ADMIN` trong metadata audit, không phải `EXAMINER`.
- Các thao tác của giám khảo (start, report issue, draft) vẫn ghi `EXAMINER`.

## Design Constraints

- Không đổi hợp đồng `ExaminerGradingAuditMetadata` hay dữ liệu audit đã ghi trước đó.
- Dùng hằng vai trò có sẵn nếu có (`Role.HOST_ADMIN.name()`), không thêm chuỗi tự do.

## Related files

- `pte-api/app/src/main/java/com/pte/scoring/internal/service/examiner/ExaminerWorkflowCommandService.java`
- `pte-api/app/src/main/java/com/pte/scoring/internal/constant/ExaminerScoringConstants.java`
- Test: `ExaminerWorkflowCommandService*Test` (nếu có) hoặc test mới cho metadata

## Steps

1. Thêm `HOST_ADMIN_ROLE` vào `ExaminerScoringConstants` (hoặc dùng `Role.HOST_ADMIN.name()`).
2. `resolveIssue` dùng nó cho `actorRole`.
3. Test: audit của `resolveIssue` có `actorRole = HOST_ADMIN`.

## Quality/Testing State

- Test đơn vị mới.
