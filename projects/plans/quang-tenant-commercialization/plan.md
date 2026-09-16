# Plan: Thương mại hoá tenant & định danh sinh viên

Status: 🔵 Not started
Date: 2026-09-16
Mode: Hard
Created by: Quang
Specs: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md)

## Overview

Chuyển nền tảng từ "admin onboard tenant thủ công, host tự soạn đề" sang **bán sỉ công cụ cho tổ chức**: trung tâm tự đăng ký → admin thẩm định → mua gói (PayOS hoặc mã kích hoạt) → tổ chức kỳ thi trong giới hạn gói, với đề do hệ thống sinh ngẫu nhiên từ template.

Kèm theo: gỡ ràng buộc email-unique-toàn-cục đang chặn một người học ở hai trung tâm, và chuyển import roster sang mô hình passthrough.

**Hai ADR phải làm cùng nhau, không nối tiếp** — `Tenant.code` của ADR-007 được đặt lúc duyệt đơn đăng ký của ADR-006.

## Phases

- [ ] Phase 1: Nền tảng định danh — `Tenant.code`, `User.username`, chuyển login sang `findByUsername`, backfill toàn bộ user hiện có
- [ ] Phase 2: Đăng ký & thẩm định tổ chức — `TenantApplication`, giữ chỗ mã từ lúc nộp đơn, duyệt → tạo Tenant + user OWNER
- [ ] Phase 3: Catalog gói & tham số nền tảng — `Plan` (EXAM_PACKAGE / STUDENT_CAPACITY), `PlatformSetting.freeStudentLimit`
- [ ] Phase 4: Lõi kích hoạt Subscription — `Subscription` + `licenseKey`, **một nơi duy nhất sinh Subscription**, snapshot cap từ Plan
- [ ] Phase 5: Mua gói qua PayOS — `Order` + `orderCode` sequence, tạo payment link, webhook verify chữ ký + idempotent
- [ ] Phase 6: Mã kích hoạt — `LicenseCode` phát lẻ, redeem atomic, `REVOKED` huỷ luôn Subscription
- [ ] Phase 7: Enforce hạn mức sinh viên — `Tenant.studentLimit` từ cột trang trí thành ràng buộc thật, kiểm theo lô
- [ ] Phase 8: Import roster passthrough — nhận file bất kỳ, sinh N tài khoản, xuất lại file + cột `account`/`password`
- [ ] Phase 9: Catalog template đề — `ExamTemplate` + `TemplateSection` (% điểm, Σ=100) + `TemplateSlot`, platform-owned
- [ ] Phase 10: Sinh đề từ template — random có seed, kiểm đủ câu trước khi sinh, rút đường soạn đề thủ công, kho đề chỉ còn SHARED
- [ ] Phase 11: Ràng buộc kỳ thi ↔ gói — C1–C4, exclusion constraint chống trùng khung giờ, đổi gói khi còn `SCHEDULED`
- [ ] Phase 12: Trùng slot sinh viên — phát hiện bằng một query, loại khỏi lô, thông báo tenant
- [ ] Phase 13: Điểm có trọng số & đình chỉ tenant — `Σ(điểm phần × %)`, `suspendedUntil` mặc định 0

## Thứ tự và phụ thuộc

```
P1 ──┬─> P2 ──> P3 ──> P4 ──┬─> P5 (PayOS)
     │                       └─> P6 (mã kích hoạt)
     └─> P7 ──> P8 (import roster)

P9 ──> P10        (độc lập với nhánh billing, làm song song được)

P4 + P10 ──> P11 ──> P12 ──> P13
```

**P1 chặn tất cả** — nó đụng vào login. Không phase nào khác bắt đầu trước khi P1 xanh.

**P9/P10 độc lập với P2–P8** — nếu làm hai người thì đây là đường cắt.

**P11 cần cả hai nhánh** — `ExamSession` phải có `subscriptionId` (từ P4) và snapshot sinh từ template (từ P10).

## Quyết định đã chốt (không mở lại trong lúc code)

| | |
|---|---|
| Mô hình gói | Multi-instance — mỗi lần mua = một `Subscription` độc lập = một "làn". Không có thao tác nâng gói |
| Hai đường mua | PayOS trực tiếp **và** mã kích hoạt Admin phát. Hội tụ vào một `activate()` |
| Bán mã theo lô | **Không làm** |
| Hoàn tiền | **Không làm.** Chỉ Admin thu hồi mã mới huỷ được Subscription |
| Đình chỉ tenant | Đồng hồ gói **không dừng**. Mặc định `suspendedUntil = 0` = gỡ thủ công |
| Kho đề | Chỉ còn SHARED. `Visibility.PRIVATE` bị rút (đã kiểm: **không có row nào** trong DB) |
| Template đề | Chỉ Admin nền tảng tạo |
| `Tenant.code` | Tổ chức tự chọn lúc nộp đơn, hệ thống kiểm unique, **bất biến sau khi duyệt** |
| Định danh sinh viên | `{tenant.code}.{random}`. Mã **ngẫu nhiên**, không sinh từ dữ liệu file |
| Chống trùng roster | **Không có.** Trách nhiệm thuộc trung tâm |
| Sinh viên chuyển trung tâm | Không có tính liên tục — tài khoản mới hoàn toàn |
| Phạm vi trùng slot | Trong cùng tenant (theo cấu trúc — `User.tenantId` là scalar) |

## Dependencies

**Có sẵn, tái dùng:**
- `tenancy.QuotaTransaction` — ledger append-only, dùng luôn cho gói mở rộng sinh viên (P3/P4), **không tạo bảng mới**
- `identity.PasswordGenerator`, `UserBulkCreateWriter` — nền cho P8
- `itembank.Visibility` — đã có SHARED/PRIVATE, P10 chỉ rút PRIVATE
- Pattern `findWithLockByPublicIdAndTenantId` trong `SessionLifecycleService` — dùng cho khoá đổi gói ở P11
- Quy ước 404-không-403 cho tài nguyên ngoài tenant — áp dụng toàn bộ endpoint mới

**Phải thêm:**
- Thư viện đọc/ghi `.xlsx` (Apache POI hoặc tương đương) — P8
- PayOS REST client tự viết — **chưa có SDK Java chính thức** (chỉ Node/PHP/Python/Go), phải gọi REST trực tiếp và tự implement phần ký. **Thuật toán ký phải đối chiếu docs khi làm, không viết theo trí nhớ** — P5
- Postgres extension `btree_gist` — P11

**Hạ tầng đã xác minh:**
- Flyway đang chạy (`flyway.enabled: true`, `ddl-auto: validate`, `V1..V13`) → **viết được SQL thủ công**: exclusion constraint, partial index, extension đều trong tầm. Migration mới bắt đầu từ `V14`.

## Rủi ro

| Rủi ro | Phase | Xử lý |
|---|---|---|
| **P1 làm hỏng đăng nhập của toàn bộ user hiện có** | 1 | Backfill `username = email` cho **mọi** user kể cả sinh viên cũ. Không sinh username mới cho sinh viên cũ — làm vậy là đá họ ra khỏi hệ thống. Test đăng nhập cho từng vai trò trước khi sang phase khác |
| Hai đơn đăng ký cùng xin một `Tenant.code` | 2 | Giữ chỗ ngay khi tạo `TenantApplication`, không phải lúc duyệt. Đơn bị từ chối thì trả mã |
| Webhook PayOS xử lý hai lần → hai Subscription | 5 | Dedup theo `orderCode`, và `activate()` là nơi duy nhất sinh Subscription |
| Hai request redeem cùng một mã | 6 | `UPDATE ... WHERE code = ? AND status = 'ISSUED'` rồi kiểm affected rows. **Không** đọc-rồi-ghi |
| Mã kích hoạt bị brute-force | 6 | Sinh bằng nguồn ngẫu nhiên mật mã, đủ dài; rate-limit endpoint redeem (`RateLimitFilter` đã có) |
| File roster xuất ra chứa mật khẩu chữ thường của cả trung tâm | 8 | Tải một lần, không lưu file trên server, buộc đổi mật khẩu lần đăng nhập đầu |
| Đề phát ra thiếu câu vì kho không đủ | 10 | Kiểm đủ **trước khi** sinh, thiếu thì 422 kèm tên task type. Không bao giờ phát đề rồi báo sau |
| Hai request tạo kỳ thi đồng thời cùng làn, trùng giờ | 11 | Exclusion constraint ở DB, không dựa vào lock ở tầng app |
| Deadlock khi hai request đổi gói chéo nhau (A→B, B→A) | 11 | Luôn khoá `Subscription` theo thứ tự `publicId` tăng dần, **không** theo thứ tự cũ-rồi-mới |
| Enroll 500 sinh viên sinh 500 query kiểm trùng slot | 12 | Một query `IN (:ids)` + so khoảng thời gian, diff trong bộ nhớ |
| Rút `Visibility.PRIVATE` làm Hibernate nổ lúc đọc | 10 | Đã kiểm: không có row `PRIVATE`. Vẫn rút theo thứ tự: bỏ đường ghi trước, rút enum sau |

## Nợ kỹ thuật chạm phải (không giải trong plan này)

- **RLS vẫn chưa có.** Plan này thêm `subscription_id`, `license_key`, `tenant.code` — toàn cột tenant-scoped, và tất cả đều chỉ được ép ở tầng application. Mỗi phase làm chi phí bổ sung RLS sau này tăng lên. Xem [ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md)
- **Bulk import chạy đồng bộ.** P8 giữ nguyên tính chất này. Một trung tâm import 5.000 dòng vẫn ăn vào connection pool dùng chung với bài thi
- **`ApplicationModules.verify()` chưa có.** Plan này thêm module `billing` với phụ thuộc `billing → tenancy`, `session → billing`. Không có test nào chặn chiều ngược lại

## Câu hỏi còn mở (tham số, không chặn code)

- Tỷ lệ hoàn tiền khi gói đã dùng — chính sách kinh doanh, và hoàn tiền chưa làm ở plan này
- Thời hạn đình chỉ mặc định trong `PlatformSetting` — mặc định 0 (gỡ thủ công), Admin đặt số khác được

## Test strategy

- **P1** là phase duy nhất có rủi ro làm sập đăng nhập → test đăng nhập cho **từng vai trò** (`STUDENT`, `HOST_ADMIN`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`) trước khi merge
- **P5, P6** là hai đường vào cùng một `activate()` → test rằng cả hai sinh ra Subscription **giống hệt nhau** về `expiresAt`, `licenseKey` format, cap đã snapshot
- **P11** ràng buộc C1–C4 → test từng điều kiện riêng, cộng một test đồng thời cho exclusion constraint
- **P12** → test với lô 500 sinh viên, đếm số query thực tế
- Coverage tối thiểu 80% theo chuẩn repo
