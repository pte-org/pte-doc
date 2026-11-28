# Phase 5: Công tắc AI theo năng lực (FR-10)

**Owner gợi ý:** Quang (sinh đề, chấm exam), Hùng (chấm practice), Ninh (chat); vendor-web settings UI do người làm backend của từng năng lực phối hợp, Quang gom · **Ưu tiên:** P1 · **Phụ thuộc:** phase 01. Phải xong trước phase 06 (practice) và trước bước kiểm DS-03c, DS-04c, DS-01e ở phase 08.

## Overview

Bốn platform setting do PLATFORM_ADMIN bật/tắt lúc chạy, không restart: `ai_question_generation_enabled`, `ai_exam_scoring_enabled`, `ai_practice_scoring_enabled`, `ai_chat_enabled`. Giá trị hiệu lực = env bật AND setting bật. Provider, model, key vẫn ở env. Tắt công tắc cho kết quả theo từng năng lực (retryable, giữ bản ghi âm, không trừ quota). Rate-limit và max-retries của practice chuyển từ `application.yml` sang setting.

## Spec stories covered

- P1: công tắc AI bật/tắt lúc chạy, lỗi coi là retryable (FR-10; DS-01e, DS-03c, DS-04c).
- Một phần P1 audit: mỗi lần đổi công tắc ghi audit (đầu mối ở phase 07 kiểm tra tổng thể).

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Đường dẫn dưới `pte-api/app/src/main/` trừ khi ghi khác:

- `resources/db/migration/V64__ai_capability_switches.sql` — tạo mới (kiểm lại số cao nhất, hiện V60): seed bốn setting mặc định `true`, cộng setting cho practice rate-limit mỗi phút (giá trị 10) và practice max-retries (giá trị 2) để khớp mặc định `application.yml` dòng 53-54.
- `java/com/pte/billing/internal/service/PlatformSettingService.java` và `java/com/pte/billing/BillingSettingsService.java` — nơi đọc/ghi platform setting hiện có; thêm getter có fallback an toàn, cache ngắn nếu cần. Xác minh có nên đặt API công khai AI-capability ở module riêng thay vì nhồi `billing`; nếu có nơi sở hữu tốt hơn (ví dụ `shared`) thì dùng, chỉ để các module khác gọi qua public API.
- Tạo lớp public nhỏ (ví dụ `AiCapabilityGate`) cung cấp "enabled hiệu lực" cho 4 năng lực = env AND setting, và trạng thái "chưa cấu hình trên server". Đặt trong module sở hữu setting, expose qua API công khai.
- Sinh đề: `java/com/pte/itembank/generation/...` `itembank/internal/generation/controller/QuestionGenerationController.java` và service tạo job/preview/batch — từ chối tạo job/preview mới bằng `AI_GENERATION_DISABLED` khi tắt; worker `itembank/internal/generation/worker/QuestionGenerationWorker.java` coi item đang chạy như provider unavailable. Env hiện có: `QUESTION_GEN_ENABLED` (`application.yml` dòng 302).
- Chấm exam: `scoring/internal/messaging/consumer/AiScoringWorker.java` (dòng ~179) và `scoring/internal/service/ai/AiScoringDispatcher.java` — kiểm công tắc tại dispatch/chấm, trả Scoring failed retryable; giữ dispatch token để chấm lại ra đúng 1 điểm.
- Chấm practice: `scoring/internal/service/ai/PracticeAiScoringService.java` (dòng ~175), `practice/internal/service/PracticeScoringStateService.java` (dòng ~222-236 map lỗi) — công tắc tắt thì Failed + Retry, giữ bản ghi âm; đọc rate-limit/max-retries từ setting thay cho `application.yml`.
- Chat: `chat/internal/service/ChatService.java`, `chat/internal/controller/ChatController.java` — tắt thì trả thông báo tạm ngưng và không trừ quota; env hiện có `CHAT_AI_ENABLED` (dòng 70).
- `scoring/internal/constant/ScoringConstants.java` — `AI_RUBRIC_SCORER_UNAVAILABLE` (dòng 116) map thành lỗi retryable; mã lỗi/thông điệp công tắc tắt trong Constants của module từng năng lực (itembank, scoring, chat).
- `resources/application.yml` dòng 53-54 — giữ làm giá trị mặc định tham chiếu hoặc bỏ sau khi seed; ghi chú.
- Admin API: endpoint platform setting hiện có chỉ PLATFORM_ADMIN sửa; xác minh quyền, và ghi audit mỗi lần đổi (tái dùng `shared/audit/AuditLogService`; `PlatformSettingService` đã có audit, kiểm tra).
- Web (vendor-web): `pte-web/apps/vendor-web/features/commercialization/components/PlatformSettingsView.tsx` và `PlatformSettingRow.tsx` — nhóm công tắc AI, banner khi có năng lực tắt, nhãn "chưa cấu hình trên server" khi env tắt; chữ đặt trong file messages, component ≤ 150 dòng. Cần endpoint trả trạng thái hiệu lực (env + setting) cho banner.
- Provider khác nhau theo kênh là P3, không làm.

## Implementation steps

1. Migration: seed bốn công tắc (mặc định bật) và hai setting practice (rate-limit, max-retries) bằng giá trị đang chạy.
2. Dựng cổng "enabled hiệu lực" công khai: env AND setting, kèm trạng thái "chưa cấu hình trên server"; không bao giờ lộ giá trị env/secret.
3. Sinh đề: chặn tạo job/preview/batch mới bằng mã lỗi riêng, item đang chạy xử lý như provider unavailable.
4. Chấm exam và practice: kiểm công tắc ở điểm dispatch/chấm; map `AI_RUBRIC_SCORER_UNAVAILABLE` và lỗi công tắc thành retryable; practice giữ bản ghi âm, chấm lại ra đúng 1 điểm.
5. Chat: tạm ngưng với thông báo rõ, không trừ quota; practice rate-limit và max-retries đọc từ setting.
6. Chỉ PLATFORM_ADMIN đổi được; mỗi lần đổi ghi audit; endpoint trạng thái hiệu lực cho UI.
7. vendor-web: nhóm công tắc AI, banner khi có công tắc tắt, nhãn chưa cấu hình trên server.
8. Thử tay: tắt từng công tắc, xác nhận hành vi từng năng lực, bật lại rồi Retry ra điểm.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Test cổng enabled: env on/setting on, env on/setting off, env off/setting on, setting thiếu (fallback).
- Test sinh đề: tắt thì từ chối tạo job/preview với `AI_GENERATION_DISABLED`; item đang chạy chuyển unavailable (mở rộng test worker/pipeline trong `itembank/internal/generation/`).
- Test chấm exam: mở rộng test `AiScoringWorker` / dispatcher, Scoring failed retryable và retry sau khi bật lại ra 1 điểm.
- Test practice: mở rộng `practice/internal/service/PracticeScoringStateService` (tìm test), Failed + Retry giữ bản ghi âm; rate-limit và max-retries đọc từ setting.
- Test chat: tắt thì thông báo tạm ngưng, usage không đổi (mở rộng test trong `chat/`).
- Test quyền: chỉ PLATFORM_ADMIN đổi; non-admin bị 403; mỗi lần đổi có audit.
- Test seed (Postgres IT): đủ dòng setting sau migration.
- vendor-web: vitest cho nhóm công tắc và banner; chạy tsc, eslint.

## Design Constraints

- Migration additive V64 (kiểm số cao nhất trong `db/migration`, hiện V60); mọi setting mới seed trong cùng migration, mặc định bật để prod giữ nguyên hành vi. Đọc setting chưa seed làm transaction rollback-only.
- Provider, model, key không đưa lên DB hay UI; không in giá trị env.
- Kiểm tra ở server tại điểm dispatch/chấm, không chỉ UI.
- Thông điệp và mã lỗi trong `*Constants.java` của module sở hữu (itembank, scoring, chat); giữ envelope và mã lỗi hiện có.
- Cross-module chỉ qua public service API: practice, chat, itembank hỏi cổng công khai, không đọc bảng setting trực tiếp.
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp (ratchet architecture); `scoring/internal/service/ai` và `chat/internal/service` cần theo dõi.
- Mọi thời gian dùng `Clock` inject.
- `CODING_STANDARDS_WEB.md` cho vendor-web: chữ trong messages, dùng `Button` của `@pte/ui`.
- Restart docker app local sau backend.

## Risks

- Công tắc bị bật/tắt nhầm lúc demo: banner admin và audit; mặc định bật.
- Đọc setting mỗi lần chấm tăng tải DB: cache ngắn hoặc đọc theo lô, đo thử.
- Tắt công tắc làm job đang chạy treo: map unavailable rõ và có retry.
- Chuyển rate-limit/max-retries khỏi yml làm đổi hành vi: seed đúng giá trị cũ, test.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (2026-11-28: 1084 related tests green; BillingSettingsServiceAiSwitchTest re-stub fixed to doThrow (test bug, assertions unchanged); documented contract flips applied)

## Todo

- [ ] V64 seed 4 công tắc + 2 setting practice
- [ ] Cổng enabled hiệu lực (env AND setting) + endpoint trạng thái
- [ ] Sinh đề, chấm exam, chấm practice, chat theo ngữ nghĩa từng năng lực
- [ ] Map AI_RUBRIC_SCORER_UNAVAILABLE retryable
- [ ] Quyền PLATFORM_ADMIN + audit khi đổi
- [ ] vendor-web nhóm công tắc + banner + vitest/tsc/eslint
- [ ] Ratchet architecture, restart docker, thử tay từng công tắc

## Bổ sung sau red-team (2026-11-27)

- **[H6] Chốt nơi đặt cổng:** tạo public API `com.pte.shared.ai.AiCapabilityGate` (interface + enum `AiCapability`), implementation đọc
  `PlatformSettingService` qua public API của billing. Các module itembank/scoring/practice/chat chỉ phụ thuộc interface trong `shared`.
  Nếu kiểm ranh giới module (Modulith) không cho shared → billing, đặt implementation trong billing và export qua `BillingSettingsService`.
- **[H6] Rollback-only:** cổng đọc setting **ngoài transaction chính** (`Propagation.REQUIRES_NEW`, readOnly) hoặc qua cache nạp sẵn (TTL 10 giây).
  Có lỗi đọc thì **fallback = enabled** và log WARN; không bao giờ vì lỗi đọc mà tắt AI hay làm hỏng transaction chấm điểm.
- **[H6] Endpoint PATCH setting:** xác minh chỉ PLATFORM_ADMIN; 4 key AI chỉ nhận `true/false`; key TTL/grace/rate-limit nhận số nguyên trong khoảng cho phép. Có test 403 cho Manager/Host.
- **[H6] Tập dượt trên prod:** trước defense, chạy 1 lần chu trình "tắt → lỗi → bật → Retry ra điểm" cho DS-01e, DS-03c, DS-04c trên dữ liệu demo prod. Không thử lần đầu trước hội đồng.
