# Phase 01 — Scoring foundation, provenance và contracts

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)  
**Covers:** P1 Host/Examiner foundations; FR-02–04, 09–18 (data/API prerequisites).  
**Depends on:** Không.  
**Outcome:** scoring có model và facade đủ tin cậy để phân công, chấm Examiner, chọn nguồn và report mà không trộn các loại score.

## Mục tiêu

Thiết lập canonical data contract trong `scoring`. Chưa cần hoàn thiện UI. Giữ nguyên host `teacherScore` cũ; không đổi raw AI score thành Examiner score. AI eligibility tiếp tục bắt nguồn từ resolver với ScoreTemplate được pin.

## Việc cần làm

1. **Rà module boundary và hiện trạng trước khi sửa**
   - Đọc `ScoringAnswer`, `ScoringMethodResolver`, `ScoringReviewService`, `AiScoringWorker`, scoring provider interfaces/implementations và migrations mới nhất.
   - Kiểm tra dependency graph `scoring` ↔ `session`/`attempt`/`identity`/`enrollment`/`reporting`; không tham chiếu `internal` package của module khác.
   - Chụp lại hành vi cũ của objective, AI raw score và Host `teacherScore` bằng test hiện có để làm regression baseline.

2. **Bổ sung persisted provenance AI**
   - Mở rộng kết quả worker/domain để lưu danh tính provider/category (real vs stub), model/version nếu có, và thời điểm score được tạo cùng raw score.
   - Stub provider phải tự đánh dấu stub; không tin request, frontend hoặc cấu hình hiện tại để gán provenance ngược.
   - Legacy `rawScore` không có provenance được xem là không publishable cho source AI. Không backfill “real” chỉ vì runtime hiện đang cấu hình provider thật.

3. **Thêm mô hình scoring workflow**
   - Assignment/batch gắn tenant + session + attempt; enforce unique `(session, attempt)` và một Examiner tối đa.
   - Examiner score tách biệt theo answer, giữ examiner ID/tenant/attempt/session/submission time, integer 0–100 và trạng thái. Không dùng `teacherScore`.
   - Selected source là state per-answer (AI hoặc Examiner) cùng lịch sử audit append-only theo actor, scope, count, timestamp.
   - Xác định optimistic version/locking boundary để Host không đổi nguồn hoặc Examiner không ghi thêm score sau khi publication lock được bật ở Phase 05.
   - Không tạo foreign key liên module dựa trên ID; database uniqueness và service-level ownership là invariant.

4. **Migration và public facade**
   - Thêm migration Flyway kế tiếp số hiện hành; default an toàn với bảng/column mới và dữ liệu cũ.
   - Public facade tối thiểu cho: resolve AI eligibility/pool candidates; validate assignment ownership; examiner queue/detail work; host review source/score; reporting query/readiness input.
   - DTO public tách Host, Examiner và Reporting; Examiner contract không có AI score, selected source hay Host score.
   - Tránh public API tổng quát trả toàn bộ `ScoringAnswer` hoặc expose repository.

5. **Xử lý eligibility và ranh giới data**
   - Chỉ `AI_SPEECH`/`AI_TEXT` từ pinned ScoreTemplate mới vào Examiner work; objective và UNSCORED không vào assignment.
   - Kiểm tra khác biệt giữa attempt template pin và answer template pin; nếu hiện trạng lưu ở một phía, facade phải thể hiện rõ template/revision nào là nguồn chân lý và test migration/data consistency.

## Hợp đồng cần chốt khi implement

- IDs public, unique indexes, FK policy, state enums, version columns và Flyway naming theo conventions hiện hành.
- Provider category lấy từ implementation đáng tin cậy. Nếu một queue có thể đổi provider trong retry, provenance phải gắn với lần thực thi tạo ra result cuối cùng.
- Submission retry: identical examiner score trả cùng kết quả; score khác cho answer đã submit bị reject (không có reopen trong MVP).
- Assignment record chưa được UI xác nhận ở phase này; phase 02 sở hữu create/preview/confirm endpoints.

## Kiểm chứng và acceptance

- Migration chạy trên database rỗng và database có score hiện hữu; rawScore/teacherScore cũ không mất.
- Test resolver: pinned AI speech/text eligible; objective/UNSCORED ineligible; đổi catalog hiện hành không làm thay scoring method đã pin.
- Test AI worker: stub provenance được persist; provider thật provenance được persist; retry không ghi sai provenance.
- Test uniqueness, FK-independent IDs, range 0–100, immutable submitted score và selection audit model.
- Serialization test chứng minh Examiner DTO không chứa `rawScore`, Host `teacherScore`, selected source hoặc provider metadata nhạy cảm.
- Modulith verify không có dependency nội bộ/cycle.

**Acceptance:** các facade/persistence contracts được compile/test và migration tương thích dữ liệu cũ; chưa có queue UI hay publication behavior.

## Design Constraints

- Scoring sở hữu canonical score-work state; cross-module callers dùng public API.
- `rawScore`, `teacherScore`, Examiner score và selected score không dùng chung cột/ý nghĩa.
- AI eligibility dựa trên pinned ScoreTemplate, không hardcode task types.
- Provenance phải do scoring execution ghi; score thiếu hoặc stub provenance không thể được Host coi là AI source hợp lệ.
- Không đổi enrollment membership constraint trong phase này.
- Preflight: `ScoreTemplateService`/`AttemptService` xác nhận module contract đi qua root-package facade và DTO; `BaseEntity` là convention cho publicId/timestamps; `application.yml` dùng `ddl-auto: validate`, Flyway hiện đến V57. Giữ assignment/scoring state trong `scoring`, không truy cập repository `internal` xuyên module; migration mới phải tương thích các `raw_score`/`teacher_score` đã tồn tại.

## Quality and Testing State

- quality: not evaluated
- testing: not started
- Kế hoạch: unit/domain + worker/service tests; migration integration trên DB trống/có dữ liệu; serialization/security tests; modulith verification.
