# ADR-006: Thương mại hoá tenant — Billing bounded context & Exam Template

**Date:** 2026-09-16
**Status:** Accepted
**Context:** Nghiệp vụ mới chốt với giáo viên hướng dẫn, thay đổi đáng kể so với thiết kế ban đầu. Nền tảng chuyển từ "admin onboard tenant thủ công, host tự soạn đề" sang **bán sỉ công cụ cho tổ chức**: trung tâm tự đăng ký → admin thẩm định → mua gói (trực tiếp qua cổng thanh toán hoặc bằng mã kích hoạt) → tổ chức kỳ thi trong giới hạn gói.

> **Bối cảnh kiến trúc:** ADR-001..005 mô tả 10 microservice. `pte-api` đã collapse về **Spring Modulith monolith** (commit `1d103c2`, `eb1a38d`), mỗi bounded context là một `@ApplicationModule` dưới `com.pte.*`. ADR này viết theo hiện trạng monolith; "service" trong ADR cũ đọc là "module".

---

## Decision

Thêm bounded context **`billing`**, chuyển `assessment` từ mô hình *soạn đề thủ công* sang *sinh đề từ template*, và biến `Tenant.studentLimit` từ cột trang trí thành ràng buộc được enforce.

---

## Nguyên tắc cứng (bất biến của nghiệp vụ thương mại)

1. **Nền tảng bán sỉ, không bán lẻ.** Khách hàng duy nhất là tổ chức. **Sinh viên không bao giờ là bên thanh toán** — không có luồng thanh toán nào hướng tới student, không có gói cá nhân, tài khoản student chỉ do tenant tạo. Mọi đề xuất tính năng chạm vào ví của người dùng cuối đều vi phạm bất biến này.
2. **Tenant không tồn tại trước khi được duyệt.** Đơn đăng ký (`TenantApplication`) và Tenant là hai entity khác nhau ở hai module khác nhau. Không có trạng thái `Tenant.PENDING`.
3. **Subscription là bản sao đông cứng của Plan tại thời điểm kích hoạt.** Admin sửa Plan không bao giờ làm thay đổi hợp đồng tenant đã mua.
4. **Subscription chỉ được sinh ra ở đúng một chỗ trong code.** Hai đường mua (thanh toán trực tiếp / redeem mã) hội tụ vào cùng một thao tác kích hoạt. Hai đường vào, một nơi ghi.
5. **Webhook là nguồn sự thật của thanh toán, không phải returnUrl.** Người dùng đóng tab sau khi trả tiền là trường hợp bình thường, không phải lỗi.
6. **Mỗi lần mua gói thi = một license độc lập ("làn").** Hai làn khác nhau chạy song song được; trong cùng một làn thì không.
7. **Đề thi do hệ thống sinh, tenant không chạm vào câu hỏi.** Tenant chọn template, hệ thống random — tenant không có đường nào nhìn thấy nội dung đề trước giờ thi.
8. **Ràng buộc gói được kiểm tại thời điểm ghi, không phải lúc đọc.** Tạo kỳ thi / thêm sinh viên là hai điểm chặn; không có job quét hậu kiểm.

---

## 1. Bounded context mới: `billing`

**Package:** `com.pte.billing` · **Cửa ra ngoài:** `BillingService`

| Entity | Sở hữu | Ghi chú |
|---|---|---|
| `TenantApplication` | Đơn đăng ký tổ chức | `PENDING / APPROVED / REJECTED`, `reviewedBy`, `reviewedAt`, `rejectReason`. Approve → gọi `TenancyService` tạo Tenant + user OWNER |
| `Plan` | Catalog gói do Admin tạo | `type`, giá, thời hạn, cap. `DRAFT / ACTIVE / ARCHIVED` — archive không ảnh hưởng Subscription đã bán |
| `Subscription` | Một lần mua gói thi | `licenseKey`, `startsAt`, `expiresAt`, **`maxStudentsPerSession` copy từ Plan** |
| `LicenseCode` | Mã kích hoạt Admin phát hành | `code`, `planId`, `ISSUED / REDEEMED / REVOKED / EXPIRED`, `issuedBy`, `redeemedByTenantId`, `redeemedAt`, `codeExpiresAt` |
| `Order` | Đơn hàng PayOS | `orderCode` (long, sequence riêng), `amount`, trạng thái |
| `PaymentTransaction` | Log webhook PayOS | Bất biến, append-only. Dedup theo `orderCode` |
| `PlatformSetting` | Tham số thương mại toàn hệ thống | `freeStudentLimit` — Admin sửa được, áp dụng cho tenant tạo mới |

### Hai họ sản phẩm, hai cơ chế khác nhau

| | `EXAM_PACKAGE` | `STUDENT_CAPACITY` |
|---|---|---|
| Vòng đời | Có hạn (`durationDays`) | **Vĩnh viễn** |
| Tác dụng | Sinh một `Subscription` = một làn thi | Cộng vào `Tenant.studentLimit` |
| Ghi ở đâu | `billing.Subscription` | `tenancy.QuotaTransaction` (`GRANTED`) — **ledger đã có sẵn, không thêm bảng** |
| Cộng dồn | Mỗi lần mua = làn mới, độc lập | Cộng dồn tuyến tính |

Hai họ này **hoàn toàn tách biệt**: hết hạn gói thi không làm mất chỗ sinh viên đã mua, và ngược lại.

### Hướng phụ thuộc

```
billing ──▶ tenancy      (tạo Tenant khi duyệt đơn, grant quota khi mua capacity)
billing ──▶ identity     (tạo user OWNER cho tenant mới)
session ──▶ billing      (đọc Subscription để validate khi tạo kỳ thi / enroll)
```

Không có chiều ngược lại. `tenancy` không biết `billing` tồn tại — nó vẫn chỉ là nơi giữ Tenant và ledger quota.

---

## 2. Subscription là license instance, không phải thuê bao

**Quyết định:** chọn mô hình *multi-instance* (mỗi lần mua = một `Subscription` row độc lập), **không** chọn mô hình thuê bao-một-tier như các SaaS cá nhân.

**Lý do:** nghiệp vụ yêu cầu tenant giữ gói A và gói B active cùng lúc, mỗi gói có cap sinh viên riêng, và kỳ thi của hai gói được phép trùng khung giờ. Mô hình một-subscription-nâng-tier chỉ cho một gói active tại một thời điểm → quy tắc này không biểu diễn được. Đây không phải sản phẩm thuê bao mà là **bán suất tổ chức thi** — gần với license theo đợt hơn.

**Không có thao tác "nâng gói".** Cần thêm năng lực thì mua thêm gói. Rủi ro tenant lách luật bằng cách mua nhiều gói nhỏ thay vì một gói lớn là **bài toán định giá, không phải bài toán kỹ thuật** — Admin đặt giá gói lớn rẻ hơn tổng các gói nhỏ tương đương là tự khắc hết.

### `licenseKey` — định danh nghiệp vụ của một làn

Mỗi `Subscription` mang một `licenseKey` sinh lúc kích hoạt, unique toàn hệ thống, dạng đọc được (ví dụ `PTE-A-2026-7QK4M2`). Nó được **denormalize xuống `ExamSession` và `Enrollment`**.

Lý do không chỉ dùng `subscriptionId` (UUID):

1. Tenant nhìn thấy và trích dẫn được khi cần hỗ trợ / đối soát hoá đơn. Mã do Admin phát hành cũng là thứ tenant cầm trên tay khi mua qua đại lý.
2. Bất biến theo vòng đời: không đổi khi Subscription đổi trạng thái.
3. Trả lời trực tiếp câu hỏi đối soát *"license này đã phục vụ bao nhiêu lượt sinh viên"* mà không join.

**Ghi rõ để không tự lừa mình:** cột `licenseKey` trên `Enrollment` là **denormalize cho tiện đối soát, không phải yêu cầu về tính đúng đắn.** Cap sinh viên là cap **mỗi kỳ thi**, nên việc kiểm cap chỉ cần `session_id` — không cần key. Gói không giới hạn tổng lượt (xem §1), nên cũng không có bộ đếm nào chạy trên đường enforce cần tới cột này. Ai bỏ cột này đi thì hệ thống vẫn chạy đúng; chỉ có truy vấn đối soát mức license phải join thêm một bảng.

### Đổi gói của một kỳ thi — cho phép, có điều kiện

Tenant chọn nhầm làn là chuyện bình thường, không phải edge case: gói A sắp hết hạn trong khi đáng ra phải dùng gói B. Cấm đổi nghĩa là bắt tenant chịu hậu quả của một cú click.

**Lock point: `status == SCHEDULED`.** Đổi được khi kỳ thi chưa mở, đông cứng từ lúc `OPEN`. Đây **đúng lock point đã tồn tại** trong `SessionLifecycleService.patchPolicy()` (`PolicyLockedException`), không phải quy ước mới — và đúng về nghiệp vụ: chưa mở thì chưa có attempt nào, không có gì để hỏng.

**Không dùng "xoá rồi tạo lại".** Nó tệ hơn đổi ở cả ba mặt: mất toàn bộ enrollment (tenant phải nhập lại 500 sinh viên), hở khung giờ giữa lúc xoá và tạo lại nên một kỳ thi khác cùng làn có thể chen vào chiếm mất slot theo C4, và audit trail đứt đoạn vì record mới không còn liên hệ với record cũ.

Ba chi phí thật của thao tác đổi — không phải drift dữ liệu:

1. **Chạy lại toàn bộ C1–C4 với gói mới.** Riêng C3 phải kiểm **số sinh viên đã enroll thực tế**, không kiểm `capacity` khai báo — gói mới có thể có cap nhỏ hơn số người đã vào.
2. **Cascade `licenseKey` xuống mọi hàng `Enrollment`** của kỳ thi, trong cùng transaction.
3. **Khoá hai hàng `Subscription` cùng lúc → nguy cơ deadlock.** Hai request đổi chéo nhau (A→B và B→A) khoá ngược chiều là deadlock kinh điển. Luôn khoá theo thứ tự `publicId` tăng dần, **không** theo thứ tự cũ-rồi-mới.

---

## 3. Ràng buộc kỳ thi

`ExamSession` thêm `subscriptionId` + `licenseKey` (bắt buộc; đổi được khi còn `SCHEDULED`, xem §2). Bốn điều kiện kiểm tại `SessionLifecycleService.create()` — và chạy lại nguyên vẹn mỗi lần đổi gói:

| # | Điều kiện | Phản hồi khi vi phạm |
|---|---|---|
| C1 | Subscription `ACTIVE` và thuộc tenant của caller | 404 (không phải 403 — giữ nguyên quy ước toàn codebase) |
| C2 | `[opensAt, closesAt] ⊆ [subscription.startsAt, expiresAt]` | 422 |
| C3 | `capacity != null && capacity <= subscription.maxStudentsPerSession` | 422 |
| C4 | Không kỳ thi nào **cùng `subscriptionId`** có khung giờ giao nhau | 409 |

C3 biến `capacity` từ optional (`null = unlimited`) thành **bắt buộc**. "Unlimited" không còn nghĩa khi mọi kỳ thi đều thuộc một gói có cap.

### C4 phải chống được race, không chỉ chống được người dùng cẩn thận

Check-then-insert ở tầng application không đủ: hai request tạo kỳ thi đồng thời trên cùng subscription đều đọc thấy "không trùng" rồi cùng insert.

**Chọn: Postgres exclusion constraint.** Project đang chạy Flyway (`flyway.enabled: true`, `ddl-auto: validate`, migration `V1..V13` trong `db/migration/`), nên viết được SQL thủ công:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE exam_sessions ADD CONSTRAINT no_overlap_per_subscription
  EXCLUDE USING gist (subscription_id WITH =, tstzrange(opens_at, closes_at) WITH &&);
```

Đây là cách duy nhất chống race **triệt để**: ràng buộc nằm ở DB, không phụ thuộc vào việc mọi đường ghi có nhớ khoá hay không. Pessimistic lock trên hàng `Subscription` cũng chặn được race, nhưng chỉ đúng chừng nào **mọi** đường tạo kỳ thi đều đi qua đúng lối đã khoá — một endpoint mới quên khoá là thủng, và không có gì báo cho biết.

Đổi lại: `Enrollment`/`ExamSession` phải bắt `DataIntegrityViolationException` trên tên constraint này và dịch thành 409, thay vì kiểm trước rồi ném exception của mình. Vẫn nên giữ một lần kiểm ở tầng application **trước** khi insert — không phải để đảm bảo đúng, mà để trả thông báo lỗi nói rõ kỳ thi nào đang chiếm khung giờ đó.

---

## 4. Giới hạn sinh viên — hai tầng khác nhau, đừng lẫn

| Tầng | Giới hạn gì | Nguồn | Enforce ở đâu |
|---|---|---|---|
| **Tenant** | Tổng số sinh viên tồn tại trong tổ chức | `freeStudentLimit` + Σ gói `STUDENT_CAPACITY` | `identity` — lúc tạo/bulk-create user role STUDENT |
| **Kỳ thi** | Số sinh viên trong một kỳ thi | `subscription.maxStudentsPerSession` | `session` — lúc enroll |

**Hiện trạng cần sửa:** `Tenant.studentLimit` đang được ghi ở `TenantLifecycleService` và `QuotaTransactionService` nhưng **không có chỗ nào đọc để chặn**. Nghiệp vụ mới biến nó thành ràng buộc thật → `identity` phải gọi `TenancyService` kiểm hạn mức trước khi tạo student, và `UserBulkCreateWriter` phải kiểm theo lô chứ không theo từng dòng.

### Sinh viên trùng slot thi

Khi enroll vào kỳ thi `S`: sinh viên đã có enrollment ở một kỳ thi khác **cùng tenant** có khung giờ giao với `S` thì bị **loại khỏi lô**, không phải làm hỏng cả request.

`BulkEnrollResponse` hiện là `(enrolled, alreadyEnrolled)` → thêm nhánh thứ ba `skippedByConflict[]` kèm kỳ thi gây xung đột, và phát event cho `notification` báo lại tenant.

**Ràng buộc hiệu năng:** enroll 500 sinh viên không được sinh 500 query. Một query duy nhất `WHERE student_public_id IN (:ids) AND opens_at < :closesAt AND closes_at > :opensAt`, rồi diff trong bộ nhớ.

---

## 5. `assessment`: từ soạn đề sang sinh đề

### Thay đổi bản chất

Hiện tại `ExamBlueprint` + `BlueprintItem` là thứ **host tự soạn** — chọn tay từng `questionPublicId`. Nghiệp vụ mới: host không chạm vào câu hỏi.

```
ExamTemplate         tenantId = null (platform-owned), name, status
  ├─ TemplateSection    section, weightPercent        (Σ = 100)
  └─ TemplateSlot       taskType, questionCount, orderIndex

ExamSnapshot       + templatePublicId, randomSeed, sectionWeights
```

Luồng mới: tenant tạo kỳ thi → chọn template → resolver random lấy câu từ kho SHARED theo từng slot → publish snapshot ngay trong cùng transaction.

`ExamBlueprint` trở thành **artifact được sinh ra**, không còn là thứ người dùng soạn. Các endpoint soạn blueprint thủ công của host bị rút.

### Ba ràng buộc của resolver

1. **Kiểm đủ câu trước khi sinh.** Kho thiếu câu cho một slot → 422 kèm tên task type thiếu. Không bao giờ phát đề thiếu câu rồi báo sau.
2. **Lưu `randomSeed`.** Đề đã phát phải tái tạo được để audit và để khiếu nại điểm có cơ sở. Random không lưu seed là random không giải trình được.
3. **Seed không lộ ra ngoài `assessment`.** Không endpoint nào trả `randomSeed` hay nội dung snapshot cho host trước `opensAt` — nếu không thì "random đề" chỉ là trang trí.

### `weightPercent` chảy đi đâu

`TemplateSection.weightPercent` được **snapshot hoá vào `ExamSnapshot`** cùng lúc với câu hỏi. `reporting` tính điểm tổng `Σ(điểm phần × trọng số)` đọc từ snapshot, không đọc từ `ExamTemplate` — Admin sửa template không được làm đổi điểm của kỳ thi đã diễn ra. Cùng logic với bất biến #2 ở Subscription.

---

## 6. Kho đề chỉ còn SHARED

`Visibility.PRIVATE` bị rút khỏi luồng nghiệp vụ. Tenant không tạo câu hỏi nữa — "tài nguyên do hệ thống cung cấp" là tuyệt đối.

**Kéo theo:** `ItembankAccessPolicy` rút gọn còn kiểm write-role; `SharedWriteForbiddenException` mất lý do tồn tại; `Question.tenantId` luôn null.

**Đã kiểm (2026-09-16): không có row `PRIVATE` nào trong DB** → rút enum value an toàn, không cần bước migrate dữ liệu. Vẫn phải rút theo thứ tự: bỏ đường ghi `PRIVATE` trước, rút enum sau — nếu còn code nào ghi được giá trị đã rút thì Hibernate nổ lúc đọc.

---

## 7. Hai đường mua gói, một nơi kích hoạt

Nền tảng bán sỉ nên phải hỗ trợ cả bán trực tiếp lẫn bán qua đại lý / sales:

| | Đường A — thanh toán trực tiếp | Đường B — redeem mã |
|---|---|---|
| Khởi đầu | Tenant chọn Plan, tạo `Order` | Admin phát hành `LicenseCode` |
| Xác nhận | Webhook PayOS báo `PAID` | Tenant nhập mã |
| Bán ở đâu | Trên nền tảng | Ngoài nền tảng (đại lý, hợp đồng, chuyển khoản) |

Cả hai hội tụ vào **một** thao tác `activate(tenant, plan, source)` — nơi duy nhất trong code sinh ra `Subscription` (bất biến #4). Hai đường vào, một nơi ghi; nếu logic kích hoạt bị nhân đôi thì sớm muộn hai đường sẽ lệch nhau về `expiresAt`, `licenseKey`, hoặc snapshot cap.

Ba điểm dễ sai ở đường B:

1. **Hạn của mã ≠ hạn của gói.** `codeExpiresAt` là hạn phải redeem; `Subscription.expiresAt` tính **từ lúc redeem**, không phải từ lúc phát hành. Mã phát tháng 1, redeem tháng 6 → gói chạy từ tháng 6.
2. **Redeem phải atomic.** Hai request cùng nhập một mã thì chỉ một được ăn. Dùng `UPDATE license_codes SET status='REDEEMED', ... WHERE code = ? AND status = 'ISSUED'` rồi kiểm số hàng bị ảnh hưởng — **không** đọc-rồi-ghi, vì đọc-rồi-ghi là chỗ sinh ra hai Subscription từ một mã.
3. **Mã là bearer token trên thực tế.** Ai cầm mã thì kích hoạt được. Sinh bằng nguồn ngẫu nhiên mật mã, đủ dài để không brute-force được, và rate-limit endpoint redeem — nếu không thì quét mã hợp lệ là chuyện khả thi.

### PayOS

**Chọn PayOS** (tài khoản đã có). Ba điểm ảnh hưởng thiết kế:

1. **`orderCode` là số nguyên (long), unique toàn merchant.** Không tái dùng được `BaseEntity.publicId` (UUID) → cần sequence riêng trong DB.
2. **Kích hoạt Subscription nằm ở webhook handler**, không ở returnUrl. Handler phải verify chữ ký HMAC bằng `checksumKey` và **idempotent** — PayOS retry webhook, xử lý hai lần không được tạo hai Subscription.
3. **PayOS chưa có SDK Java chính thức** (chỉ Node/PHP/Python/Go) → gọi REST trực tiếp, tự implement phần ký. Thuật toán ký phải verify lại với docs khi implement, không làm theo trí nhớ.

`Order` ở trạng thái `PENDING` quá lâu (ví dụ 24h) không tự thành `EXPIRED` — cần job dọn, hoặc chấp nhận để nguyên và không cho tạo Order mới khi còn Order pending cùng Plan.

**Ngoài phạm vi (chốt 2026-09-16):** không làm bán mã theo lô. Mã phát lẻ từng cái, không có entity lô, không có batch issue.

---

## 8. Huỷ gói, hoàn tiền, thu hồi mã

Ba đường dẫn tới cùng một kết cục — một `Subscription` ngừng dùng được:

| Sự kiện | Điều kiện | Kết quả |
|---|---|---|
| Huỷ đơn chưa thanh toán | `Order` còn `PENDING` | Huỷ payment link qua API PayOS, `Order → CANCELLED`. Chưa có Subscription nào tồn tại, không có gì để hoàn |
| Admin thu hồi mã đã redeem | `LicenseCode` đã `REDEEMED` | `LicenseCode → REVOKED` → **huỷ luôn Subscription sinh ra từ mã đó** |

**Ngoài phạm vi (chốt 2026-09-16): chưa làm chức năng hoàn tiền.** Gói đã thanh toán thì không có đường huỷ do tenant khởi xướng — chỉ Admin thu hồi mã mới huỷ được Subscription, và không kèm chuyển tiền.

Khi nào làm, giữ nguyên tắc này: **việc chuyển tiền tách khỏi việc huỷ quyền dùng.** Huỷ Subscription là thao tác trong hệ thống, hoàn tiền là thao tác ở PayOS/ngân hàng — ghi nhận riêng, và không để huỷ quyền phải chờ tiền về, vì một lần hoàn tiền lỗi sẽ để tenant tiếp tục dùng gói đã huỷ.

### Kỳ thi đã tạo trên làn bị huỷ

Đây là hệ quả bắt buộc, không phải lựa chọn — huỷ Subscription mà để kỳ thi của nó chạy tiếp thì việc huỷ vô nghĩa:

- Kỳ thi `SCHEDULED` trên làn đó → **huỷ theo**, phát thông báo cho tenant kèm danh sách kỳ thi bị ảnh hưởng
- Kỳ thi `OPEN` / `CLOSED` → **không đụng vào**. Đã diễn ra rồi, không rút lại được; điểm và bài làm vẫn là dữ liệu hợp lệ của tenant

Dữ liệu để tính tỷ lệ hoàn sau này đã có sẵn nếu cần: số kỳ thi đã `CLOSED` trên `licenseKey` đó.

---

## 9. Đình chỉ tenant — đồng hồ gói không dừng

Đình chỉ là **hình phạt**, không phải tạm dừng dịch vụ. `Tenant.suspend()` nhận thêm `suspendedUntil` do Admin đặt cho từng lần.

**Mặc định là 0 — nghĩa là không tự hết hạn.** Tenant ở trạng thái `SUSPENDED` cho tới khi Admin bấm `reactivate()`. Đây là mặc định an toàn: đình chỉ là hành động có chủ đích, việc gỡ nó cũng phải có chủ đích. Admin đặt số ngày > 0 khi muốn hình phạt tự hết hạn.

**`Subscription.expiresAt` không được gia hạn bù.** Thời gian bị treo là thời gian tenant mất — đó chính là nội dung của hình phạt. Dừng đồng hồ rồi trả lại sau thì đình chỉ không còn sức răn đe nào.

Trong thời gian bị đình chỉ:

| | |
|---|---|
| Tạo kỳ thi mới | Chặn |
| Mở kỳ thi `SCHEDULED` | Chặn |
| Enroll sinh viên | Chặn |
| Mua gói mới / redeem mã | Chặn |
| **Attempt đang chạy** | **Không đụng vào** |

Dòng cuối là bắt buộc, không phải nhân nhượng: đình chỉ là thao tác control-plane, và bất biến #4 của ADR-001 cấm control plane chạm vào critical path. Sinh viên đang làm bài dở không được mất bài vì một quyết định hành chính nhắm vào tổ chức. Chặn ở điểm *bắt đầu*, không chặn ở điểm *đang diễn ra*.

**Hệ quả chấp nhận có chủ đích:** đình chỉ kéo dài quá `expiresAt` thì gói chết hẳn, tenant mất trắng phần còn lại. Đúng ý đồ — nhưng Admin cần thấy được điều đó trước khi bấm, nên màn hình đình chỉ phải hiện số gói và số ngày sẽ bị mất.

Hết hạn `suspendedUntil` → tenant tự động trở lại `ACTIVE`. Cần một job quét, vì không có gì khác kích hoạt chuyển trạng thái này. Với mặc định 0 thì job không có việc gì làm — nó chỉ phục vụ các lần đình chỉ có đặt thời hạn.

---

## Consequences

**Được:** nghiệp vụ thương mại đầy đủ, self-service từ đăng ký tới thanh toán. Kho đề tập trung → chất lượng đề kiểm soát được. Random theo template làm mất giá trị của việc học tủ. Ràng buộc gói enforce tại điểm ghi → không có trạng thái "đã vượt hạn mức" tồn tại trong hệ thống.

**Trả giá (chấp nhận có chủ đích):**
- Mất hoàn toàn khả năng host tự soạn đề. Host nào cần đề riêng sẽ không dùng được nền tảng — đây là đánh đổi về định vị sản phẩm, không phải thiếu sót kỹ thuật.
- `licenseKey` denormalize ở hai bảng → thao tác đổi gói phải cascade và phải khoá hai hàng `Subscription` theo thứ tự cố định. Chi phí này là **tự chọn**: nó tồn tại vì cột trên `Enrollment` phục vụ đối soát, không vì tính đúng đắn (xem §2).
- Pessimistic lock trên `Subscription` serialize việc tạo kỳ thi trong cùng làn. Với tần suất thực tế (vài kỳ thi/ngày) thì không đáng kể, nhưng nó **là** một điểm nghẽn có thật cần nhớ.
- Thêm phụ thuộc bên thứ ba (PayOS) vào luồng kích hoạt gói. PayOS sập → **đường A** không mua được gói mới, **đường B (redeem mã) vẫn chạy** — hai đường mua ngoài mục đích thương mại còn là một lớp dự phòng. Kỳ thi đang chạy không ảnh hưởng (bất biến #4 của ADR-001 vẫn giữ: control plane ngoài critical path).
- Mã kích hoạt là bearer token ngoài tầm kiểm soát của nền tảng sau khi phát hành. Mã lọt ra ngoài = mất một gói. Bù bằng `REVOKED` và log phát hành, không bù được bằng cách thu hồi mã đã in ra.

**Nợ kỹ thuật kế thừa, không giải trong ADR này:** RLS vẫn chưa có — `licenseKey` và `subscriptionId` là cột tenant-scoped mới, hiện chỉ được ép ở tầng application như mọi cột khác. Bảng mới càng nhiều thì chi phí bổ sung RLS sau này càng tăng.

---

## Cần chốt (chưa quyết)

Không còn câu hỏi nào chặn việc triển khai. Các câu đã giải:

### Đã giải (2026-09-16)

| Câu hỏi | Kết luận |
|---|---|
| Hoàn tiền / huỷ gói giữa chừng | **Chưa phát triển** — ngoài phạm vi (§8) |
| Thời hạn đình chỉ mặc định | 0 = không tự hết hạn, Admin gỡ thủ công (§9) |
| Kỳ thi đã tạo mà Subscription bị huỷ | Kỳ thi `SCHEDULED` huỷ theo, `OPEN`/`CLOSED` giữ nguyên — §8 |
| `REVOKED` mã đã redeem | Huỷ luôn Subscription sinh ra từ mã — §8 |
| Tenant bị đình chỉ thì Subscription xử lý sao | Đồng hồ **không dừng** — thời gian mất là hình phạt. Attempt đang chạy không bị đụng — §9 |
| Còn row `Question` nào `PRIVATE` không | Không có → rút `Visibility.PRIVATE` an toàn, không cần migrate — §6 |
| Phát hành `LicenseCode` theo lô | Chưa phát triển — ngoài phạm vi, thêm sau nếu cần (§7) |
| Sinh viên có thuộc nhiều tenant được không | **Câu hỏi đặt sai.** `User.tenantId` là cột scalar, một user thuộc đúng một tenant; không có bảng membership nhiều-nhiều. Kiểm trùng slot là trong-tenant **theo cấu trúc**, không phải theo lựa chọn — không cần quyết gì |

---

## Phụ thuộc: định danh sinh viên

Mô hình bán sỉ cho nhiều trung tâm không chạy được với `User.email` unique toàn cục — trung tâm Y bị chặn khi import một học viên đã từng học ở trung tâm X. Vấn đề này được giải trong **[ADR-007](ADR-007-student-identity-and-login.md)**: sinh viên đăng nhập bằng tài khoản hệ thống sinh (có tiền tố `Tenant.code`), `studentCode` unique theo tenant, email không còn là khoá.

**ADR-007 là điều kiện tiên quyết** — `Tenant.code` mà nó cần được đặt lúc Admin duyệt `TenantApplication` (§1), nên hai ADR phải triển khai cùng nhau chứ không nối tiếp.
