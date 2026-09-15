# Plan: Modular Monolith cho pte-api

**Spec:** [spec.md](spec.md)
**Branch:** `quang/refactor/backto-monolith` (repo `pte-api`, sạch tại `3bb9670`)
**Kế hoạch Phase 04–11:** [remaining-modules-refactor-plan.md](remaining-modules-refactor-plan.md)
**Mode:** Hard · **Test:** default
**Status:** In progress — **Phase 01–02 hoàn tất, đã qua quality gate (approved)**.
Phase 03 đã chi tiết, 04–11 viết trước khi thực thi từng phase (nguyên tắc #6).
Phase 01 và 02 chưa có commit — người dùng tự commit (không phải Cook).

---

## Nguyên tắc bất biến

Áp dụng cho **mọi** phase, không ngoại lệ:

1. **Kết thúc mỗi phase, repo phải build được và toàn bộ test xanh.** Không có phase
   nào được kết thúc ở trạng thái dở dang. Đây là hàng rào chống lại rủi ro số 1.
2. **Cây `services/` cũ không bị xoá cho đến Phase 10.** Monolith mọc song song bên
   cạnh microservice. Test của service cũ tiếp tục chạy, đóng vai trò lưới an toàn
   phát hiện hồi quy khi port.
3. **Port, không viết lại.** 639 file chứa nhiều xử lý biên đã được sửa qua thời gian
   (ví dụ `saveAndFlush` trước khi ghi outbox để lấy `createdAt`). Đọc và chuyển, chỉ
   viết lại khi logic đó tồn tại *chỉ vì* hệ thống bị tách.
4. **Mỗi phase là một commit riêng** với message conventional. Dễ quay lui từng bước.
5. **Không nới lỏng phân tách tenant.** Gộp service không được làm mất kiểm tra
   `tenantId` ở bất kỳ truy vấn nào.
6. **Viết file chi tiết của phase N+1 trong lúc thực thi phase N.** Không viết sẵn
   toàn bộ từ đầu (sẽ là bịa, vì chưa đọc code service đó), cũng không đợi đến sát
   giờ (dễ đi sai hướng). Đọc code service nguồn của phase sau ngay khi đang làm
   phase trước — luôn đi trước thực thi đúng một bước.

---

## Bản đồ phase

| # | Phase | Nguồn (số file) | Đích | Kết quả kiểm chứng được |
|---|---|---|---|---|
| 01 | Khung monolith | — | `app/`, `shared/` | App khởi động, `/actuator/health` xanh, Modulith verify pass |
| 02 | Identity | `pte-common` + `iam` (65) | `shared/`, `identity/` | Đăng nhập thật qua monolith, JWT phát ra hợp lệ |
| 03 | Tenancy + Enrollment | `admin` (149) | `tenancy/`, `enrollment/` | Danh sách student trả về bằng **một câu JOIN** |
| 04 | Media | `media` (21) | `media/` | Upload/tải audio qua MinIO |
| 05 | Itembank + Assessment | `authoring` (56) | `itembank/`, `assessment/` | CRUD câu hỏi + đề thi; snapshot gom còn **một** bản |
| 06 | Session | `scheduling` (89) | `session/` | Tạo và lên lịch được ca thi |
| 07 | Attempt ★ | `exam-delivery` (83) | `attempt/` | **Luồng thi đầu-cuối chạy được** — mốc demo được sớm nhất |
| 08 | Scoring | `scoring` (60) | `scoring/` | Nộp bài trả `202` < 300ms; worker chấm dần từ queue |
| 09 | Proctoring + Notification | `proctor` (44), `notification` (29) | 2 module | Ghi vi phạm, gửi email |
| 10 | Reporting | `reporting` (43) | `reporting/` | Báo cáo chạy bằng truy vấn trực tiếp, bỏ `AnswerProjection` |
| 11 | Cutover | `services/`, `gateway`, compose | — | `services/` bị xoá; compose 1 app + LB 2 bản sao; seed script |

★ = mốc quan trọng nhất về mặt trình bày.

---

## Lý do thứ tự này

Thứ tự **không** tự nghĩ ra mà dựng từ đồ thị lời gọi thật giữa các service hiện tại
(9 lớp `*Client` trong `services/*/client/`):

```
exam-delivery → authoring, media, scheduling
scoring       → media
scheduling    → authoring
proctor       → scheduling
reporting     → exam-delivery, scoring
admin         → iam
```

Sắp xếp topo cho ra thứ tự trong bảng trên. Trong monolith, các lời gọi HTTP này trở
thành lời gọi hàm — nhưng ràng buộc thứ tự vẫn nguyên: module bị gọi phải tồn tại
trước module gọi nó.

> **Đã sửa sau red-team review (2026-09-15):** bản đầu xếp `media` ở Phase 08 trong
> khi `attempt` (P06) và `scoring` (P07) đều gọi nó — phụ thuộc ngược chiều. `media`
> chỉ 21 file và không gọi ai, nên chuyển lên Phase 04. Tổng số phase 10 → 11.

**Hệ quả cần biết trước:** luồng thi đầu-cuối chỉ chạy được từ **Phase 07**. Nếu cần
demo sớm hơn thế, phải đảo sang chiến lược lát cắt dọc — chấp nhận port từng phần
nhiều service cùng lúc, đổi lại độ rối cao hơn nhiều. Khuyến nghị không đổi.

Phase 03 được đặt sớm có chủ đích: nó xoá đúng cơ chế projection đã gây ra bug
production sáng 2026-09-15, biến `/student-roster` thành một câu JOIN. Đây là bằng
chứng cụ thể sớm nhất cho thấy việc gộp có tác dụng thật.

---

## Design Constraints (toàn cục)

- **Java/Spring:** giữ nguyên phiên bản hiện tại. Migration này không đổi Spring Boot,
  không đổi JPA, không đổi thư viện.
- **Spring Modulith:** `spring-modulith-starter-core` + `spring-modulith-starter-test`.
  API công khai ở gốc package module, chi tiết nội bộ trong `internal/`.
- **Database:** một Postgres, **một schema**. Tên bảng giữ nguyên như hiện tại để giảm
  rủi ro khi port; đổi tên bảng không nằm trong phạm vi.
- **Flyway:** monolith dùng bộ migration **mới, đánh số lại từ V1**, sinh từ entity sau
  khi port. Không tái sử dụng migration của service cũ — chúng thuộc 4 database khác
  nhau và có version trùng nhau.
- **RabbitMQ:** chỉ dùng cho chấm điểm, email, xử lý media. Cấm dùng để đồng bộ dữ
  liệu giữa module — trong monolith đó là một lời gọi hàm.
- **Cấm mang theo:** `OutboxEntry`, `ProcessedEvent`, `EventIdempotencyGuard`, mọi
  `*Consumer` kiểu projection, `StudentRosterEntry`, `UserDirectoryEntry`,
  `AnswerProjection`, `ProjectionBackfill`, `StudentExportClient`,
  `InternalRebuildController`. Gặp file thuộc nhóm này khi port thì **bỏ**, không chuyển.

---

## Risks

| # | Rủi ro | Mức | Giảm thiểu |
|---|---|---|---|
| 1 | **Bỏ dở giữa chừng** → nửa microservice nửa monolith, tệ hơn cả hai | CAO | Nguyên tắc bất biến #1 + #2: mỗi phase build được, code cũ còn nguyên tới Phase 10. Bỏ dở ở bất kỳ phase nào vẫn còn hệ thống cũ chạy được. |
| 2 | **Đánh rơi xử lý biên** đã sửa qua thời gian | CAO | Nguyên tắc #3 (port không viết lại) + test service cũ vẫn chạy làm lưới an toàn. |
| 3 | **Mâu thuẫn tiến độ**: hạn 3 tháng nhưng "cần gấp" | TRUNG BÌNH | Phase 07 là mốc demo được. Nếu gấp, dừng sau 07–08 vẫn có sản phẩm trình bày được. |
| 4 | **Phân tách tenant bị nới lỏng** khi gộp | CAO | Nguyên tắc #5. Phase 03 và 10 phải rà lại toàn bộ truy vấn có `tenantId`. |
| 5 | **Hội đồng chưa biết việc đổi kiến trúc** | TRUNG BÌNH | Phi kỹ thuật. Trao đổi với giảng viên hướng dẫn trước, không đợi đến lúc bảo vệ. |
| 6 | **Modulith verify đỏ hàng loạt** ở phase giữa do module tham chiếu chéo | THẤP | Thứ tự phase bám chiều phụ thuộc nên tham chiếu luôn xuôi chiều. |
| 7 | **Frontend gãy** do đổi đường dẫn API | TRUNG BÌNH | FR-09: giữ nguyên hợp đồng API công khai. Phase 10 xử lý routing, không phải từng phase. |

---

## Rollback

Mỗi phase là một commit trên `quang/refactor/backto-monolith`. `main` không bị chạm.
Quay lui một phase = `git revert` commit đó. Bỏ toàn bộ migration = bỏ nhánh; prod
đang chạy microservice không bị ảnh hưởng vì Phase 11 (cutover) là bước cuối cùng.

---

## Quality and Testing State

| Phase | Quality gate | Testing |
|---|---|---|
| 01 | **approved** (0 blocking, 4 deviation đã duyệt) | test riêng của phase xanh (3/3); `ck:test --unit` sweep = skipped_by_user; full reactor 14/14 xanh; `docker compose up` **chưa chạy thật** (không có Docker daemon trong phiên) |
| 02 | **approved** (0 blocking, chạy 2 lần — lần 2 sau khi tổ chức lại package theo phản hồi người dùng) | test riêng của phase xanh (29/29 gồm cả Phase 01); `ck:test --unit` sweep = skipped_by_user; full reactor 14/14 xanh (2 lần); JWT login/restart end-to-end **chưa kiểm chứng thật** (không có Postgres/Docker) |
| 03 | **approved** (0 blocking, inline `ck:quality --gate`, receipt valid) | `app` 142/142 xanh; `services/admin` compile xanh |
| 04–11 | chưa đánh giá | chưa bắt đầu |

Chi tiết: [phase-01-khung-monolith.md](phase-01-khung-monolith.md#quality-and-testing-state),
[phase-02-identity.md](phase-02-identity.md#quality-and-testing-state),
[phase-03-tenancy-enrollment.md](phase-03-tenancy-enrollment.md#quality-and-testing-state).

`ck:cook` cập nhật bảng này sau mỗi phase.
