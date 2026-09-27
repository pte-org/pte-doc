# Phase 6: Optional release verification

## Goal

Ghi nhận checklist release tùy chọn cho authoring đến immutable snapshot. Phase này không phải test/quality gate bắt buộc theo quyết định hiện tại.

## Steps

1. Nếu cần release smoke, kiểm tra: create DRAFT → upload/confirm Cloudinary media → submit → Admin approve → create revision → archive/restore.
2. Kiểm tra blueprint: template default order → filter → select/reorder → Author submit → Admin approve → snapshot.
3. Kiểm tra old snapshot không đổi sau source revision publish/archive.
4. Kiểm tra shortage, role matrix và migration trên clean/existing data.
5. Chỉ chạy Playwright, integration test hoặc `ck:quality` khi được yêu cầu bổ sung.

## Design Constraints

- Không claim automated verification đã pass nếu chưa chạy.
- Nếu chạy smoke, không dùng fixture để bypass role/Cloudinary ownership.
- Nếu chạy snapshot check, kiểm tra content chứ không chỉ ID/status.

## Files / ownership

- backend test packages under `pte-api/app/src/test/...`
- web unit/component tests under corresponding `pte-web` feature/package
- Playwright specs under repository test convention
- migration verification scripts/fixtures if repo already has them
- quality/test receipts under this plan directory

## Quality and Testing State

- `skipped_by_user`: không bắt buộc test/E2E/quality audit ở phase này.
- Đây là checklist tùy chọn, không dùng làm điều kiện chặn implementation.

## Acceptance Criteria

- Các bước release smoke được ghi nhận nếu team lựa chọn chạy.
- Cloudinary, approval boundary và snapshot immutability được xác nhận thủ công nếu cần.
- Không còn placeholder/no-op mutation trong hai feature.
