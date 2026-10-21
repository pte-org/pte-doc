# Phase 16: Auth, report & suspension operator contract

Owner: **Quang**
Status: **Implemented — focused and full regression evidence passed; production release boundary remains open**
Depends on: **Phase 13**; can run in parallel with Phase 15 after contract review
Maps to: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §5, §9 · [ADR-007](../../architecture/ADR-007-student-identity-and-login.md)

## Requirements

Backend đã có `mustChangePassword`, endpoint `POST /api/v1/auth/change-password` và report snapshot có `appliedWeight`, nhưng web contract/flow chưa enforce hoặc giải thích đầy đủ. Suspension impact preview cũng đang hiển thị một phần danh sách, chưa ràng buộc preview với confirmation, và scheduled auto-reactivation chưa có system audit tương đương manual reactivation.

## Design Constraints

- `mustChangePassword` là security/business gate, không phải field để UI bỏ qua. Session chỉ được đưa user vào workspace sau khi đổi mật khẩu thành công; user luôn có thể logout.
- API client phải phản ánh response backend thật và xoá comment/typing ngược với endpoint đang tồn tại. Không hiển thị raw machine error cho người dùng.
- First-login flow của tenant-web và vendor-web phải dùng common UI/i18n patterns hiện có; route file mỏng, user-facing copy nằm trong constants/catalog.
- Report score phải giải thích được applied weight lấy từ immutable snapshot, gồm trường hợp normalized weight khi kỳ thi chỉ có một phần.
- Suspension impact phải có tổng số subscription, total loss và dữ liệu đủ để admin biết danh sách còn lại; không cắt `slice(0, 5)` mà không có `remainingCount`/pagination/expand affordance.
- POST suspend phải xác nhận trên snapshot impact mới. Nếu dữ liệu subscription thay đổi sau preview, request phải trả conflict/re-confirm hoặc tự recompute rồi yêu cầu người vận hành xác nhận lại; không coi preview cũ là sự thật.
- Auto-reactivation là business event do system actor thực hiện, phải audit tenant, `suspendedUntil` cũ, thời điểm chạy và kết quả; job retry không được tạo audit duplicate không cần thiết.

## Steps

1. Cập nhật auth contract trong `@pte/api-client`: thêm `mustChangePassword` vào `AuthResponse`, giữ request/response shape của `changePassword`, và bổ sung test mapping/refresh/session hydration.

2. Xây first-login guard cho tenant-web và vendor-web: sau login nếu flag true thì redirect tới change-password route; các protected routes không được bypass bằng deep link; sau success phải refresh/replace session state để flag false và redirect về route đích.

3. Bổ sung translated validation/error copy cho mật khẩu hiện tại/mật khẩu mới và trạng thái token; test login thường, first-login, refresh, logout, wrong password và retry sau API error cho cả hai app.

4. Mở rộng student report UI để hiển thị breakdown score + `appliedWeight`, tổng weight thực tế sau normalization và explanation ngắn gọn. Kiểm tra response cũ thiếu breakdown vẫn render an toàn, không tự tính lại từ template hiện tại.

5. Hoàn thiện suspension impact contract:

   - trả/hiển thị `planPublicId` cùng plan label nếu admin cần phân biệt các lane;
   - hiển thị total count và số item còn lại khi danh sách dài;
   - dùng duration chính xác hoặc format days/hours không under-report phần lẻ;
   - thêm `impactDigest`/version hoặc equivalent confirmation token;
   - fail closed khi preview chưa sẵn sàng hoặc digest đã stale.

6. Gắn system audit cho scheduled auto-reactivation, phân biệt manual actor và system actor. Test tenant bounded được mở đúng một lần khi job chạy lặp; tenant indefinite không bị job mở nhầm.

7. Review common component usage, i18n và accessibility của các màn hình bị chạm; không đổi default visual của `@pte/ui` để vá riêng một feature.

## Success Criteria

- Account có `mustChangePassword = true` không vào được workspace trước khi đổi mật khẩu ở tenant-web/vendor-web.
- Report hiển thị applied weight từ snapshot và không thay đổi khi template hiện tại đổi.
- Admin thấy đầy đủ số lượng/subscription impact, không bị mất thông tin vì preview chỉ hiển thị năm dòng.
- Confirm stale impact bị từ chối hoặc yêu cầu re-confirm; suspend không chạy trên dữ liệu admin chưa xác nhận.
- Auto-reactivation tạo audit có system actor, tenant và timestamp; retry không làm sai trạng thái.

## Quality and Testing State

- Quality gate: **approved** — report: `quality/phase-16-auth-report-and-suspension-operator-contract-quality-report.json`.
- Testing: **focused and full API regression passed** — report: `tests/phase-16-auth-report-and-suspension-operator-contract-test-report.json`; the default profile leaves opt-in PostgreSQL suites skipped, with all 61 supplemental tests passed separately in Phase 17.
- Evidence includes API auth/tenancy contracts, suspension stale-digest rejection, system audit on scheduled reactivation, API-client/UI typechecks, and tenant/vendor web test suites.

## Decision Record

- First-login gate áp dụng cho mọi account có `mustChangePassword = true`; trước khi đổi chỉ được vào change-password flow hoặc logout.
- Impact loss hiển thị chính xác theo ngày + giờ, không làm tròn xuống.
- Preview digest stale trả `409` và yêu cầu xác nhận lại, không tự silently apply impact mới.
