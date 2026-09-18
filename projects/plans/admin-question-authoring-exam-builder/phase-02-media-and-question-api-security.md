# Phase 2: Cloudinary media authoring contract and API security

## Goal

Nối đúng upload audio/image qua Cloudinary signed upload flow và làm cho question API kiểm tra ownership, media status, MIME và role trước khi lưu/submit/approve.

## Steps

1. Thay implementation MinIO trong `MediaObject`/`PresignService` bằng Cloudinary integration; giữ media API abstraction để question module không phụ thuộc SDK.
2. Tạo signed upload params server-side gồm timestamp, folder, resource type, allowed format và max size; tuyệt đối không gửi `api_secret` cho browser.
3. Dùng Cloudinary `image` cho image và resource type phù hợp cho audio; lưu `publicId`, `resourceType`, `secureUrl`, `format`, `bytes`, `duration`, `assetId`/checksum.
4. Browser upload trực tiếp lên Cloudinary, sau đó gọi complete/confirm để backend kiểm tra asset qua Cloudinary API trước khi đánh dấu `UPLOADED`.
5. Thêm authenticated author preview endpoint dùng secure URL hoặc signed delivery URL có TTL; không trả storage key nội bộ.
6. Đảm bảo complete chỉ do owner gọi được; asset đã complete không overwrite/complete lần hai.
7. Khi create/update/submit/approve question, kiểm tra media đúng scope, đúng asset kind, đúng MIME và `UPLOADED`.
8. Bổ sung reconciliation/cleanup policy cho upload mồ côi trên Cloudinary; tối thiểu phải có log/report và TTL rõ ràng.

## Design Constraints

- Browser upload trực tiếp Cloudinary; API không proxy binary lớn.
- Không expose public unauthenticated media URL.
- Audio prompt PTE hiện chỉ WAV; mở rộng định dạng chỉ sau khi chốt product và scoring support.
- Media được snapshot sử dụng không được xóa hoặc ghi đè; Cloudinary deletion phải kiểm tra reference trước.

## Files / ownership

- `pte-api/.../media/domain/MediaObject.java`
- `pte-api/.../media/internal/controller/MediaController.java`
- `pte-api/.../media/internal/controller/InternalMediaController.java`
- `pte-api/.../media/internal/service/CloudinaryMediaService.java` hoặc adapter tương đương
- Cloudinary configuration/properties và signed-upload DTOs
- media request/response DTOs, repository, constants
- `pte-api/.../resources/db/migration/V{next}__platform_media_scope.sql`
- API client media request/types mới; loại bỏ adapter `/assets/upload` cũ sau khi không còn caller

## Quality and Testing State

- Chưa chạy cho phase này.
- Theo quyết định hiện tại, không bắt buộc test/quality audit ở từng phase. Cloudinary contract, MIME/size, ownership và pending-media cases được ghi lại làm checklist tùy chọn.
- Preflight: backend compile passed at final gate; quality audit and tests skipped by user decision (`quality: skipped_by_user; decision: user_confirmed_skip`).

## Acceptance Criteria

- Platform Author upload được audio/image và nhận media public ID.
- Upload chưa được Cloudinary confirm không thể submit/approve question.
- Author preview được media qua URL TTL ngắn hạn.
- Host không lấy được media authoring platform nếu không có quyền.
- Media đã được snapshot không bị xóa/ghi đè bởi author flow.
