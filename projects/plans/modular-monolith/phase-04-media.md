# Phase 04 — Media

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Media upload/download, presigned URL, audio duration
**Nguồn:** `services/media` (21 file)
**Đích:** `com.pte.media`

---

## Mục tiêu

Đưa Media vào monolith nhưng vẫn giữ nguyên flow MinIO hiện tại:

```text
request upload → presigned PUT → complete upload → presigned GET
```

Kết thúc phase, `attempt` và `scoring` có thể gọi public `MediaService` trong app,
không cần `RestClient` hoặc endpoint nội bộ giữa các module.

---

## Design Constraints

- Giữ nguyên API path, response envelope, content-type allowlist và domain error
  của service cũ.
- Mọi media object phải có `tenantId` và `ownerPublicId`; mọi lookup theo public
  ID phải kiểm tra tenant.
- Chỉ `audio/wav` được dùng làm `audioPrompt`; duration WAV phải được đọc từ
  object nội bộ sau khi upload complete.
- Upload URL TTL là 15 phút; download URL bị giới hạn tối đa 24 giờ và chỉ cấp cho
  media đã `UPLOADED`.
- Storage key phải giữ tenant segment, ví dụ `audio/{tenantId}/{uuid}.wav`.
- MinIO dùng hai endpoint: internal endpoint để đọc object/duration và public
  endpoint để tạo presigned URL.
- Module khác chỉ gọi public API ở package root; repository, MinIO config và
  exception implementation nằm dưới `internal/`.
- Source media không có projection/event synchronization; không tạo outbox table.

---

## Việc cần làm

1. **Port domain và contract**
   - Port `MediaObject`, `MediaStatus`, request/response và các exception:
     invalid WAV, unsupported content type, not found, not uploaded, presign failed,
     already uploaded.
   - Dùng `shared.BaseEntity`, `CurrentUser`, `ApiResponse` và global exception
     handler của app.

2. **Tạo public service**
   - Tạo `com.pte.media.MediaService` làm cửa duy nhất cho module khác.
   - Expose các thao tác tương đương `requestUpload`, `completeUpload` và
     `presignGet`.
   - Giữ `CurrentUser` ở boundary user-facing; API nội bộ nhận tenant rõ ràng và
     không được tin tenant từ query nếu caller không phải trusted application call.

3. **Port storage adapter**
   - Port `MinioConfig`, bucket bootstrap, presigned PUT/GET và WAV reader vào
     `internal/config` hoặc `internal/storage`.
   - Khi complete audio prompt, đọc duration từ internal MinIO; lỗi SDK/IO/security
     phải được map về domain exception như source.

4. **Port controller**
   - Giữ `MediaController` cho API upload/complete.
   - Chỉ giữ `InternalMediaController` như compatibility adapter nếu còn client
     ngoài gọi trong giai đoạn dual-run; code trong app không gọi adapter này.
   - Kiểm tra lại context path `/api/media` khi gắn vào app/gateway.

5. **Flyway**
   - Viết `V5__media.sql` khớp entity và tên bảng `media_objects`.
   - Có index/unique constraint cho storage key và lookup owner/tenant.
   - Không tạo bảng outbox, processed event hoặc projection.

6. **Rà dependency**
   - Port test của service media sang app.
   - Xóa các client HTTP media khỏi code app nếu chúng chỉ phục vụ module đã port;
     chưa xóa client trong `services/` trước Phase 11.

---

## Tests to Write First

- Request upload với content type được phép/bị cấm.
- `audioPrompt=true` với WAV và non-WAV.
- Storage key luôn chứa tenant ID và UUID mới.
- Complete upload đúng owner, khác owner, upload lặp và object chưa tồn tại.
- WAV duration chính xác, WAV malformed, MinIO internal read lỗi.
- Presigned GET chặn khác tenant, media pending và TTL vượt 24 giờ.
- Modulith không cho module khác chạm repository/config nội bộ.

---

## Acceptance

- [ ] Upload → complete → presigned download chạy qua app.
- [ ] Audio prompt lưu đúng duration; non-audio prompt không đi qua WAV reader.
- [ ] Cross-tenant media lookup không làm lộ existence hoặc URL.
- [ ] `attempt`/`scoring` gọi `MediaService`, không gọi `MediaClient`.
- [ ] `V5__media.sql` chạy được trên database monolith trống.
- [ ] Không có artifact outbox/projection mới trong app.
- [ ] Test media nguồn và test app xanh.
- [ ] `ApplicationModules.verify()` pass.

---

## Quality and Testing State

Chưa thực thi. Sau khi code xong phải cập nhật số test, quality report và receipt
trước khi bắt đầu Phase 05.
