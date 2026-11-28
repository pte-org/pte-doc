# Brainstorm: Unhappy path và điểm dễ bị tấn công khi demo Defense 1.1

**Date:** 2026-11-27
**Nguồn đối chiếu:** BM04 v1.1 (`SEP490_FA26SE182_R2_Commitment`), F-01..F-20, DS-01a..DS-04c, NFR-01..06.
**Phạm vi code:** `pte-api/app`, `pte-web/apps/{vendor-web,tenant-web}`, `pte-practice`, `pte-app`. Chỉ đọc code, chưa chạy thử.
**Phân loại:** ENFORCED (backend đã chặn) · UI-ONLY (chỉ UI chặn, gọi API trực tiếp vẫn qua) · MISSING (chưa có) · RACE (kiểm tra rồi mới ghi, không có khóa hoặc ràng buộc DB).

Đường dẫn Java viết tắt từ `pte-api/app/src/main/java/com/pte/`.

---

## 0. Kết luận nhanh

- **Chỉ có 2/13 kịch bản ngoại lệ chạy đúng như kịch bản hiện tại:** DS-01c (chỉ phần câu hỏi) và DS-02b/c/d. Ngưỡng cam kết trong BM04 là ≥ 11/13.
- **Các kịch bản phải sửa kịch bản hoặc sửa code trước khi demo:** DS-01b, DS-02e, DS-03a (bước chấm objective), DS-03d (thông báo lỗi), DS-04a (SST Pending), DS-04b (lý do khóa), DS-04c (AI lỗi rồi Retry).
- **Ba vùng hội đồng dễ đánh nhất:**
  1. Gọi API trực tiếp, bỏ qua UI: temp password, device check, hạn nộp bài thi.
  2. Phân tách quyền (tự duyệt) và audit log chưa đủ 100% như NFR-06 cam kết.
  3. Các trạng thái ghi trong BM04 nhưng code không tạo ra được: practice Expired, exam definition "Approved".

---

## 1. Kịch bản demo trong BM04 so với hành vi thực tế của code

| DS | Kịch bản ghi trong BM04 | Hành vi thực tế | Mức | Cần làm |
|---|---|---|---|---|
| DS-01b | Submit câu Repeat Sentence chưa có audio thì bị chặn, câu vẫn ở Draft | Không lưu được Draft khi thiếu audio. Validation chạy ngay lúc tạo (`itembank/internal/service/lifecycle/QuestionCreationService.java:101`). Code chặt hơn spec. | Kịch bản sai | Sửa kịch bản thành "Lưu câu RS thiếu audio thì bị chặn, hiện field thiếu", hoặc nới validation để Draft lưu được và chỉ chặn ở bước submit |
| DS-01c | M1 tự duyệt câu hỏi và rubric thì bị từ chối | Câu hỏi: bị từ chối đúng. Rubric: chỉ bị chặn khi version đang **PENDING**. Manager tự tạo DRAFT rồi bấm Activate thì **vẫn thành công** (`scoring/.../RubricWorkflowPolicy.java:22`, có comment "Managers may activate their own direct edits") | Cao | Demo phải đi đúng đường submit, hoặc chặn Activate từ DRAFT |
| DS-01d | Thiếu câu Describe Image thì chặn activate, báo số cần và số có | Đúng (`ExamDefinitionValidator.java:173-188`). Thông báo hiện key `DESCRIBE_IMAGE`, không hiện tên hiển thị | Thấp | Map sang tên hiển thị |
| DS-01e | AI lỗi thì không lưu gì; viết tay thì lưu Draft | Đúng cho run một câu. Với batch, các câu đã lưu trước khi lỗi vẫn giữ lại | Thấp | Demo bằng form một câu |
| DS-02b/c/d | Trùng mã số thuế / import vượt hạn mức / code đã dùng | Đúng | – | Lưu ý: mã số thuế chỉ được trim, nên `0101-234-567` vẫn qua (mục 2) |
| DS-02e | Replay webhook vẫn ra 1 subscription; đơn chưa trả thì "expires after its time limit" | Replay đúng. Đơn hết hạn sau **24 giờ**, cron chạy **mỗi giờ** (`application.yml:99-101`, `OrderExpirationService.java:42`). Không demo trực tiếp được. Trong thời gian đó, mua lại cùng plan bị 409 `ORDER_PENDING_EXISTS` và Host không có nút hủy đơn | Cao | Env demo: `BILLING_ORDER_PENDING_TTL_HOURS=0` và cron mỗi phút. Thêm endpoint để Host hủy đơn |
| DS-03a | "objective answers are scored at submit" | **Sai.** Lúc submit chỉ copy câu trả lời sang module chấm (`scoring/internal/listener/AttemptSubmittedIngestListener.java`). Chỉ chấm khi Host bấm Score (`ScoringCommandService.java:67-89`) | Cao (vi phạm F-13) | Chấm câu objective ngay trong listener, hoặc sửa F-13 và kịch bản |
| DS-03b | Offline 60s, Alt+Tab, submit offline không xong, Retry thì xong | Đúng (`pte-app/lib/core/sync/sync_engine.dart:162-181`). Thời gian "≤ 30s" của NFR-05 chưa đo | TB | Đo trước một lần |
| DS-03c | AI lỗi thì Scoring failed; chấm lại ra đúng 1 điểm | Đúng (dispatch token, `AiScoringDispatcher.java:42-48`). Cần chuẩn bị sẵn cách bật/tắt AI | TB | Xem DS-04c |
| DS-03d | Publish bị chặn và **nêu tên** điểm còn thiếu | API có trả chi tiết, nhưng UI chỉ hiện "N answer(s) without a final score" (`tenant-web/.../ReportPublicationPanel.tsx:53-58,177`) | Cao | Liệt kê học viên, task type và lý do |
| DS-04a | SST hiện Pending rồi tự ra điểm | Câu AI lưu ở trạng thái NONE. Học viên phải tự bấm "Chấm điểm" (`PracticeAnswerScoringRouter.java:42`) | TB | Sửa kịch bản thêm bước bấm Chấm điểm, hoặc tự dispatch khi submit |
| DS-04b | Bị khóa và hiện **lý do** | UI chỉ hiện chung "Practice locked". Response không có mã lý do (`pte-practice/features/practice/access-state.ts:14`) | TB | Thêm enum `reason` |
| DS-04c | AI lỗi thì Failed + Retry; bật lại AI thì Retry ra điểm | Với provider `stub`: lỗi là `AI_RUBRIC_SCORER_UNAVAILABLE`, bị map thành INTERNAL, **không retry được** và không có nút Retry (`PracticeScoringStateService.java:222-236`). Provider được chọn lúc khởi động, không có công tắc lúc đang chạy | **Rất cao** | Dùng provider thật rồi cắt mạng ra ngoài, hoặc thêm flag `scoring.ai.force-failure` bật/tắt được lúc chạy |

**Điều kiện môi trường bắt buộc kiểm tra trên prod trước demo:** `PRACTICE_WEB_ENABLED` và `PRACTICE_STRICT_ENTITLEMENT_ENABLED` mặc định là `false` (`application.yml:51,61`). Nếu prod chưa bật, mọi học viên sẽ nhận 403.

---

## 2. Unhappy path theo workflow (code)

### WF-01 Chuẩn bị tài nguyên

| # | Tấn công / tình huống | Thực tế | Mức |
|---|---|---|---|
| 1-1 | Manager gửi `ACTIVATE` lên template DRAFT chưa từng submit | Template lên ACTIVE mà không qua duyệt. `requireActivatable` nhận DRAFT (`ExamDefinitionApprovalWorkflow.java:173-178`); duyệt xong trả về DRAFT nên không phân biệt được bản đã duyệt hay chưa (RF-19). Sửa sau khi duyệt rồi activate lại không cần duyệt lại | **Cao** |
| 1-2 | Activate lại template RETIRED | Được phép. RETIRED không phải trạng thái cuối, trái với state path trong BM04 | TB |
| 1-3 | Platform Admin tự tạo câu hỏi rồi tự duyệt | Thành công (`shared/security/SecurityPolicy.java:73`, admin override). BM04 ghi "Authors cannot approve their own" mà không có ngoại lệ | Cao: hoặc giải thích, hoặc chặn |
| 1-4 | Manager `PATCH status {PUBLISH}` lên câu Exam-channel chưa có CEFR | Lên APPROVED, bỏ qua bước Pending và kiểm tra CEFR (`QuestionApprovalService.java:106-128`) | **Cao** |
| 1-5 | MC-Single chỉ có 2 đáp án; MC-Multiple chỉ có 1 | Lưu được và duyệt được. Kiểm tra số đáp án / số ô trống chỉ áp dụng cho draft AI (`QuestionValidationHelper.java:81-101`), trái với RF-08 | Cao |
| 1-6 | Write Essay đặt giới hạn 1–5000 từ; prompt dài vài MB | Lưu được: không có khoảng giới hạn theo template, không có `@Size` | TB |
| 1-7 | Host template chỉnh tăng số câu hoặc thời gian của một task type | Được phép. Code chỉ chặn *thêm* task type (`HostExamTemplateService.java:161,191`) | TB |
| 1-8 | Host lưu trọng số 150 | Lưu được, chỉ bị chặn lúc activate (`ExamDefinitionActivationValidator.java:180-203`) | Thấp |
| 1-9 | Archive câu hỏi khiến template ACTIVE thiếu câu | Archive không kiểm tra template, nên template đang dùng thiếu câu và generate exam sẽ lỗi | TB |
| 1-10 | Staff B sửa hoặc hủy rubric draft của Staff A; Manager reject version của chính mình | Thành công: không kiểm tra người sở hữu (`RubricVersionCommandService.java:39,66-81`) | TB |
| 1-11 | Hai Manager cùng duyệt hai revision của một câu | Đụng unique index và trả về **500** chung chung (không có handler cho `DataIntegrityViolation`) | TB |
| 1-12 | Batch AI chạy song song; preview liên tục | Quota mỗi ngày bị RACE (`GenerationQuotaGuard.java:35-40`). Kiểm tra trùng chỉ so với câu AI, không so với câu viết tay | Thấp |
| 1-13 | AI reviewer từ chối đến khi hết lượt gọi | Draft bị từ chối vẫn được lưu thành DRAFT (`GenerationPipeline.java:106`). Chấp nhận được vì vẫn cần người duyệt, nhưng nên gắn cờ | Thấp |
| 1-14 | NFR-06 "100% approvals logged" | Duyệt question, template, plan: có log. Submit/reject rubric: **không có** audit. Activate rubric ghi vào bảng riêng | Cao (vì cam kết 100%) |

### WF-02 Onboard tổ chức

| # | Tấn công / tình huống | Thực tế | Mức |
|---|---|---|---|
| 2-1 | Staff đăng nhập bằng temp password rồi gọi API bằng curl | Gọi được mọi API. "Phải đổi mật khẩu" chỉ là flag trong response và redirect ở UI (`tenant-web/.../RequireAuth.tsx:27-37`). Code không có filter nào chặn | **Cao** |
| 2-2 | Thêm học viên vào lớp INACTIVE (assign/transfer/merge) | Thành công. `ClassStudentService` không kiểm tra trạng thái lớp (đã xác minh). Vi phạm F-06 | **Cao** |
| 2-3 | Tạo Proctor/Examiner hàng loạt | **Chưa có** endpoint batch; UI tạo từng người. F-20 ghi "one by one or in a batch" | **Cao** |
| 2-4 | Host của tổ chức SUSPENDED đăng nhập | Đăng nhập và đọc dữ liệu được; chỉ các thao tác ghi có `assertTenantActive` mới bị chặn | Cao |
| 2-5 | Suspend staff đang đăng nhập | Access JWT còn dùng được tối đa 15 phút (`application.yml:15`) | TB: giải thích là JWT stateless |
| 2-6 | Mã số thuế `0101234567` rồi `0101-234-567` | Cả hai qua; không chuẩn hóa, không regex | TB |
| 2-7 | Sai mật khẩu 6 lần, mỗi lần đổi `X-Forwarded-For` | Lockout bị bỏ qua nếu API không đứng sau proxy tin cậy (`AuthController.java:111`). Trên prod có Caddy nên ít rủi ro hơn, nhưng cổng `8091` có lộ ra ngoài không? | TB |
| 2-8 | Đánh cắp refresh token rồi replay | Bị 401, nhưng không thu hồi cả family token | Thấp |
| 2-9 | NFR-06: payment, redeem/revoke license, import học viên/staff | **Không có** audit log (`PayOsWebhookService`, `LicenseCodeRedeemer/Revoker`, `UserAccountProvisioner`). DS-02a expected #6 ghi "payment, grant and import actions are in the audit log" | **Cao** |
| 2-10 | Import lỗi giữa chừng | Mỗi dòng ghi trong một transaction `REQUIRES_NEW`, nên lỗi sau khi validate để lại các dòng đã ghi. Trái với "Nothing is imported if…" | TB |
| 2-11 | File Excel rất lớn | Giới hạn 5MB chỉ ở UI; server không giới hạn số dòng (quota vẫn giới hạn số tài khoản tạo ra) | Thấp |
| 2-12 | Revoke code của gói giới hạn số học viên | `REVOKE_CAPACITY_UNSUPPORTED`. Cần giải thích, vì F-04 nói "revoking a used code cancels its subscription" | TB |

### WF-03 Tổ chức kỳ thi

| # | Tấn công / tình huống | Thực tế | Mức |
|---|---|---|---|
| 3-1 | Gọi `POST /attempts/{id}/answers/save` sau giờ kết thúc | **Vẫn lưu được** cho tới khi session CLOSED. Code ghi rõ "no server-side deadline" (`AnswerSubmitService.java:28-34`). Việc tự nộp khi hết giờ chỉ làm ở client | **Rất cao** |
| 3-2 | Chỉnh đồng hồ Windows lùi 20 phút | Timer client được thêm 20 phút (`timer_service.dart:78,107` dùng `DateTime.now()`), cộng với 3-1 nên server vẫn nhận bài | **Rất cao** |
| 3-3 | Lùi đồng hồ rồi Alt+Tab liên tục | Debounce tính ra số âm, nên mọi violation sau đó **bị bỏ qua** (`lockdown_service.dart:536-542`) | Cao |
| 3-4 | Gọi start attempt với `deviceCheckConfirmed:true` bằng curl | Bắt đầu được; device check chỉ là tự khai. App chỉ kiểm tra mic và loa, **không** kiểm tra network/screen như F-11 ghi | Cao |
| 3-5 | Một học viên đăng nhập trên 2 máy | Cả hai resume cùng một attempt và ghi đè câu trả lời của nhau; không ràng buộc thiết bị | Cao |
| 3-6 | Đang ở Listening câu 10 thì sửa câu 3 qua API | Được phép (`AttemptAnswerRecorder.java:76-80`). PTE thật không cho quay lại | TB: nghiệp vụ |
| 3-7 | Gửi incident sau khi đã submit | Được: không kiểm tra trạng thái (`AttemptEvidenceContextService.java:26-36`) | TB |
| 3-8 | Host không bấm Score mà publish luôn | Câu objective chưa có điểm **bị loại khỏi report** chứ không chặn publish (`ScoringReviewReadQueryService.java:218-222`). Học viên nhận email thiếu điểm Reading/Listening | **Rất cao** |
| 3-9 | Gán lại class vào exam SCHEDULED | Học viên vào lớp sau khi publish vẫn được thêm vào exam (`SessionClassSourceService.java:73`). Trái với F-10 | Cao |
| 3-10 | Exam mở/đóng "on time" | Trễ tối đa 60s (`fixedDelay`). Restart app thì bắt kịp được | Thấp: nói trước |
| 3-11 | Attempt CREATED nhưng không bao giờ bắt đầu (RF-18) | Bị rollback, không có bản ghi vắng mặt. RF-18 đã quá hạn 26/11 | TB |
| 3-12 | Ràng buộc trạng thái incident (RF-20) | Không có `CHECK` ở DB. Quá hạn | TB |
| 3-13 | RabbitMQ chết lúc publish | Mất email kết quả, không còn log và không có endpoint gửi lại (`NotificationDispatchService.java:157-160`). Mà học viên **chỉ** nhận điểm qua email | Cao |
| 3-14 | NFR-02 100 answers/s | Mỗi lần lưu câu trả lời khóa `PESSIMISTIC_WRITE` trên dòng `exam_sessions` (`ExamSessionRepository.java:32`), nên mọi lần lưu bị xếp hàng tuần tự | Cao khi chạy k6 |
| 3-15 | Replay câu trả lời cũ sau câu mới | Không có idempotency key; bản cũ ghi đè bản mới | TB |
| 3-16 | Cùng một form có lặp câu không? | App code chặn, nhưng không có unique ở DB (`exam_version_items`) | Thấp |

### WF-04 Luyện tập

| # | Tấn công / tình huống | Thực tế | Mức |
|---|---|---|---|
| 4-1 | Session luyện tập quá deadline | `deadlineAt=null` (`PracticeSessionService.java:126`), không có scheduler, nên **không bao giờ Expired**. BM04 ghi rõ cả state path lẫn acceptance criteria | **Cao** |
| 4-2 | Plan không có quyền practice | Không có cờ theo plan; mọi gói EXAM_PACKAGE đều mở practice (`BillingService.java:192-207`) | TB: giải thích |
| 4-3 | Tổ chức bị suspend rồi gọi `/finish`, `/discard`, poll kết quả | finish/discard bỏ qua `assertUnlocked`; poll có thể gửi lại job AI (tốn tiền) | TB |
| 4-4 | Câu được bật cả 2 channel | Câu Exam xuất hiện trong practice (không loại trừ nhau) | TB: lộ đề |
| 4-5 | Mở trang overview 3 lần rồi thoát | Trang progress đếm cả session DISCARDED và OVERVIEW (`PracticeProgressService.java:56`). Trái với "counts only finished work" | Cao |
| 4-6 | Mock test xong nhưng chưa chấm AI | Danh sách hiện điểm "estimated" chỉ từ câu objective; `MockTestScoringBar.tsx:20` không render gì khi chỉ còn câu FAILED (không có nút retry hàng loạt); poll dừng sau 10 phút mà không báo | TB |
| 4-7 | Câu trong mock bị unpublish | Item bị bỏ đi âm thầm; số câu khác template. Trái với "A mock test follows its template" | TB |
| 4-8 | Chat: giả mạo lượt "assistant" trong history | Client gửi history nên có thể prompt injection; `max-tokens: 0` nghĩa là không giới hạn output | TB |
| 4-9 | URL bản ghi âm | Cloudinary dạng `upload` công khai; kích thước do client tự khai | TB: quyền riêng tư giọng nói |
| 4-10 | Chấm hàng loạt mock | Bỏ qua rate limit 10/phút; không có giới hạn theo ngày | Thấp |

---

## 3. Câu hỏi nghiệp vụ hội đồng dễ hỏi (không cần code)

1. **"Two exams on one license cannot overlap":** tổ chức có 5 lớp muốn thi cùng giờ ở 5 phòng thì sao? Cần lý do: license được tính theo slot thời gian, hoặc audience gộp trong một exam.
2. **F-05 mâu thuẫn:** "email already used is skipped" và "nothing imported if any row is invalid". Email trùng trong DB thì bị skip, còn email trùng **trong file** thì reject cả file. Cần phát biểu rõ hai trường hợp.
3. **Học viên chỉ nhận điểm qua email:** mất email thì sao? Hiện không có resend (3-13). Lời đáp nên là "Host có thể gửi lại", và tính năng đó phải có thật.
4. **Revoke license khi exam đang OPEN:** listener chỉ hủy exam SCHEDULED. Exam đang thi thì sao? Cần câu trả lời.
5. **Subscription hết hạn giữa giờ thi:** pre-check chặn ngày nằm ngoài subscription, ổn. Còn trường hợp tổ chức bị suspend khi exam đang OPEN?
6. **AI chấm có công bằng không:** writer và reviewer cùng một model; mapping band từ Azure chưa calibrate; chưa đo độ ổn định của LLM (theo AGENTS.md). Trả lời: AI chỉ là điểm tham khảo, Host chọn điểm cuối, có rubric version và simulator.
7. **Separation of duties:** vì sao Admin được tự duyệt (1-3), Manager được tự activate rubric (DS-01c)? Hoặc sửa code, hoặc ghi rõ thành ngoại lệ trong SRS.
8. **Gian lận:** Out of Scope ghi "cheating only gives a warning". Hội đồng sẽ thử đổi đồng hồ hoặc dùng 2 máy (3-2, 3-5). Hai lỗi này **không** thuộc "advanced anti-cheat" mà là lỗ hổng toàn vẹn dữ liệu cơ bản.
9. **Quyền riêng tư:** bản ghi giọng học viên có URL công khai; thời gian lưu trữ bao lâu?
10. **PayOS trả tiền cho đơn đã hết hạn:** code chỉ log "manual refund". Quy trình hoàn tiền là gì, ai làm?

---

## 4. Lỗi trong chính tài liệu BM04

- DS-02a: bước 9 ghi "One Student signs in", expected #5 ghi "Both Students sign in".
- Mục 8.1: tổng số automated theo workflow là 27+32+36+12 = **107**, bảng ghi 111 (phần chênh 4 là NFR test, cần ghi rõ).
- WF-03: E2E test 2 cái, tự động 0 cái, trong khi RF-22 yêu cầu mỗi workflow một E2E.
- Exam definition state path ghi "Draft (approved)", nhưng code không có cờ đánh dấu đã duyệt (RF-19 chưa xong).
- F-11 ghi device check gồm "network, screen", app chỉ kiểm tra mic và loa.
- RF-18/19/20 (Phát, hạn 26/11) đã quá hạn.

---

## Ideas Explored

- **A. Chỉ sửa kịch bản demo cho khớp code.** Rẻ nhất, nhưng hội đồng vẫn đánh được qua API (3-1, 2-1, 3-8).
- **B. Fix theo mức ưu tiên P0/P1, phần còn lại chuẩn bị câu trả lời.** Đã chọn.
- **C. Fix toàn bộ cả 50+ mục.** Không khả thi trước Defense 1.1.
- **D. Gom các lỗi "bỏ qua UI" về một filter chung** (trạng thái người dùng/tổ chức, buộc đổi mật khẩu). Giải quyết 2-1, 2-4, 2-5 và 4-3 cùng lúc. Nên làm trong B.

## User's Direction

Rà đều cả 4 workflow. Đầu ra là báo cáo kèm danh sách fix làm input cho `/ck:plan`.

## Open Questions

- Prod hiện đã bật `PRACTICE_WEB_ENABLED` và `PRACTICE_STRICT_ENTITLEMENT_ENABLED` chưa? Provider chấm AI trên prod là gì?
- Demo chạy trên prod VPS hay trên staging (RF-24)? Điều này quyết định có đặt được env demo như TTL đơn hàng hay force-failure không.
- Admin tự duyệt và Manager tự activate rubric: giữ thiết kế rồi sửa SRS, hay sửa code?
- Câu objective: chấm lúc submit (sửa code), hay sửa F-13 thành "scored when the Host starts scoring"?
- Bài thi có được sửa câu trước không (3-6): bám PTE thật hay giữ như hiện tại?

## Risks

1. DS-04c và DS-02e không demo được nếu không chuẩn bị env hoặc công tắc. Hai kịch bản này đã chiếm 2/13 ngoại lệ.
2. Hội đồng mở Postman: 3-1/3-2 (nộp bài sau giờ) và 2-1 (temp password) là những lỗi dễ bị lộ nhất.
3. NFR-06 cam kết "100% logged" nhưng thiếu audit cho payment, license redeem/revoke, import, rubric submit/reject.
