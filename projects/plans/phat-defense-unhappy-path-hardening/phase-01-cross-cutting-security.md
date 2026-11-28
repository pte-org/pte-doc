# Phase 1: Bảo mật xuyên suốt

**Owner gợi ý:** Hùng (1A, FR-07), Quang (1B, FR-04) · **Ưu tiên:** P1 · **Phụ thuộc:** không

## Overview

Chặn ở backend hai lỗ hổng "bỏ qua UI" mà hội đồng dễ thử bằng Postman: staff còn temp password gọi được mọi API (2-1), và tự duyệt nội dung của chính mình kể cả Admin, rubric activate từ DRAFT (1-3, DS-01c). Hai phần độc lập, làm riêng được.

## Spec stories covered

- P1: staff đăng nhập bằng temp password chỉ gọi được đổi mật khẩu và đăng xuất (FR-07).
- P1: Academic Manager và Platform Admin không tự duyệt hay tự activate nội dung của mình (FR-04, một phần; phần template ở phase 02).

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/TEST_SCENARIOS_IAM.md`.

Mục 1A (FR-07), đường dẫn dưới `pte-api/app/src/main/java/com/pte/`:
- `identity/internal/security/AccessTokenIssuer.java` — thêm claim `pwd_change_required` theo `User.mustChangePassword`.
- `identity/internal/config/SecurityConfig.java` — gắn filter mới vào chuỗi lọc sau xác thực JWT.
- `identity/internal/security/` — tạo filter chặn (một lớp nhỏ) và tạo bộ danh sách cho qua (change-password, logout; xác minh đường dẫn thật của hai endpoint trong `identity/internal/controller/`).
- `identity/internal/constant/*Constants.java` — mã lỗi `PASSWORD_CHANGE_REQUIRED` và thông điệp (xác minh tên file constants của identity trước khi thêm).
- `identity/internal/service/` — nơi xử lý đổi mật khẩu (`UserCredentialRotation.java`, `UserProfileService.java`) cần cấp lại token không còn claim.
- `identity/internal/service/RefreshTokenService.java` — refresh phải đọc cờ hiện tại của user, không copy claim cũ.

Mục 1B (FR-04):
- `shared/security/SecurityPolicy.java` — bỏ admin override tại `canReviewAcademic`/`canPublishAcademic` khi caller là tác giả.
- `scoring/internal/rubric/workflow/RubricWorkflowPolicy.java` — luôn kiểm self-approval; chỉ cho activate từ PENDING.
- `scoring/internal/rubric/service/RubricVersionCommandService.java` — dùng policy mới; xem xét 1-10 (chủ sở hữu draft) ở mức ghi nhận, không bắt buộc.
- `itembank/internal/service/lifecycle/QuestionApprovalService.java` — xác nhận gọi `SecurityPolicy`, không có đường vòng.
- `scoring/internal/constant/ScoringConstants.java`, `itembank/internal/constant/*` — mã lỗi mới nếu cần (xác minh).

## Implementation steps

1A. Thêm claim `pwd_change_required` khi cấp access token; bỏ claim khi user không còn cờ.
1A. Viết filter chạy sau xác thực: nếu claim bật và đường dẫn ngoài danh sách cho qua thì trả 403 `PASSWORD_CHANGE_REQUIRED` đúng envelope lỗi hiện có.
1A. Đảm bảo đổi mật khẩu xong thì token mới (và refresh) không còn claim; token cũ còn claim bị chặn tới hết hạn (15 phút), ghi chú hành vi này.
1A. Kiểm các luồng web/app dùng cờ `mustChangePassword` trong `TokenResponse` vẫn chạy: login, đổi mật khẩu, tiếp tục.
1B. Bỏ ngoại lệ admin cho trường hợp caller là tác giả ở policy dùng chung; giữ quyền duyệt bản của người khác.
1B. Sửa chính sách rubric: kiểm self cho mọi chuyển trạng thái, activate chỉ từ PENDING; DRAFT phải submit rồi người khác duyệt.
1B. Cập nhật thông điệp lỗi trong Constants và kịch bản DS-01c trong ghi chú cho phase 07.

## Tests

Mới (đặt song song với lớp được test, dưới `pte-api/app/src/test/java/com/pte/`):
- `identity/internal/security/` — test filter: claim bật + API khác bị 403, change-password và logout qua, claim tắt thì qua.
- Mở rộng `identity/internal/security/AccessTokenIssuerTest.java` — claim có/không có.
- Test tích hợp đăng nhập temp password, đổi mật khẩu, gọi API khác (mở rộng test IAM hiện có; tìm trong `identity/`).
- Mở rộng `shared/security/SecurityPolicyTest.java` — admin tác giả bị chặn; admin khác tác giả vẫn duyệt được.
- Test mới cho `RubricWorkflowPolicy` (chưa thấy test cũ, tạo mới): activate DRAFT bị chặn, tác giả tự submit-duyệt bị chặn, PENDING do người khác duyệt thành công.
- Chạy `ApiInventoryExportTest` nếu endpoint đổi (không kỳ vọng đổi).

## Design Constraints

- Migration chỉ additive từ V61+ (phase này dự kiến không cần; nếu cần phải kiểm số cao nhất trong `db/migration`, hiện là V60).
- Mọi setting mới phải được seed trong cùng migration (phase này không thêm setting).
- Thông điệp người dùng và mã lỗi đặt trong `*Constants.java` của module sở hữu; giữ nguyên envelope và mã lỗi hiện có (`docs/API_RESPONSE_SETUP.md`).
- Cross-module chỉ qua public service API; filter ở `identity` không chọc vào internals của module khác.
- Không file nào quá 300 dòng, `internal/**` không quá 15 lớp (ratchet test trong `app/src/test/java/com/pte/architecture`); tách lớp nhỏ nếu `security` sắp đầy.
- Dùng `Clock` inject cho mọi so sánh thời gian.
- Không nới lỏng kiểm tra tác giả để tiện demo; Admin cũng bị chặn.
- Restart docker app local sau khi đổi backend rồi mới kiểm tay.

## Risks

- Chặn nhầm API cần cho đổi mật khẩu (ví dụ lấy profile): mitigation là danh sách cho qua kiểm bằng test với luồng web/app thật, chỉ thêm khi thật sự cần.
- Token cũ còn claim sau khi đổi mật khẩu gây vòng lặp: mitigation là app/web luôn dùng token trả về từ endpoint đổi mật khẩu hoặc refresh.
- Manager hợp lệ không còn duyệt được vì dữ liệu cũ thiếu người tạo: mitigation là kiểm null tác giả trong policy và test.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (tdd green 2026-11-28: 30 phase + 34 related, ratchet OK)

## Todo

- [ ] Đọc các tiêu chuẩn đã nêu và ghi lại trong báo cáo tiến độ đầu tiên
- [ ] 1A: claim + filter + constants + cấp lại token sau đổi mật khẩu
- [ ] 1A: test filter, token issuer, tích hợp
- [ ] 1B: SecurityPolicy bỏ admin override khi là tác giả
- [ ] 1B: RubricWorkflowPolicy self-check + chỉ activate từ PENDING
- [ ] 1B: test SecurityPolicy và RubricWorkflowPolicy
- [ ] `.\mvnw.cmd -pl app -DskipTests compile` và test liên quan + ratchet architecture
- [ ] Restart docker app local, thử curl tay các kịch bản 2-1, 1-3

## Bổ sung sau red-team (2026-11-27)

- **[BLOCK B1] Student import có `mustChangePassword=true`** (`identity/internal/service/UserBulkCreateWriter.java:45-46`). pte-app
  không xử lý cờ này, nên filter áp cho mọi role sẽ khóa học viên khỏi mọi API thi (DS-03a/b). Hướng xử lý: xem quyết định
  "Phạm vi filter" ở mục Validation của plan.md. Dù chọn hướng nào, test bắt buộc gồm: Student import đăng nhập pte-app rồi bắt đầu attempt.
- **[H3] Null author:** dữ liệu cũ không có tác giả thì **cho phép** duyệt (không có ai để tự duyệt), chỉ chặn khi `author == caller`.
  Không được dùng null như một đường vòng: test riêng cho trường hợp null và trường hợp tác giả trùng.
- **[H3] Runbook:** trước demo phải có trên prod ít nhất 2 tài khoản duyệt (Manager M1, M2) và 1 Academic Staff; phase 08 kiểm.
