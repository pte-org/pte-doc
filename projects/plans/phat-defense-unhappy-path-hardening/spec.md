# Spec: Defense 1.1 unhappy-path hardening

**Date:** 2026-11-27
**Status:** Draft
**Nguồn:** `pte-doc/plans/reports/261127-defense-unhappy-path-brainstorm.md` (mã mục 1-x, 2-x, 3-x, 4-x, DS-xx tham chiếu tới báo cáo đó)

---

## Problem Statement

Theo đối chiếu code, chỉ khoảng 6/13 kịch bản ngoại lệ trong BM04 chạy đúng như kịch bản. Một số acceptance criterion
mới được chặn ở UI, nên hội đồng có thể vượt qua bằng cách gọi API trực tiếp. Mục tiêu là đạt ngưỡng cam kết
(4/4 main, ≥ 11/13 exception, 0 lỗi Critical/High) trước Defense 1.1.

---

## Quyết định đã chốt

- **Tự duyệt:** chặn hoàn toàn. Platform Admin cũng không được tự duyệt hay tự activate câu hỏi, template, rubric
  do chính mình tạo. Rubric chỉ được activate từ trạng thái PENDING.
- **Chấm câu objective trong kỳ thi:** giữ cách Host bấm Score mới chấm (chấm theo cohort). Chặn publish nếu còn câu
  objective chưa có điểm. Sửa F-13 và DS-03a thành "scored when the Host starts scoring" (BM04 lên v1.2).
  Practice giữ nguyên cách chấm tức thì.

---

## User Stories

- **[P1]** Là hội đồng, tôi gửi câu trả lời qua API sau giờ thi hoặc chỉnh đồng hồ máy thì bị từ chối.
  Accepted when: `answers/save` và `submit` sau `examEndTime + grace` trả lỗi nghiệp vụ; timer app dùng offset theo giờ server.
- **[P1]** Là Host, tôi không thể publish kết quả thiếu điểm.
  Accepted when: còn câu objective hoặc AI chưa có điểm thì publish bị chặn, và UI liệt kê học viên, task type và lý do (DS-03d).
- **[P1]** Là Academic Manager hoặc Platform Admin, tôi không thể tự duyệt hay tự activate nội dung của mình; template chưa duyệt thì không activate được.
  Accepted when: DS-01c đúng cho cả câu hỏi và rubric; activate template DRAFT chưa duyệt trả 409 (RF-19).
- **[P1]** Là staff đăng nhập bằng temp password, tôi chỉ gọi được API đổi mật khẩu và đăng xuất.
  Accepted when: mọi API khác trả 403 `PASSWORD_CHANGE_REQUIRED`.
- **[P1]** Là Host, tôi không thể thêm học viên vào lớp không ACTIVE (F-06).
- **[P1]** Là người demo, tôi chạy được DS-04c, DS-03c, DS-02e trên môi trường demo mà không phải restart.
  Accepted when: có công tắc làm AI lỗi bật/tắt được lúc đang chạy; lỗi đó được coi là retryable; đơn hàng hết hạn sau ≤ 2 phút theo cấu hình demo.
- **[P1]** Là học viên, session luyện tập quá hạn sẽ chuyển Expired, và trang progress chỉ đếm phần đã hoàn thành.
- **[P1]** Là auditor, mọi thao tác duyệt, payment, license redeem/revoke/grant, import, chọn điểm và publish đều có trong audit log (NFR-06).
- **[P2]** Màn hình bị khóa luyện tập hiện lý do (DS-04b); Host tạo staff hàng loạt (F-20); một attempt chỉ chạy trên một thiết bị;
  device check có kiểm tra network và screen; Alt+Tab debounce dùng đồng hồ monotonic.
- **[P2]** Option và blank count cho câu viết tay (RF-08); Host template không được tăng count hay timing; chặn PUBLISH bỏ qua CEFR.
- **[P3]** _(ghi nhận, không làm trước Defense)_ Gửi lại email kết quả, transactional outbox, khóa NFR-02, giới hạn chat history phía server, signed URL cho Cloudinary.

---

## Functional Requirements

1. FR-01: Server từ chối lưu câu trả lời và submit khi `now > examEndTime + grace` (grace cấu hình được, mặc định 30s). Có sweeper tự submit attempt quá hạn. (3-1)
2. FR-02: pte-app tính `serverOffset` từ header `Date` của response rồi dùng đồng hồ monotonic cho timer và debounce. (3-2, 3-3)
3. FR-03: `ReportPublishService` thêm blocker `OBJECTIVE_NOT_SCORED`. UI `ReportPublicationPanel` hiện danh sách blocker chi tiết. (3-8, DS-03d)
4. FR-04: `SecurityPolicy.canReviewAcademic/canPublishAcademic` bỏ admin override khi caller là tác giả. `RubricWorkflowPolicy` luôn kiểm tra self và chỉ cho activate từ PENDING. (1-3, DS-01c)
5. FR-05: Exam definition có `approvedAt/approvedBy`, bị xóa khi sửa. Chỉ activate khi đã duyệt. RETIRED không activate lại được. (1-1, 1-2, RF-19)
6. FR-06: Action `PUBLISH` của câu hỏi chạy cùng bộ kiểm tra với submitApproval (CEFR), hoặc bị bỏ. (1-4)
7. FR-07: JWT mang claim `pwd_change_required`. Filter chỉ cho qua change-password và logout khi claim này bật. (2-1)
8. FR-08: `ClassStudentService` assign/bulkAssign/transfer/merge ném lỗi khi lớp đích không ACTIVE. (2-2)
9. FR-09: Gọi `AuditLogService.record` trong: PayOS webhook (PAID), LicenseCodeRedeemer, LicenseCodeRevoker, UserAccountProvisioner (bulk và đơn), submit/reject/activate rubric, chọn điểm, publish. (1-14, 2-9)
10. FR-10: **Công tắc AI theo năng lực, lưu ở platform setting** (thay cho force-failure):
    `ai_question_generation_enabled`, `ai_exam_scoring_enabled`, `ai_practice_scoring_enabled`, `ai_chat_enabled`.
    - Giá trị hiệu lực = env bật (provider/key, `QUESTION_GEN_ENABLED`, `CHAT_AI_ENABLED`, ...) **AND** setting bật. Provider, model và key vẫn nằm trong env, không đưa lên DB hay UI.
    - Seed trong migration với mặc định `true` (prod giữ nguyên hành vi). Chỉ PLATFORM_ADMIN được đổi. Mỗi lần đổi ghi audit log. Admin UI có banner khi có năng lực bị tắt, và hiện "chưa cấu hình trên server" khi env tắt.
    - Kiểm tra trên server tại điểm dispatch hoặc chấm, không chỉ ở UI.
    - Khi tắt: sinh đề thì từ chối tạo job/preview (`AI_GENERATION_DISABLED`), item đang chạy được xử lý như provider unavailable.
      Chấm exam: Scoring failed, retryable. Chấm practice: Failed + Retry, giữ bản ghi âm. Chat: thông báo tạm ngưng, không trừ quota.
    - Exam và practice dùng chung provider và rubric (để điểm luyện tập có giá trị dự báo). Tách riêng công tắc và giới hạn:
      chuyển practice rate-limit và max-retries từ `application.yml` sang setting.
    - `AI_RUBRIC_SCORER_UNAVAILABLE` cũng được map thành lỗi retryable. (DS-01e, DS-03c, DS-04c)
    - P3: provider riêng theo kênh.
11. FR-11: Practice session đặt `deadlineAt` lúc begin. Sweeper chuyển session quá hạn sang EXPIRED. `PracticeProgressService` chỉ đếm COMPLETED. (4-1, 4-5)
12. FR-12: Kiểm tra `assertUnlocked` ở practice finish, discard và khi ký upload. (4-3)
13. FR-13: Env demo `BILLING_ORDER_PENDING_TTL_HOURS` cho phép TTL dạng phút, cộng cron cấu hình được. Thêm endpoint để Host hủy đơn PENDING. (DS-02e)
14. FR-14 (P2): `PracticeEntitlementResponse.reason`; `POST /users/bulk-staff`; ràng buộc attempt với deviceId; device check network/screen; validator option/blank count; Host template remove-only (count/timing).
15. FR-15: Gán lại class vào exam SCHEDULED không thêm học viên vào lớp sau thời điểm publish. (3-9)

---

## Non-Functional Requirements

- Security: 0 endpoint thay đổi dữ liệu thi/học mà chỉ được chặn ở UI, trong danh sách tấn công ở báo cáo mục 2.
- Audit: 100% các action trong FR-09 có dòng audit, kiểm bằng test.
- Không đổi response envelope và error code đã có (`docs/API_RESPONSE_SETUP.md`). Error code mới đặt trong `*Constants.java` của module.

---

## Success Criteria

- [ ] 13/13 kịch bản ngoại lệ chạy đúng kịch bản (đã sửa kịch bản DS-01b, DS-03a, DS-04a) trên môi trường demo.
- [ ] Bộ test Postman/curl gồm các tấn công 1-1, 1-3, 1-4, 2-1, 2-2, 3-1, 3-8, 4-1, 4-3: mỗi cái trả về đúng lỗi nghiệp vụ.
- [ ] Mỗi FR-01..FR-13 có ít nhất 1 test tự động; `.\mvnw.cmd -pl app test` 0 failure.
- [ ] BM04 v1.2: sửa F-13, DS-01b, DS-03a, DS-04a, DS-02a (one/both students), mục 8.1 (107 so với 111).

---

## Out of Scope

- Anti-cheat nâng cao (VM, quay màn hình), theo đúng Out of Scope trong BM04.
- Transactional outbox cho email, tối ưu khóa cho NFR-02 (ghi nhận cho sau Defense).

---

## Assumptions

- Demo chạy trên môi trường mà team chỉnh được env (staging RF-24 hoặc prod với env demo).
- Không reset DB. Migration mới là `V61+` và chỉ bổ sung (additive).

---

## Clarifications (đã chốt 2026-11-27)

- Demo chạy trên **prod VPS**. Công tắc AI theo năng lực (FR-10) và TTL đơn hàng (FR-13) là **platform setting** do Admin chỉnh lúc chạy,
  không cần restart. Công tắc AI mặc định `true`; TTL đơn mặc định 1440 phút (giữ hành vi cũ). Mỗi setting mới phải được seed bằng migration (đọc setting chưa có sẽ làm transaction thành rollback-only).
  Phase verify phải kiểm tra prod đã bật `PRACTICE_WEB_ENABLED` và `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, và đang dùng provider AI nào (không in giá trị env).
- Sửa câu đã qua trong bài thi (3-6): **giữ như hiện tại**. Phát tự quyết sau; không thuộc plan này.
- Một plan, chia phase theo workflow, mỗi phase ghi owner gợi ý theo BM04.
