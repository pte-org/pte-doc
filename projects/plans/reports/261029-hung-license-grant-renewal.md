# Cấp gói theo hợp đồng, gia hạn gói và thu hồi gói

**Ngày:** 2026-10-29
**Người đề xuất:** Hung
**Trạng thái:** Đã tách (2026-10-30). Phần Admin cấp gói theo hợp đồng chuyển sang [plan 261029-hung-license-grant](../hung-license-grant/plan.md). Gia hạn nối tiếp cho PayOS: **bỏ**, mua thêm là gói mới chạy ngay. Thu hồi theo gói và nhắc hạn: để đợt sau.
**Phạm vi repo:** pte-api (billing, session, notification), pte-web (tenant-web, vendor-web, api-client)

---

## 1. Tóm tắt

Tổ chức có gói thi bằng **hai cách**:

| Cách | Hiện tại | Sau thay đổi |
|---|---|---|
| **Ký hợp đồng trực tiếp** | Admin phát mã → gửi cho Host → Host vào trang *Redeem* nhập mã | Admin bấm **Cấp gói** cho đúng tổ chức → gói kích hoạt luôn. Host không phải làm gì. |
| **Mua online qua PayOS** | Thanh toán xong, gói chạy ngay | Như cũ, nhưng nếu đang có gói cùng loại thì gói mới **nối tiếp** sau gói cũ (gia hạn) |

Thêm ba việc:
- **Ngày bắt đầu theo hợp đồng:** Admin chọn ngày gói bắt đầu chạy.
- **Thu hồi mọi gói**, kể cả gói mua qua PayOS (hiện chưa làm được).
- **Nhắc hạn** cho Host trước khi gói hết.

**Mã kích hoạt không bị xoá.** Nó được dùng bên trong hệ thống như "phiếu cấp gói", Host không còn nhìn thấy.

## 2. Vấn đề hiện tại

1. **Bước gửi mã thừa.** PTEPrep không bán mã ra bên ngoài. Admin gặp tổ chức trực tiếp nhưng vẫn phải phát mã, gửi mã, chờ Host nhập. Dễ gửi nhầm người, lộ mã.
2. **Gói tính ngày từ lúc Host nhập mã**, không theo ngày trên hợp đồng. Host nhập sớm là mất ngày.
3. **Không có gia hạn.** Mua thêm gói khi gói cũ còn hạn thì gói mới chạy ngay, phần còn lại của gói cũ bị chồng lên, coi như mất.
4. **Gói PayOS không thu hồi được.** Thu hồi hiện chỉ làm được thông qua mã kích hoạt.
5. **Không có nhắc hạn.** Host chỉ biết gói hết khi không đặt được lịch thi.

Thời hạn gói được tính theo **số ngày** Admin nhập cho từng gói (30 = "1 tháng", 365 = "1 năm"). Gói thêm chỗ học viên không có thời hạn. Hai điểm này **giữ nguyên**.

## 3. Vì sao giữ mã kích hoạt mà không xoá

Đã rà code `dev`: mã kích hoạt nằm trong **khoảng 34 file backend, 22 file test, 37 file frontend**. Nó đang là **đường duy nhất để thu hồi gói**, có trong dữ liệu cũ, sự kiện, thông báo, dashboard Admin và nhật ký audit.

| | Xoá hẳn mã | **Giữ mã, Admin cấp là kích hoạt luôn** ✅ |
|---|---|---|
| Host nhập mã / Admin gửi mã | Không | Không |
| Thu hồi gói cấp theo hợp đồng | Phải viết luồng mới | Có sẵn |
| Audit, dashboard, trang Admin | Viết lại | Giữ, chỉ thêm cột |
| Dữ liệu cũ | Có rủi ro lỗi khi đọc | Không đụng |
| Khối lượng | ~90 file | ~15–20 file |
| Sau này bán qua đại lý / khuyến mãi | Phải làm lại | Bật lại kiểu mã không gắn tổ chức |

Các bên khác (Pearson voucher, các nền tảng membership) chỉ dùng mã khi **người mua khác người dùng** hoặc **bán qua bên thứ ba**. PTEPrep hiện chưa có trường hợp này, nên mã chỉ cần chạy ngầm.

## 4. Các luồng chi tiết

### 4.1. Admin cấp gói theo hợp đồng

```
Admin → License codes (đổi tên: Cấp gói) → "Cấp gói"
  1. Tìm tổ chức theo MÃ TỔ CHỨC hoặc MÃ SỐ THUẾ
     (gõ email cũng được nhưng chỉ để tra cứu; nhiều kết quả thì Admin chọn một)
  2. Màn xác nhận: tên, mã tổ chức, MST (in đậm để đối chiếu hợp đồng giấy),
     địa chỉ, loại cơ sở, Host hiện tại
  3. Nhập: gói, ngày bắt đầu, số hợp đồng (bắt buộc), ghi chú
     - Ngày bắt đầu tự điền:
         · đang có gói cùng loại còn hạn → ngày gói đó hết hạn (gia hạn nối tiếp)
         · không có → hôm nay
     - Admin sửa được theo hợp đồng, không cho chọn ngày quá khứ
  4. Xem trước: chạy từ ... đến ..., số học viên tối đa mỗi kỳ thi
  5. Xác nhận → hệ thống phát mã GẮN với tổ chức này và kích hoạt ngay trong cùng một bước
     → ghi audit → Host nhận thông báo
```

**Vì sao không chọn theo Gmail:** một Gmail có thể là Host của nhiều tổ chức (cơ sở chính và chi nhánh), email liên hệ của tổ chức cũng có thể trùng. Mã tổ chức và mã số thuế thì không trùng, và mã số thuế có sẵn trên hợp đồng.

**Ví dụ:** Trung tâm ABC ký hợp đồng ngày 1/11, gói 30 ngày cho đợt thi tháng 12. Ngày 1/11 Admin cấp gói với ngày bắt đầu 1/12. Gói chạy 1/12 → 31/12. Trong tháng 11 Host đã tạo kỳ thi và đặt lịch vào tháng 12 được.

### 4.2. Host mua và gia hạn qua PayOS

```
Host → Plans & billing → chọn gói (hoặc bấm "Gia hạn" trên thẻ gói / trong thông báo nhắc hạn)
  → màn thanh toán hiện trước: "Gói chạy từ 31/12/2026 đến 31/12/2027"
  → thanh toán trên PayOS
  → PayOS báo thành công → hệ thống tính ngày bắt đầu:
       · đang có gói cùng loại còn hạn (kể cả gói đang chờ) → nối tiếp sau gói đó
       · không có → chạy ngay
  → Host nhận thông báo
```

**Ví dụ:** Gói năm hết hạn 31/12. Ngày 10/12 Host gia hạn.
- Hiện tại: gói mới chạy 10/12 → 10/12 năm sau, mất 21 ngày.
- Sau thay đổi: gói mới chạy **31/12 → 31/12 năm sau**, đủ 365 ngày.

**Đổi sang gói khác** (nâng/hạ cấp) không phải gia hạn: gói mới chạy ngay, gói cũ chạy song song đến hết. Không hoàn tiền phần còn lại (ADR-006).

### 4.3. Quy tắc gia hạn

1. **Gia hạn = cùng gói.** Gói mới bắt đầu đúng lúc gói cùng loại gần nhất hết hạn. Hệ thống tự nhận biết, Host không cần chọn "mua mới" hay "gia hạn".
2. **Không sửa ngày gói cũ.** Mỗi lần mua/cấp là một gói riêng (mã định danh, số học viên tối đa, ngày bắt đầu, ngày hết hạn riêng). Host vẫn thấy liền mạch như được cộng ngày, nhưng thu hồi, đối chiếu hợp đồng và lịch sử thanh toán không bị lẫn.
3. **Tối đa 1 gói chờ** cho mỗi loại gói (tránh mua nhầm nhiều lần). Nếu Host vẫn thanh toán được (ví dụ mở hai tab) thì vẫn kích hoạt, nối tiếp tiếp theo, vì đã nhận tiền.
4. **Gói ngừng bán** thì không mua/gia hạn được, phải chọn gói đang bán.
5. **Kỳ thi nằm vắt qua hai gói** (ví dụ 30/12 → 2/1): giữ quy tắc hiện tại, một kỳ thi phải nằm gọn trong một gói. Báo lỗi ghi rõ khoảng ngày để Host chọn gói phù hợp.

### 4.4. Host tạo kỳ thi trên gói chưa bắt đầu

```
Host → Exams → Tạo kỳ thi → chọn "Gói thi 30 ngày (01/12 – 31/12)"
  → đặt lịch 10/12–12/12  ✅ được
  → đặt lịch 25/11        ❌ "Kỳ thi phải nằm trong thời hạn gói (01/12 – 31/12)"
```

### 4.5. Admin thu hồi gói (mọi nguồn)

```
Admin → Tổ chức (hoặc danh sách gói) → chọn gói → "Thu hồi gói"
  1. Xem trước ảnh hưởng: "Sẽ huỷ 2 kỳ thi chưa diễn ra. Kỳ thi đang mở / đã đóng giữ nguyên."
  2. Nhập lý do (bắt buộc) → xác nhận
  3. Gói → Đã huỷ, kỳ thi chưa diễn ra trên gói bị huỷ, Host nhận thông báo, ghi audit
  4. Gói từ mã kích hoạt: mã cũng chuyển sang Đã thu hồi
     Gói từ PayOS: đơn hàng vẫn "Đã thanh toán", không hoàn tiền, lịch sử đơn ghi "Gói đã bị thu hồi"
```

Thu hồi một **gói chờ** không ảnh hưởng gói đang chạy. Đây cũng là cách sửa sai khi cấp nhầm: thu hồi rồi cấp lại.

### 4.6. Nhắc hạn

| Khi nào | Ai nhận | Nội dung |
|---|---|---|
| Còn 30 ngày | Host | *"Gói năm hết hạn 31/12. Gia hạn để không gián đoạn."* + nút Gia hạn |
| Còn 7 ngày | Host | Như trên, kèm số kỳ thi đã lên lịch sau ngày hết hạn (nếu có) |
| Còn 1 ngày | Host | Nhắc lần cuối |
| Đã hết hạn | Host | *"Gói đã hết hạn. Kỳ thi mới cần gói còn hiệu lực."* |
| Gói hợp đồng còn 30 ngày | Admin | Hiện trong danh sách "Sắp hết hạn" để liên hệ ký lại |

Không nhắc nếu đã có gói gia hạn đang chờ.

## 5. PayOS thay đổi gì

**Giữ nguyên toàn bộ phần kết nối PayOS:** tạo link thanh toán, kiểm tra chữ ký webhook, kiểm tra số tiền, chống xử lý trùng, đơn hết hạn/huỷ, đơn 0 đồng. Không đổi cấu hình hay tài khoản PayOS.

**Chỉ đổi phần sau khi thanh toán thành công:**

| # | Thay đổi |
|---|---|
| 1 | Tính ngày bắt đầu theo quy tắc gia hạn (mục 4.3), tính **lúc nhận webhook** chứ không phải lúc tạo đơn, có khoá để hai đơn thanh toán cùng lúc không trùng ngày |
| 2 | Màn thanh toán hiện trước ngày chạy của gói |
| 3 | Lúc tạo đơn: chặn nếu đã có 1 gói chờ cùng loại |
| 4 | Gói PayOS thu hồi được (mục 4.5) |

## 6. Thay đổi trên từng trang

### 6.1. Host – Plans & billing (tenant-web)

| Phần | Sau thay đổi |
|---|---|
| Thẻ gói | Nhãn nguồn: *Mua online / PTEPrep cấp*. Trạng thái: *Đang hiệu lực đến dd/mm*, *Sắp hiệu lực từ dd/mm*, số ngày còn lại |
| Nút Gia hạn | Trên thẻ gói đang chạy (khi nào hiện: câu hỏi mở) |
| Khi chưa có gói | *"Chưa có gói. Mua online hoặc liên hệ PTEPrep để được cấp theo hợp đồng."* |
| Lối vào trang nhập mã (menu ⋯, ô trống, thẻ danh mục) | **Bỏ** |
| Lịch sử | Hiện tất cả gói đã nhận, kể cả gói PTEPrep cấp và gói đã thu hồi |

> ⚠️ Gói chưa bắt đầu vẫn có trạng thái `ACTIVE` trong hệ thống. Nhãn *Sắp hiệu lực* **phải làm cùng đợt** với cấp gói và gia hạn, nếu không Host sẽ tưởng gói đã dùng được.

### 6.2. Host – trang Redeem license code

**Ẩn** khỏi giao diện. Sửa câu thông báo ở module tạo kỳ thi (đang ghi *"redeem a license or purchase a plan first"*).

### 6.3. Host – Tạo kỳ thi

Danh sách chọn gói hiện cả gói đang chạy và gói chờ, kèm khoảng ngày. Báo lỗi ghi rõ khoảng hiệu lực.

### 6.4. Admin – trang License codes → "Cấp gói" (vendor-web)

- Form *Phát mã* thay bằng form *Cấp gói* (mục 4.1).
- Danh sách thêm cột: tổ chức, số hợp đồng, ngày bắt đầu, ngày hết hạn.
- Không còn phát mã "trôi nổi" (không gắn tổ chức).

### 6.5. Admin – trang tổ chức

- Danh sách gói của tổ chức, mỗi gói có nút **Gia hạn** (mở form cấp gói đã điền sẵn) và **Thu hồi**.

### 6.6. Admin – Dashboard

- Giữ số liệu mã như hiện tại. Thêm danh sách gói **sắp hết hạn chưa có gói gia hạn** (dashboard đã có cờ 30 ngày).

### 6.7. Admin – trang Plans

Giữ nguyên.

## 7. Phạm vi

| Ưu tiên | Hạng mục | Repo |
|---|---|---|
| **P1** | Kích hoạt gói có ngày bắt đầu; cho tạo kỳ thi nháp trên gói chưa bắt đầu | pte-api |
| **P1** | Admin cấp gói = phát mã gắn tổ chức + kích hoạt ngay, có số hợp đồng, audit, thông báo | pte-api, vendor-web |
| **P1** | Gia hạn nối tiếp cho cả PayOS và Admin cấp | pte-api, tenant-web, vendor-web |
| **P1** | Plans & billing: nhãn nguồn, *Sắp hiệu lực*, nút Gia hạn, ẩn lối vào nhập mã | tenant-web, api-client |
| **P2** | Thu hồi theo gói cho mọi nguồn (PayOS) | pte-api, vendor-web |
| **P2** | Nhắc hạn 30/7/1 ngày và khi hết hạn | pte-api (notification) |
| **P2** | Sửa script seed local sang luồng cấp gói | pte-api |
| **P3** | Danh sách "Sắp hết hạn" cho Admin, lịch sử gói đủ nguồn cho Host | pte-web |
| **P3** | Dời ngày bắt đầu khi gói chưa chạy | pte-api, vendor-web |

**Ngoài phạm vi:** xoá mã kích hoạt, tự động trừ tiền định kỳ, hoàn tiền / tính tiền ngày lẻ khi đổi gói, kỳ thi dùng hai gói nối tiếp, phát mã theo lô, bán mã qua đại lý.

## 8. Thứ tự triển khai

1. Backend: kích hoạt có ngày bắt đầu + quy tắc gia hạn + nới điều kiện tạo kỳ thi nháp.
2. Admin cấp gói (mã gắn tổ chức) và gia hạn từ phía Admin.
3. Host: nhãn trạng thái, nút Gia hạn, ẩn trang nhập mã. **Phát hành cùng bước 2.**
4. Thu hồi gói PayOS, nhắc hạn.

Mỗi bước không làm hỏng luồng đang chạy: mã cũ vẫn nhập được cho tới khi bước 3 ẩn trang.

## 9. Rủi ro

| Rủi ro | Cách giảm |
|---|---|
| Admin cấp nhầm tổ chức | Chọn theo mã tổ chức/MST, màn xác nhận làm nổi MST, bắt buộc số hợp đồng, thu hồi để sửa sai |
| Host tưởng gói chờ đã dùng được | Nhãn *Sắp hiệu lực* phát hành cùng đợt, báo lỗi lịch thi ghi khoảng ngày |
| Host mua gia hạn nhiều lần | Giới hạn 1 gói chờ, màn thanh toán hiện ngày chạy |
| Hai thanh toán cùng lúc bị trùng ngày bắt đầu | Tính ngày lúc nhận webhook, khoá dòng gói khi tính |
| Thu hồi huỷ kỳ thi ngoài ý muốn | Bắt buộc xem trước ảnh hưởng và nhập lý do; kỳ thi đang mở/đã đóng không bị đụng |
| Kỳ thi vắt qua ngày chuyển gói bị chặn | Báo lỗi gợi ý chọn gói phù hợp; theo dõi phản hồi trước khi làm "kỳ thi dùng hai gói" |

## 10. Câu hỏi cần chốt

1. **Ai được cấp, gia hạn và thu hồi gói?** Chỉ Platform Admin, hay cả Platform Manager? (Hiện phát mã: cả hai; thu hồi mã: chỉ Admin.)
2. **Ngày bắt đầu xa nhất** Admin được chọn? Đề xuất không quá 6 tháng kể từ ngày cấp.
3. **Nút Gia hạn** luôn hiện, hay chỉ khi gói còn ≤ 30 ngày?
4. **Có ân hạn sau khi hết hạn không?** Ví dụ 7 ngày vẫn xem kết quả/chấm bài nhưng không tạo kỳ thi mới.
5. **Gia hạn có được đổi sang gói khác mà vẫn nối tiếp không?** Ví dụ hết Gói năm thì gia hạn bằng Gói năm Plus.
6. **Có "gói chỉ cấp theo hợp đồng" không?** Gói giá riêng, chỉ Admin cấp, không hiện trong danh mục mua online. Nếu có thì thêm ô *"Hiện trong danh mục mua online"* cho từng gói.
7. **Thu hồi khi đang có kỳ thi mở:** đề xuất được, chỉ huỷ kỳ thi chưa diễn ra (giống luồng thu hồi mã hiện tại).
8. **Gói thêm chỗ học viên:** Admin cấp loại này có cần ngày bắt đầu không, và có cần thu hồi được không (hiện không thu hồi được)?

---

## Phụ lục: ghi chú kỹ thuật cho bước spec

Rà trên `pte-api@dev` và `pte-web@dev` ngày 2026-10-29.

**Hiện trạng**
- `Organization.publicId` chính là `tenantId` ở các module khác. `code` và `taxCode` duy nhất trong số tổ chức chưa bị từ chối; `contactEmail` không duy nhất; `User` có thể thuộc nhiều tổ chức.
- `SubscriptionActivationService.activate(tenantId, plan, source)` là đường duy nhất tạo Subscription: `startsAt = clock.instant()`, `expiresAt = startsAt + durationDays`. Được gọi từ `LicenseCodeRedeemer:66`, `PayOsWebhookService:99`, `OrderPersistenceService.completeFreeOrder:84`.
- `SubscriptionRepository.findUsableForPlanRenewal` có khoá `PESSIMISTIC_WRITE` nhưng **chưa có nơi gọi**; điều kiện `startsAt <= now` cần nới để tính cả gói chờ.
- Redeem: `POST /api/v1/license-code-redemptions` (`HOST_ADMIN`), tenant lấy từ JWT. Mã hiện **không gắn tổ chức** (bearer).
- `Subscription.cancel()` chỉ được gọi từ `LicenseCodeRevoker`. Thu hồi phát `SubscriptionRevokedEvent` → `SubscriptionRevokedSessionListener` (huỷ kỳ thi SCHEDULED, BEFORE_COMMIT) và `CommercialNotificationListener` (thông báo Host). Có preview TTL 5 phút + scope digest. `LicenseRevokeScopeResolver` từ chối mã của gói `STUDENT_CAPACITY`.
- `Subscription.isUsableAt(now)` = `startsAt ≤ now < expiresAt`. Kiểm tra lịch thi trong khoảng gói: `SessionSubscriptionRules:55`, `ExamDraftService:232`, `ExamPublishService:258`. **Cần nới:** `ExamDraftService:230`, `SessionSubscriptionRules:52` đang đòi `isUsableAt(now)`.
- Không thấy ràng buộc "một gói một kỳ thi" ở session → mua hai gói giống nhau chạy song song không có lợi, nên tự động nối tiếp là an toàn.
- `SubscriptionExpirationService` chạy mỗi phút, chuyển sang `EXPIRED`, không phát sự kiện nhắc hạn. `InboxNotificationType` chưa có loại nhắc hạn. `BillingOverviewService.EXPIRING_SOON_DAYS = 30` chỉ dùng cho dashboard.
- Script seed `scripts/seed-local-exam-ready.ps1:353-371` phát rồi nhập mã để tạo gói demo.

**Gợi ý thiết kế**
- `license_codes` thêm: `bound_tenant_id`, `requested_starts_at`, `contract_reference`, `note`. Migration Flyway mới (kiểm tra số V cao nhất trên `dev`).
- `LicenseCodeService.grantToTenant(...)`: `LicenseCodeIssuer` phát mã gắn tenant + `LicenseCodeRedeemer.redeem(code, tenantId, startsAt)` trong một transaction. Redeemer kiểm tra `bound_tenant_id` khớp nếu có.
- `activate(tenantId, plan, source, startsAt)`; thêm hàm `resolveRenewalStart(tenantId, planId, now)` = `max(now, max(expiresAt) của gói ACTIVE cùng tenant + plan)`, chạy trong transaction có khoá. Webhook và đơn 0 đồng dùng hàm này; Admin grant dùng làm giá trị mặc định.
- Có thể thêm `Subscription.renewalOf` để hiển thị chuỗi gia hạn.
- Thu hồi theo gói: tách `SubscriptionRevocationImpactQuery` + scope digest khỏi `LicenseCodeRevoker`. Endpoint `GET/POST /api/v1/admin/subscriptions/{publicId}/revoke-preview|revoke`; nếu gói có mã thì đánh dấu mã REVOKED.
- Nhắc hạn: job hằng ngày phát `SubscriptionExpiringEvent(tenantId, subscriptionId, daysLeft)`, khoá chống trùng `subscription:{id}:expiring:{30|7|1}`, listener ghi inbox (giống mẫu `order:%s:expired`).
- Endpoint gợi ý: `POST /api/v1/admin/license-codes/grants` (hoặc `/api/v1/admin/tenants/{tenantId}/subscription-grants`), giữ endpoint redeem phía backend nhưng ẩn trên UI.
- tenant-web: trạng thái *Sắp hiệu lực* dựa trên `startsAt > now`; `activationSource` đã có trong response.

**Nguồn tham khảo**
- Pearson VUE – PTE vouchers: https://www.pearsonvue.com/us/en/pte/vouchers.html
- Pearson PTE – Contact / Expiry date extension: https://www.pearsonpte.com/help-center/contact-us.html
- AlfaPTE – B2B pricing: https://b2b-pricing.alfapte.com/
- iQIYI – VIP code key: https://www.iq.com/vip/codekey
