# Phase 3: Gói chờ dùng được để lên lịch

**Status:** Not started · **Repo:** pte-api · **Stories:** P1 #4 (FR-11)

Gốc đường dẫn: `pte-api/app/src/main/java/com/pte/`

## Mục tiêu

Host tạo nháp, publish và đổi lịch kỳ thi trên gói chưa tới ngày chạy, miễn là lịch nằm gọn trong khoảng của gói. **Không** cho mở kỳ thi, không mở practice trước `startsAt`.

## Hiện trạng đã xác minh

- `lockSubscriptions` / `lockedActiveSubscription` (`ExamSessionAccess:57`, `SessionSubscriptionRules:40`) trả dòng đã khóa ở mọi trạng thái. Kiểm tra "dùng được" chỉ chạy sau đó.
- Kiểm tra thật chỉ có 3 chỗ:
  - `SessionSubscriptionRules.validateSubscriptionWindowAndCapacity:48-56`, dùng chung cho tạo, đổi lịch, promote, gia hạn, **mở thủ công** (`SessionStateService:73`) và **auto-open** (`:121`)
  - `ExamDraftService:230`
  - preflight publish `ExamPublishService:255` (qua `getActiveSubscription`)
- Bắt đầu attempt chỉ đòi session ở trạng thái OPEN (`EntitlementService:69`). Vì vậy **mở thủ công là đường duy nhất dùng gói sớm**.

## Việc cần làm

1. Thêm `SubscriptionView.isSchedulableAt(now)` = `ACTIVE && expiresAt > now`. Thêm `Subscription.isSchedulableAt(now)` = như trên và kiểm tra thêm `!deleted`. `isUsableAt` giữ nguyên.
2. `BillingService`:
   - Thêm `getSchedulableSubscription(id, tenantId)` và `listSchedulableSubscriptions(tenantId)`.
   - `getActiveSubscription` / `listActiveSubscriptions` giữ nguyên, vì practice (`PracticeEntitlementService:110`), overview và suspension impact đang dùng.
3. `SessionSubscriptionRules.validateSubscriptionWindowAndCapacity`: thêm tham số `boolean requireStarted`.
   - `true` → `isUsableAt(now)`, như hiện nay.
   - `false` → `isSchedulableAt(now)`.
   - Chỉ `SessionStateService.open` (`:73`) và `openIfDue` (`:121`) truyền `true`. Mọi chỗ gọi khác truyền `false`.
   - Fallback `:44` dùng `getSchedulableSubscription`.
4. `ExamDraftService:230` và preflight `ExamPublishService:255` chuyển sang "lên lịch được".
5. `SubscriptionController:46` (`GET /api/v1/subscriptions`) dùng `listSchedulableSubscriptions`. `revealLicenseKey:78` dùng `getSchedulableSubscription`.
6. Mở thủ công trên gói chưa chạy trả lỗi riêng `SESSION_SUBSCRIPTION_NOT_STARTED`, kèm ngày bắt đầu. Lỗi "ngoài khoảng gói" (`SessionWindowOutsideSubscriptionException`) kèm `dd/MM/yyyy – dd/MM/yyyy`.

## Design Constraints

- Không đổi nghĩa `isUsableAt` / `getActiveSubscription`. Mỗi chỗ chuyển phải nêu lý do trong PR.
- Không sửa `EntitlementService`, `SessionCreationService`, `SessionScheduleService`, `SessionSubscriptionService` ngoài việc truyền cờ.
- Điểm danh của giám thị được phép sớm `PROCTOR_LEAD_TIME` trước `opensAt`. Chấp nhận.

## Tests

- Test mới `SessionSubscriptionRulesTest`: gói chờ + `requireStarted=false` thì qua; gói chờ + `true` thì lỗi; lịch trước `startsAt` → lỗi kèm khoảng ngày.
- `ExamWorkflowServicesTest`: gói chờ 01/12–31/12; nháp 10/12 được, 25/11 bị 422; publish nháp 10/12 được.
- Test cho `SessionStateService`: mở thủ công khi `now < startsAt` bị từ chối.
- `BillingServiceTest`: `listSchedulableSubscriptions` có gói chờ; `listActiveSubscriptions` / `hasActiveExamPackageSubscription` không có.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
