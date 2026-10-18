# Plan: Thương mại hoá tenant & định danh sinh viên

Status: 🟡 In progress — implementation for Phases 1–17 is recorded; release gate remains open because full regression and PostgreSQL migration evidence are not clean
Date: 2026-09-17
Mode: Hard
Test: default
Created by: Quang
Last reviewed: 2026-10-18 by Quang
Specs: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md)

## Overview

Chuyển nền tảng từ "admin onboard tenant thủ công, host tự soạn đề" sang **bán sỉ công cụ cho tổ chức**: trung tâm tự đăng ký → admin thẩm định → mua gói (PayOS hoặc mã kích hoạt) → tổ chức kỳ thi trong giới hạn gói, với đề do hệ thống sinh ngẫu nhiên từ template.

Kèm theo: gỡ ràng buộc email-unique-toàn-cục đang chặn một người học ở hai trung tâm, và chuyển import roster sang mô hình passthrough.

**Hai ADR phải làm cùng nhau, không nối tiếp** — `Tenant.code` của ADR-007 được đặt lúc duyệt đơn đăng ký của ADR-006.

## Cơ sở của đợt rà soát business rule

Đợt follow-up này dùng `ck-plan --hard` trên trạng thái source hiện tại, sau khi đối chiếu các report của Phase 12–13. Đây là kế hoạch đóng các khoảng trống còn lại, không phải xác nhận rằng các rule đã được enforce đầy đủ.

| Khoảng trống đã xác minh | Rủi ro kinh doanh | Phase xử lý |
|---|---|---|
| Tenant bị đình chỉ vẫn có đường tạo attempt mới và thao tác qua canonical draft/orchestration flow | Tenant bị đình chỉ vẫn phát sinh hoạt động mới | P14 |
| Enrollment/audience/proctor chưa dùng một hợp đồng identity active + đúng role + đúng tenant | Gán nhầm người, dữ liệu tenant sai, hoặc giao bài cho tài khoản không còn hợp lệ | P14 |
| Kiểm tra slot hiện tại là read-then-write; publish bỏ qua `skippedByConflict` | Hai kỳ thi trùng slot cùng được nhận, audience hiển thị `ENROLLED` giả | P15 |
| `mustChangePassword`, applied weight và suspension impact chưa đi hết tới trải nghiệm vận hành | Người dùng không bị buộc đổi mật khẩu; trung tâm/admin không giải thích được kết quả hoặc thiệt hại | P16 — resolved |
| Renewal expiry, re-suspend, suspended login và refund/revocation chưa có một quyết định thương mại nhất quán | Bán sai thời hạn, sai kỳ vọng khi đình chỉ hoặc tranh chấp thương mại | P17 — resolved |

Các đường dẫn source làm căn cứ chính gồm `ExamOrchestrationService`, `AttemptLifecycleService`, `EnrollmentService`, `IdentityService`, `SubscriptionActivationService`, auth contract của `pte-web` và `SuspendTenantModal`. Các implementation gap của P1/P2/P16/P17 đã được xử lý; phần còn mở là release evidence, không phải business decision.

## Phases

- [x] Phase 1: Nền tảng định danh — `Tenant.code`, `User.username`, chuyển login sang `findByUsername`, backfill toàn bộ user hiện có [quality: approved; testing: focused passed]
- [x] Phase 2: Đăng ký & thẩm định tổ chức — `TenantApplication`, giữ chỗ mã từ lúc nộp đơn, duyệt → tạo Tenant + user OWNER [quality: approved; testing: focused passed; PostgreSQL partial index pending]
- [x] Phase 3: Catalog gói & tham số nền tảng — `Plan` (EXAM_PACKAGE / STUDENT_CAPACITY), `PlatformSetting.freeStudentLimit` [quality: approved; testing: passed]
- [x] Phase 4: Lõi kích hoạt Subscription — `Subscription` + `licenseKey`, **một nơi duy nhất sinh Subscription**, snapshot cap từ Plan [quality: approved; testing: passed]
- [x] Phase 5: Mua gói qua PayOS — `Order` + `orderCode` sequence, tạo payment link, webhook verify chữ ký + idempotent [quality: approved; testing: passed]
- [x] Phase 6: Mã kích hoạt — `LicenseCode` phát lẻ, redeem atomic, `REVOKED` huỷ luôn Subscription [quality: approved; testing: passed]
- [x] Phase 7: Enforce hạn mức sinh viên — `Tenant.studentLimit` từ cột trang trí thành ràng buộc thật, kiểm theo lô [quality: approved; testing: passed]
- [x] Phase 8: Import roster passthrough — nhận file bất kỳ, sinh N tài khoản, xuất lại file + cột `account`/`password` [quality: approved; testing: passed]
- [x] Phase 9: Catalog template đề — `ExamTemplate` + `TemplateSection` (% điểm, Σ=100) + `TemplateSlot`, platform-owned [quality: approved; testing: passed]
- [x] Phase 10: Sinh đề từ template — random có seed, kiểm đủ câu trước khi sinh, rút đường soạn đề thủ công, kho đề chỉ còn SHARED [quality: approved; testing: passed]
- [x] Phase 11: Ràng buộc kỳ thi ↔ gói — C1–C4, exclusion constraint chống trùng khung giờ, đổi gói khi còn `SCHEDULED` [quality: approved; testing: passed]
- [x] Phase 12: Trùng slot sinh viên — phát hiện bằng một query, loại khỏi lô, thông báo tenant [quality: approved; testing: passed]
- [x] Phase 13: Điểm có trọng số & đình chỉ tenant — `Σ(điểm phần × %)`, breakdown `appliedWeight` trong report snapshot, `suspendedUntil` mặc định 0 [quality: approved; testing: passed]
- [x] Phase 14: Guardrail hoạt động tenant & eligibility identity — chặn đúng điểm bắt đầu, giữ nguyên attempt đang chạy, chuẩn hoá tenant/role/status/deleted checks [quality: approved; testing: passed]
- [x] Phase 15: Enrollment concurrency & publish reconciliation — serialize theo student, không ghi `ENROLLED` nếu không có enrollment thật [quality: approved; testing: passed]
- [x] Phase 16: Auth/report/suspension operator contract — first-login password, giải thích applied weight, preview đình chỉ đầy đủ và audit auto-reactivation [quality: approved; testing: focused passed]
- [x] Phase 17: Đóng chính sách thương mại & release gate — chốt renewal, suspended auth, re-suspend, refund/revocation và bằng chứng rollout [implementation complete; release gate open]

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

Follow-up sau P13 được tách để tránh một transaction/rule thay đổi che khuất rule khác:

```
P13 ──> P14 ──> P15
  ├───────────> P16
  └───────────> P17 (chỉ chốt rollout sau P14–P16)
```

P14 là dependency của P15 vì mọi enrollment phải đi qua identity eligibility và cùng tenant-activity policy. P16 có thể làm song song với P15. P17 là cổng bằng chứng phát hành, không được coi là hoàn tất chỉ vì test unit xanh.

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
- Flyway đang chạy (`flyway.enabled: true`, `ddl-auto: validate`, `V1..V13`) → **viết được SQL thủ công**: exclusion constraint, partial index, extension đều trong tầm.
- **Hệ thống chưa có dữ liệu thật** → P1 sửa thẳng `V2__identity.sql` và `V3__tenancy.sql` thay vì thêm migration mới; cả đội `docker compose down -v` một lần. Đây là **ngoại lệ duy nhất**; từ Phase 2 trở đi chỉ thêm `V15`, `V16`, … và không bao giờ sửa migration đã tồn tại nữa.

## Rủi ro

| Rủi ro | Phase | Xử lý |
|---|---|---|
| P1 đổi khoá đăng nhập | 1 | **Rủi ro thấp — hệ thống chưa có dữ liệu thật (chốt 2026-09-16)**, nên không cần backfill và không có user nào để mất. Vẫn test đăng nhập từng vai trò trước khi sang phase khác: rẻ, và là thứ duy nhất chứng minh không vai trò nào bị bỏ sót |
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
| Guard sai điểm làm hỏng resume/submit của attempt đang chạy | 14 | Tách `new attempt` khỏi `resume`; test ma trận 403/200 cho từng operation |
| Một audience member không còn là student active vẫn được publish/enroll | 14 | Identity facade kiểm tenant + role + `deleted=false` + `status=ACTIVE` ở mọi command boundary |
| Hai request enroll chéo session cùng nhận một student | 15 | Khoá row identity theo thứ tự `publicId` tăng dần trước conflict query và insert; bắt buộc Postgres concurrency test |
| Publish đánh dấu `ENROLLED` dù bulk enroll trả conflict | 15 | Reconcile từ `BulkEnrollResponse`; chỉ `enrolled`/`alreadyEnrolled` mới được đánh dấu enrolled |
| Preview đình chỉ bị stale hoặc chỉ hiển thị 5 gói | 16 | Digest/version confirmation, total count, plan label và hiển thị phần còn lại |
| Scheduled auto-reactivation không có actor/audit | 16 | System audit event chứa tenant, thời điểm hết hạn, lý do và idempotency |
| Thời hạn renewal khác ADR nhưng vẫn lọt qua test hiện tại | 17 | Chặn rollout ở decision gate; sửa ADR + acceptance test trước khi đổi code |

## Nợ kỹ thuật chạm phải (không giải trong plan này)

- **RLS vẫn chưa có.** Plan này thêm `subscription_id`, `license_key`, `tenant.code` — toàn cột tenant-scoped, và tất cả đều chỉ được ép ở tầng application. Mỗi phase làm chi phí bổ sung RLS sau này tăng lên. Xem [ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md)
- **Bulk import chạy đồng bộ.** P8 giữ nguyên tính chất này. Một trung tâm import 5.000 dòng vẫn ăn vào connection pool dùng chung với bài thi
- **`ApplicationModules.verify()` chưa có.** Plan này thêm module `billing` với phụ thuộc `billing → tenancy`, `session → billing`. Không có test nào chặn chiều ngược lại

## Quyết định đã chốt cho follow-up

- **Renewal expiry:** mỗi lần mua là một lane độc lập với `expiresAt = activationTime + durationDays`; không tự nối sau `latestExpiry`.
- **Suspended tenant:** vẫn cho login/refresh, đọc report và tiếp tục attempt đang chạy; chặn toàn bộ hoạt động mới và forward-moving activity.
- **All-conflict publish:** nếu có ít nhất một enrollment thành công hoặc đã tồn tại thì cho partial publish; nếu toàn bộ audience conflict thì giữ `READY` và trả `409` để admin xử lý.
- **Re-suspend:** request trên tenant đã `SUSPENDED` là idempotent no-op; đổi deadline cần command/policy riêng và impact preview mới.
- **Stale impact preview:** suspend confirmation dùng digest/version; dữ liệu stale trả `409` và yêu cầu xác nhận lại.
- **Impact duration:** hiển thị chính xác theo ngày + giờ, không làm tròn xuống làm thiếu thiệt hại.
- **Capacity/refund/revocation:** không tự giảm quota student-capacity khi revoke; refund/chargeback ngoài release này và phải trả machine code `unsupported` rõ ràng.
- **First-login scope:** mọi account có `mustChangePassword = true` đều bị chặn vào workspace cho tới khi đổi mật khẩu thành công; chỉ cho đổi mật khẩu hoặc logout.

Các quyết định trên là contract business; quality/testing state của P16–P17 đã được ghi nhận, nhưng release vẫn mở cho tới khi full regression và PostgreSQL evidence sạch.

## Test strategy

- **P1** là phase duy nhất có rủi ro làm sập đăng nhập → test đăng nhập cho **từng vai trò** (`STUDENT`, `HOST_ADMIN`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`) trước khi merge
- **P5, P6** là hai đường vào cùng một `activate()` → test rằng cả hai sinh ra Subscription **giống hệt nhau** về `expiresAt`, `licenseKey` format, cap đã snapshot
- **P11** ràng buộc C1–C4 → test từng điều kiện riêng, cộng một test đồng thời cho exclusion constraint
- **P12** → test với lô 500 sinh viên, đếm số query thực tế
- **P14** → HTTP contract matrix cho suspended/active tenant; resume attempt, submit, heartbeat, report read vẫn pass; cross-tenant/nonstudent/deleted/suspended identity đều bị từ chối ở đúng command boundary
- **P15** → Postgres test thật cho hai session overlap cùng student, acquisition order không deadlock, publish không sinh false `ENROLLED`, retry/idempotency và query count batch
- **P16** → typecheck/API contract cho tenant-web và vendor-web; first-login redirect/change-password; report applied weight; preview đầy đủ/stale digest; system audit auto-reactivation
- **P17** → ADR/decision checklist, renewal expiry test theo policy đã chọn, suspended auth matrix, và release evidence cho các test bị skip hoặc baseline `ModuleStructureTest`
- Coverage tối thiểu 80% theo chuẩn repo

## Evidence recorded on 2026-10-18

- P1/P2/P4/P16/P17 API focused suite: **70 tests passed**, 0 failures/errors/skips. The suite covers identity username lookup, application approval/rejection, renewal expiry, suspension impact confirmation, suspended login selection, HTTP request shape, stale digest rejection, and scheduled system audit.
- Web typechecks: `@pte/api-client`, `@pte/ui`, `tenant-web`, and `vendor-web` all passed. Web tests recorded for this implementation remain green: 677 API-client, 536 tenant-web, and 68 vendor-web tests.
- Web lint: tenant-web passed; vendor-web passed with two pre-existing `next/image` warnings in question-bank components. `@pte/api-client` and `@pte/ui` do not expose a lint script.
- Full API regression: 2,156 tests, 5 failures, 2 errors, and 60 skipped. The blocking baseline includes `ModuleStructureTest`, notification listener regressions, and a UUID-order assertion in `UserRepositoryTest`; no production or deployment claim is made.
- PostgreSQL boundary: the Phase 2 unique partial index and skipped integration suites still need a real PostgreSQL run. Phase 17 therefore remains an implementation-complete but rollout-blocked gate.

Reports: [quality](quality/) · [tests](tests/)

## Release boundary

Không tuyên bố commercialization rollout-ready khi P14 chưa chứng minh được “block new, allow in-progress”, P15 chưa có concurrency evidence trên Postgres, hoặc P17 còn release evidence chưa đạt/không có owner. Full regression hiện vẫn có baseline `ModuleStructureTest` error; report rollout phải tách rõ lỗi baseline đó khỏi bằng chứng của các phase mới.
