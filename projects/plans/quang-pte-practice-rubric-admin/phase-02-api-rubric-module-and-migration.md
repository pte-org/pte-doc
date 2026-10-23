# Phase 02: backend rubric module, migration và workflow

**Status:** implemented and verified  
**Dependency:** Phase 01  
**Output:** API backend quản lý rubric, public read facade và dữ liệu versioned/audited.

## Mục tiêu

Tạo module `com.pte.rubric` theo cấu trúc Spring Modulith hiện tại. Module sở hữu rubric policy, revision, criteria, levels, anchors, references, readiness và lifecycle. Practice/Item Bank chỉ gọi public facade.

## Công việc

1. Kiểm tra migration head thực tế ngay trước khi code; không hard-code số tiếp theo từ plan.
2. Tạo migration additive cho rubric tables, child tables, binding, indexes và immutable hash metadata.
3. Thêm nullable provenance columns vào `practice_session_items` và `practice_explanations` để dữ liệu cũ vẫn đọc được.
4. Tạo entities/repositories/mappers/DTOs và module `package-info.java`; cập nhật `ModuleStructureTest` đúng module boundary.
5. Implement create, get, list, clone, replace document, submit approval, reject, publish, retire, readiness và diff.
6. Implement validation service: duplicate criteria, missing levels, unsupported task/evidence, missing provenance, invalid Personal Introduction, runtime mismatch và missing required reference.
7. Implement ownership/self-review checks trong service; controller chỉ là lớp gate đầu tiên.
8. Dùng lock/expected version cho revision number và publish race; map unique conflict thành error `409` ổn định.
9. Audit bằng `AuditLogService` cho success và failure; message/code thuộc `RubricConstants.java`.
10. Expose public facade `resolvePublishedForTask` và `resolvePinned`; không expose repository nội bộ cho module khác.

## Common/shared bắt buộc

- Response dùng `ApiResponse<T>` và global exception mapping theo `docs/API_RESPONSE_SETUP.md`/`docs/COMMON_EXCEPTION_SETUP.md`.
- Auth dùng `CurrentUserContext`, role constants và `SecurityPolicy`; không tự parse token trong rubric module.
- Audit dùng `AuditLogService`; không tạo audit logger riêng.
- Dùng module public facade khi Practice hoặc Item Bank cần rubric; không import `rubric.internal`.
- Error code/message mới đặt trong `RubricConstants.java` theo API standards.

## Design Constraints

- Lifecycle chính: `DRAFT → PENDING_APPROVAL → PUBLISHED → RETIRED`; reject đưa về `DRAFT`.
- Chỉ draft được sửa; published/retired immutable.
- Academic Manager không tự publish bản do mình author; Platform Admin override cần reason bắt buộc.
- Tối đa một published revision cho mỗi logical rubric key/channel.
- Không ghi đầy đủ rubric content hoặc Student response vào audit summary.
- Migration forward-only, tương thích rolling deployment; không rewrite session/explanation cũ.

## Quality and Testing State

- Quality: **APPROVED** by the independent review; final phase completion remains subject to the `--hard` confirmation gate.
- Testing: migration, validator, lifecycle, ownership/self-review, module-boundary and binding coverage is present; full backend regression passes.
- Required tests: migration parser/schema, validator unit tests, lifecycle service tests, ownership/self-review tests, optimistic concurrency, partial unique publish constraint, audit success/failure, controller error envelope và `ModuleStructureTest`.
- TDD gate: transition/authorization/evidence requirements were covered by tests before the implementation was accepted.
