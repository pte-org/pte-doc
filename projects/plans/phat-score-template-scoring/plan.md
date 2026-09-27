# Plan: Score Template (V5) — Template Entity + Pinned Weighted Scoring (Plan A)
Status: 🟢 Done — all 7 phases complete, pending user's final review/approval
Date: 2026-09-16
Mode: Hard

## Overview

Đưa toàn bộ dữ liệu template điểm PTE (số câu, thời gian, cờ chấm AI, trọng số) đang nằm rải rác trong Java/JSON (`AiScoringTaskCatalog`, `task-skill-mapping.json`, `task-timing.json`) vào một entity `ScoreTemplate` versioned do platform admin quản lý qua module Spring Modulith mới `com.pte.scoretemplate`, pin nó vào `ExamSnapshot` lúc publish, và đổi luồng timing/chấm điểm/báo cáo để đọc từ template đã pin thay vì hardcode — mà **không** đụng tới luồng sinh đề ngẫu nhiên, blueprint thủ công, hay assign Class (đó là Plan B).

Đây là **Plan A** trong 2 plan tách từ spec `score-template-exam-generation`. Phạm vi: FR-01→FR-07, FR-14, FR-18→FR-20, phần pin-vào-snapshot của FR-13, và màn hình platform-admin quản lý template trên vendor-web. Không đụng tới FR-08→FR-12 (sinh đề ngẫu nhiên), FR-15→FR-17 (bỏ blueprint thủ công/SessionComposition, assign Class), tenant-web, hay P2 (bank-stock view) — những phần đó thuộc Plan B và sẽ có plan riêng.

## Phases

- [x] Phase 1: Score Template module — entity, migration V14 + seed V5, admin API — FR-01, FR-02, FR-03, FR-04, FR-05, FR-06
- [x] Phase 2: Pin template vào ExamSnapshot lúc publish — phần pin của FR-13
- [x] Phase 3: Attempt lấy timing từ template đã pin — FR-14
- [x] Phase 4: Scoring đọc scoringMethod từ template đã pin, xóa AiScoringTaskCatalog — phần scoring của FR-07
- [x] Phase 5: Reporting tính điểm có trọng số (FR-18/19/20), xóa task-skill-mapping.json/TaskSkillMappingConfig — phần reporting của FR-07
- [x] Phase 6: vendor-web — màn hình platform-admin xem/clone/sửa/kích hoạt template — UI cho P1 story 1 & 2
- [x] Phase 7: pte-app — bỏ Enabling skills, ẩn Overall khi không đủ 4 skill — FR-19/FR-20 phía hiển thị

## Research Summary

Không có `plan-researcher` report riêng cho Hard mode lần này; ngữ cảnh đến từ brainstorm report (`plans/reports/260916-score-template-exam-generation-brainstorm.md`) và khảo sát trực tiếp codebase (`pte-api/app`) trước khi viết plan này. Các quyết định đã chốt (không re-litigate):

- Module mới `com.pte.scoretemplate` (ngang hàng `itembank`), facade `ScoreTemplateService` chỉ có `getActive()`/`getByPublicId()` — các module khác (assessment, attempt, scoring, reporting) không bao giờ đụng repository của nó.
- Migration Flyway thật (`V14__score_template.sql`), không dùng `ddl-auto=update` — đúng cách project đang dùng cho `pte-api/app` (`ddl-auto: validate`, `flyway.enabled: true`, `V1`→`V13` hiện có). README mô tả `ddl-auto=update` là tài liệu cũ của `services/*` (microservices tiền-modulith), không áp dụng cho `app`.
- Pin template ở **snapshot** (không phải attempt) — 1 đề = 1 thang điểm cố định vĩnh viễn, khớp bảng V5 seed ACTIVE ngay từ đầu nên không có snapshot "mồ côi" template.
- Trọng số lưu `NUMERIC(5,2)` dạng phần trăm, "<1%" quy ước = 0.50; không bắt buộc tổng = 100 (FR-05).
- Khảo sát codebase phát hiện 1 xung đột không có trong bản brainstorm gốc: `config/task-skill-mapping.json` được **dùng chung** bởi `reporting.TaskSkillMappingConfig` (sẽ xóa) **và** `itembank.internal.config.PteTaskTypeSkillMapping` (điền `QuestionResponse.skills`, dùng cho tính năng gắn nhãn skill lúc soạn câu hỏi, không liên quan chấm điểm). Xóa thẳng file sẽ làm `itembank` crash lúc khởi động. Đã xác nhận `QuestionResponse.skills` không được vendor-web tiêu thụ ở đâu cả (chỉ khai báo type, không dùng) → Phase 5 sẽ gỡ luôn `PteTaskTypeSkillMapping`/`skills` khỏi `itembank` để có thể xóa file thật, thay vì chỉ xóa `TaskSkillMappingConfig` của `reporting`. Đây là mở rộng phạm vi tối thiểu, cần thiết để thỏa mãn đúng nghĩa đen success criterion "task-skill-mapping.json đã bị xóa; grep không còn tham chiếu" — được nêu rõ như một quyết định trong Phase 5, không âm thầm.
- `reporting.domain.enums.Skill` sẽ rút còn 4 giá trị communicative (bỏ 6 enabling skill) vì nguồn dữ liệu duy nhất của chúng (`TaskSkillMappingConfig`) bị xóa và spec liệt kê enabling skill là Out of Scope. **Quyết định user (2026-09-16):** xóa hẳn `ReportResponse.enablingSkills` và sửa `pte-app` (Phase 7). Hợp đồng mới: `communicativeSkills` chỉ gồm skill đã thi, `overall` null khi không đủ 4 skill. Field `QuestionResponse.skills` của itembank cũng bị bỏ hẳn (user chọn).
- FR-14 (timing): 22 dạng lấy `prepSeconds`/`responseSeconds` thẳng từ template đã pin (thay `task-timing.json`); riêng 5 dạng audio-prompt Speaking, `preListenSeconds` **ở lại** một file JSON rút gọn (không có trường này trong `ScoreTemplateItem` theo FR-02) vì cơ chế dựng `prepSeconds` động (nghe trước + audio thật + preRecord) vẫn giữ nguyên trong `SnapshotPinService`. `PERSONAL_INTRODUCTION` (UNSCORED, không có trong 22 dòng V5) tiếp tục lấy timing tĩnh từ file rút gọn đó — đây là một khoảng trống spec không nói rõ, được quyết định trong Phase 3 để giữ luồng blueprint thủ công hiện có (có thể chèn PI) không vỡ.
- FR-07 (scoring): đường đi ít xâm lấn nhất là copy `scoreTemplatePublicId` xuống tới `ScoringAnswer` (giống cách `taskType`/`payload`/`correctAnswerText` đã được copy từ `attempt` sang `scoring` hôm nay), rồi tra `scoringMethod` qua `ScoreTemplateService.getByPublicId()` thay vì 2 tập hardcode (`AiScoringTaskCatalog` + tập ẩn trong `ObjectiveScoringService.supports`).
- Không có Testcontainers/Postgres test harness trong `pte-api` hiện tại (chỉ Mockito unit test + `@DataJpaTest` H2 `create-drop`, không chạy Flyway trong test). "22 item khớp bảng V5" được test tự động bằng cách parse trực tiếp file `V14__score_template.sql` (không cần DB thật) + xác minh thủ công một lần bằng `docker compose up` để chắc Postgres áp migration thật và Hibernate `validate` pass — nêu rõ trong Phase 1, không âm thầm thêm Testcontainers (lệch convention hiện có).

## Dependencies

- Phase 2–5 phụ thuộc `ScoreTemplateService.getActive()`/`getByPublicId()` từ Phase 1.
- Phase 3 phụ thuộc cột `scoreTemplatePublicId` trên `ExamSnapshot` từ Phase 2.
- Phase 4 phụ thuộc cột `scoreTemplatePublicId` trên `PinnedExamSnapshot`/`SubmittedAnswerView` từ Phase 3.
- Phase 5 phụ thuộc cả Phase 1 (weights) và Phase 3 (tested-skills từ `PinnedItem.section`, qua `AttemptService`).
- Phase 6 phụ thuộc API admin của Phase 1.
- Phase 7 phụ thuộc hợp đồng `ReportResponse` mới của Phase 5 — chạy liền sau Phase 5.
- DB dev: user đồng ý reset Postgres local khi áp migration V14–V17 (không cần backfill).
- Không phụ thuộc Plan B — Plan A giữ nguyên `BlueprintService`, `SessionComposition`, tenant-web nguyên trạng.

## Risks

- HIGH: Xóa `config/task-skill-mapping.json` phá `itembank.PteTaskTypeSkillMapping` (dùng chung file) — mitigation: Phase 5 gỡ luôn phần dùng file đó trong `itembank` (đã xác nhận dead trên FE) trước khi xóa file.
- HIGH: Đổi công thức `ScoreAggregationService` là thay đổi hành vi chấm điểm của MỌI attempt cũ (không có dữ liệu thật để giữ tương thích, nhưng vẫn là core business logic) — mitigation: bộ unit test đối chiếu từng ví dụ số theo FR-18/19/20 trước khi coi Phase 5 là xong; không có rollback tự động nếu công thức sai, cần review kỹ trước khi merge.
- MEDIUM: `pinned_exam_snapshots`/`exam_snapshots`/`scoring_answers` thêm cột `NOT NULL` không default — nếu DB dev cục bộ đã có dữ liệu cũ, migration sẽ fail. Vì hệ thống chưa deploy, chấp nhận yêu cầu reset DB dev cục bộ 1 lần mỗi phase có migration mới (nêu rõ trong từng phase liên quan).
- MEDIUM: Không có Testcontainers → "test so sánh từng ô" của seed V5 chỉ tự động ở mức parse SQL text, chưa chứng minh Postgres thật chấp nhận cú pháp (đặc biệt partial unique index) — mitigation: bước xác minh thủ công 1 lần trong Phase 1 (`docker compose up`, xem log Flyway + Hibernate `validate`).
- LOW: 11 dạng RECOMMENDED giữ nguyên `responseSeconds` hiện có (theo spec); chỉ `WRITE_FROM_DICTATION` đổi 30s → 120s (FIXED theo V5).
- NOTED (red-team): "<1%" = 0.50 tạo nhiều ca làm tròn biên `.5` — đã chốt `RoundingMode.HALF_UP` ở Phase 5.
- NOTED (red-team): race `activate`/`cloneToDraft` — đã thêm pessimistic lock + dịch lỗi constraint thành 409 ở Phase 1; xác suất thấp vì chỉ platform admin thao tác.
- LOW: Số hiệu migration (V14/V15/V16/V17) giả định các phase chạy đúng thứ tự liệt kê — nếu thứ tự thực thi khác, phải kiểm tra lại migration mới nhất hiện có trước khi đặt tên file tiếp theo (đã nhắc trong từng phase).

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-09-16 19:40
**Phase in progress:** none — Phase 2 done, awaiting review gate before Phase 3
**Status:** Phase 2 implemented with TDD (red→green), full suite green (502/502), V15 hand-verified on real Postgres 17

### Decisions made this session (Phase 2)
- `SnapshotPublishService` giờ nhận thêm `ScoreTemplateService`; `publish()` gọi `getActive()` ngay sau kiểm tra blueprint rỗng, trước khi mutate gì — `NoActiveScoreTemplateException` lan truyền thẳng ra ngoài (không bắt), không lưu snapshot, không đổi `BlueprintStatus`. Test `publish_noActiveTemplate_throwsAndSavesNothing` xác nhận.
- `SnapshotResponse` thêm `scoreTemplatePublicId`/`scoreTemplateVersion` (cả 2, để admin/host xem đề đang dùng thang điểm nào); `SnapshotContentResponse` chỉ thêm `scoreTemplatePublicId` (đủ cho Phase 3 tra `ScoreTemplateService.getByPublicId()`) — đúng theo phase file.
- Migration `V15__assessment_score_template_pin.sql`: `ALTER TABLE exam_snapshots ADD COLUMN ... NOT NULL` không default — đã verify trên Postgres 17 tạm (dựng nối tiếp V1→V15 trên DB rỗng) áp thành công, không đụng volume dev thật.
- Side-effect bắt buộc phải sửa (không có trong "Files" của phase file nhưng là hệ quả biên dịch trực tiếp của việc đổi 2 record DTO): cập nhật 4 chỗ dựng `SnapshotResponse`/`SnapshotContentResponse` bằng constructor vị trí ở `SnapshotPinServiceTest` (attempt), `CompositionServiceTest`, `SessionLifecycleServiceTest` (session) — thêm placeholder `UUID.randomUUID()`/`1` cho 2 field mới, chưa assert gì trên chúng (Phase 3 sẽ dùng thật).
- `ModuleStructureTest` xanh — `assessment → scoretemplate` là cạnh một chiều hợp lệ (scoretemplate không phụ thuộc ngược lại).

### Next immediate action
Chờ user duyệt Phase 2 (Review Gate, `--hard`) rồi tiếp tục Phase 3 (attempt lấy timing từ template đã pin, FR-14).

---

**Last active:** 2026-09-16 20:20
**Phase in progress:** none — Phase 3 done, awaiting review gate before Phase 4
**Status:** Phase 3 implemented with TDD (red→green), full suite green (524/524), V16 hand-verified on real Postgres 17

### Decisions made this session (Phase 3)
- **Phát hiện lệch kiến trúc thật so với phase file, đã sửa có chủ đích:** phase file giả định `TaskTimingConfig.timingFor(taskType)` vẫn gọi được cho MỌI task type sau khi rút gọn JSON, chỉ các trường con (`prepSeconds`/`responseSeconds`/`preRecordSeconds`) là vắng mặt. Thực tế: 17/22 task type bị xoá hẳn KHÓA khỏi JSON (không chỉ field con), nên `timingFor()` (ném exception khi thiếu khoá) sẽ vỡ ngay cho các dạng tĩnh đã có trong template (vd `MC_READING_SINGLE`). Đã thêm phương thức mới `TaskTimingConfig.timingForIfConfigured(taskType)` (tra cứu không ném lỗi, trả `null` nếu vắng mặt) — `SnapshotPinService` dùng phương thức này khi `taskType` đã có trong template, chỉ dùng `timingFor()` (ném lỗi) khi template không có dòng cho `taskType` đó (trường hợp `PERSONAL_INTRODUCTION`). Không đổi record `Timing` hay logic parse — đúng ràng buộc phase file đặt ra.
- Nguồn ưu tiên timing mỗi `taskType` (đã cài đúng theo yêu cầu): template thắng nếu có dòng khớp — 17 dạng tĩnh đọc thẳng `prepSeconds`/`responseSeconds` từ template; 5 dạng audio-prompt đọc `preRecordSeconds` từ cột `prepSeconds` của template (quy ước seed Phase 1) nhưng vẫn đọc `preListenSeconds` từ `task-timing.json` (không có cột này trong `ScoreTemplateItem`). Chỉ `taskType` vắng mặt trong template (PI) mới fallback toàn bộ về JSON như cũ.
- `task-timing.json` rút còn `PERSONAL_INTRODUCTION` + `preListenSeconds` của 5 dạng audio-prompt — `TaskTimingConfigTest` viết lại hoàn toàn theo hình dạng mới (test cũ cho 7 dạng Listening placeholder + DESCRIBE_IMAGE bị xoá, thay bằng test xác nhận các dạng đó **không còn** cấu hình ở đây).
- `SnapshotPinServiceTest`: giữ nguyên gần như mọi test cũ (chỉ thêm mock `ScoreTemplateService` trả về template **rỗng item** mặc định trong `setUp()`) — nhờ vậy các test cũ tiếp tục đi qua nhánh fallback `taskTimingConfig` y hệt trước Phase 3, không cần viết lại logic test. Chỉ 2 test "dynamic prep" cũ (`repeatSentence_dynamicPrepTiming`, `respondToASituation_preservesPreListenValue`) phải thêm `stubTemplateItems(...)` vì bản chất 5 dạng audio-prompt giờ LUÔN cần có dòng template (bất biến FR-05 đảm bảo). Thêm 4 test mới cho hành vi ưu tiên nguồn timing + việc copy `scoreTemplatePublicId`.
- Hệ quả biên dịch bắt buộc phải sửa kèm (không nằm trong "Files" của phase file): `AttemptSummaryQueryServiceTest`/`SubmittedAnswerQueryServiceTest` cần dựng `PinnedExamSnapshot` thật (không còn null) cho `PinnedItem` trong test, và 4 lời gọi `new SubmittedAnswerView(...)` ở `ScoringIngestServiceTest` (module `scoring`, ngoài phạm vi Files của phase) cần thêm đối số `scoreTemplatePublicId` — dùng `UUID.randomUUID()` placeholder, Phase 4 sẽ dùng giá trị thật.
- `getScoreContext` trả `testedSections` = tập hợp `section` phân biệt của mọi `PinnedItem` trong **1 attempt cụ thể** (không phải toàn bộ snapshot) — đúng ý plan.md Dependencies đã ghi ("tested-skills từ PinnedItem.section").
- Migration `V16__attempt_score_template_pin.sql` verify thành công trên Postgres 17 tạm (áp nối tiếp V1→V16), không đụng volume dev thật.

### Next immediate action
Chờ user duyệt Phase 3 (Review Gate, `--hard`) rồi tiếp tục Phase 4 (scoring đọc `scoringMethod` từ template đã pin, xóa `AiScoringTaskCatalog`).

---

**Last active:** 2026-09-16 20:35
**Phase in progress:** none — Phase 4 done, awaiting review gate before Phase 5
**Status:** Phase 4 implemented with TDD (red→green), full suite green (528/528), V17 hand-verified on real Postgres 17

### Decisions made this session (Phase 4)
- Thêm enum cục bộ `com.pte.scoring.domain.enums.ScoringMethod` (4 giá trị, trùng tên với `scoretemplate.domain.enums.ScoringMethod`) thay vì import enum của `scoretemplate` — giữ `scoring` độc lập khỏi domain package nội bộ của module khác (`dto.response` là `@NamedInterface` công khai, `domain.enums` thì không), đúng quy ước "taskType/section luôn là String xuyên module" đã có sẵn trong codebase.
- `ScoringMethodResolver` mới (`scoring.internal.service`): tra `(scoreTemplatePublicId, taskType) → Optional<ScoringMethod>` qua `ScoreTemplateService.getByPublicId`, cache theo `scoreTemplatePublicId` bằng `ConcurrentHashMap` (an toàn cả vòng đời JVM vì template bất biến sau khi ACTIVE — không cần thư viện cache ngoài, đúng Risk đã nêu trong phase file).
- `ObjectiveScoringService.supports`/`AiScoringDispatcher.supports` đổi chữ ký sang nhận `ScoringMethod` đã tra sẵn (thay vì tự tra `taskType` qua tập hardcode) — `ScoringCommandService.requestScoring()` giờ là nơi DUY NHẤT gọi `ScoringMethodResolver`, tra đúng 1 lần mỗi answer rồi rẽ nhánh OBJECTIVE/AI_SPEECH/AI_TEXT/UNSCORED; UNSCORED và "không có trong template" đều giữ nguyên `PENDING`.
- `AiScoringJob` thêm field `scoringMethod` (String "AI_SPEECH"/"AI_TEXT", set lúc `dispatch()`) — `AiScoringWorker.callVendor()` switch thẳng trên field này, không còn tra lại theo `taskType` lúc consume message.
- **Đã xóa `AiScoringTaskCatalog.java` + test của nó**; xóa luôn mọi *tham chiếu tên lớp* còn sót trong comment (kể cả ở file khác) để thỏa đúng nghĩa đen success criterion của spec (`grep -r AiScoringTaskCatalog pte-api/app/src` → 0 kết quả, đã xác nhận bằng lệnh grep thật, không chỉ 0 lỗi biên dịch).
- `score()` của `ObjectiveScoringService` (switch theo `taskType`, thuật toán chấm từng dạng) **không đổi** — chỉ đổi cổng vào `supports()`, đúng yêu cầu "giữ nguyên luật chấm" của phase file.
- Migration `V17__scoring_score_template_pin.sql` verify thành công trên Postgres 17 tạm (áp nối tiếp V1→V17), không đụng volume dev thật.

### Next immediate action
Chờ user duyệt Phase 4 (Review Gate, `--hard`) rồi tiếp tục Phase 5 (reporting tính điểm có trọng số FR-18/19/20, xóa `task-skill-mapping.json`/`TaskSkillMappingConfig`, bỏ Enabling skills).

---

**Last active:** 2026-09-16 20:55
**Phase in progress:** none — Phase 5 done, awaiting review gate before Phase 6
**Status:** Phase 5 implemented with TDD (red→green), full suite green (527/527), pte-web (`vendor-web`/`tenant-web`/`api-client`) type-check sạch

### Decisions made này session (Phase 5)
- `ScoreAggregationService` viết lại hoàn toàn theo FR-18/19/20 dùng `BigDecimal`/`MathContext.DECIMAL64`, làm tròn cuối `RoundingMode.HALF_UP`. Group `ScoredAnswerView` theo `taskType`, tính `avgRaw`; mỗi dòng template chỉ đóng góp qua cột weight khác 0 tương ứng — 1 dạng như REPEAT_SENTENCE đóng góp độc lập cho cả SPEAKING lẫn LISTENING bằng cùng 1 `avgRaw` nhưng weight khác nhau (test `aggregate_oneTaskTypeContributesToTwoSkills_computesEachIndependently`).
- Bắt buộc dùng `AttemptService.getScoreContext()` → `ScoreTemplateService.getByPublicId(context.scoreTemplatePublicId())` — **không bao giờ** `getActive()`. Đã grep xác nhận trong service chỉ gọi `getByPublicId`, đúng yêu cầu "điểm attempt cũ không đổi khi kích hoạt template mới".
- `skillScores` map **chỉ chứa key của skill đã thi** (`context.testedSections()`), không còn set đủ 4 skill rồi đánh dấu insufficient — khớp đúng nghĩa "kết quả chỉ có skill thuộc section đã chọn" (FR-19). `overall` là `null` (không phải `insufficientData()`) khi thi thiếu 1/4 skill — phân biệt rõ "không áp dụng" và "chưa đủ dữ liệu".
- **Test hand-verify thật với số liệu V5 thật** (RA overall=4/speaking=9, DI overall=15/speaking=31): SPEAKING = 10+80×(9×100/100+31×50/100)/40 = 59 — khớp implementation ngay lần chạy đầu, không phải sửa lại công thức.
- Rút `reporting.domain.enums.Skill` còn 4 giá trị, bỏ `isCommunicative()`; `ReportResponse` bỏ hẳn `enablingSkills`; `ReportMapper` không còn filter theo communicative/enabling (skillScores map đã được `ScoreAggregationService` lọc sẵn).
- Gỡ `skills` khỏi `itembank` (Java: `ItembankService`, `QuestionMapper`, `QuestionResponse`; TS: `pte-web/packages/api-client/.../question/index.ts`) và xóa `PteTaskTypeSkillMapping` + `itembank.domain.enums.Skill` — đã grep xác nhận `.skills()`/`.skills` không còn nơi nào dùng trước khi xóa.
- **Xóa sạch mọi tham chiếu tên lớp còn sót trong comment** (`TaskSkillMappingConfig`, `PteTaskTypeSkillMapping`, `task-skill-mapping`) để `grep` trả về đúng 0 kết quả như success criterion của spec, không chỉ dừng ở "hết lỗi biên dịch" — cùng cách xử lý như Phase 4.
- Verify `tsc --noEmit` sạch cho cả `vendor-web`, `tenant-web`, `api-client` sau khi bỏ field `skills` khỏi `QuestionResponse` — khớp trực tiếp success criterion cuối của phase.
- Phase 7 (sửa `pte-app` Flutter cho hợp đồng `enablingSkills` đã xóa + `overall` nullable) **phải chạy ngay sau phase này** — chưa chạy, app hiện tại sẽ crash nếu gọi backend mới (đã cảnh báo từ khi lập plan).

### Next immediate action
Chờ user duyệt Phase 5 (Review Gate, `--hard`) rồi tiếp tục Phase 6 (vendor-web: màn hình platform-admin xem/clone/sửa/kích hoạt template).

---

**Last active:** 2026-09-16 21:15
**Phase in progress:** none — Phase 6 done, awaiting review gate before Phase 7
**Status:** Phase 6 implemented (FE, không có test tự động cho các trang admin dạng này — đúng như phase file đã xác nhận), `tsc --noEmit` + `eslint` + `next build` đều sạch cho `vendor-web`/`api-client`

### Decisions made this session (Phase 6)
- **Phát hiện quan trọng, không nằm trong phạm vi Phase 6 để sửa:** toàn bộ `packages/api-client` hiện có (question, authoring/blueprints, scoring/answers, quota...) đang dùng path kiểu `/api/{service}/...` sót lại từ kiến trúc gateway/microservices cũ đã bị gỡ (README ghi rõ "gateway was removed"). Path thật của monolith hiện tại KHÔNG có tiền tố `/api` hay tên service (vd `QuestionController` map ở `/questions`, không phải `/api/authoring/questions`). Nghĩa là nhiều màn hình admin hiện có (`questionbank`, `licensing`, `exams`...) nhiều khả năng đang gọi sai endpoint và sẽ nhận lỗi 404 khi chạy thật — đây là nợ kỹ thuật có sẵn từ trước, ngoài phạm vi Plan A/Phase 6. Module `scoretemplate` mới viết dùng đúng path thật `/score-templates` (đối chiếu trực tiếp `@RequestMapping` trong `ScoreTemplateController.java`), không lặp lại lỗi này — đúng cảnh báo đã ghi sẵn trong Risk của phase file.
- Không có `GET /score-templates/active` trên backend (Plan A chỉ mở HTTP cho `PLATFORM_ADMIN`, không có route "active" riêng) — `useActiveScoreTemplate()` suy ra từ `listScoreTemplates()` lọc `status === "ACTIVE"` phía client, không gọi thêm request.
- Sửa 1 lỗi thật do `eslint` (`react-hooks/set-state-in-effect`) bắt được: bản đầu của `ScoreTemplateEditorView` dùng `useEffect` để đồng bộ dữ liệu fetch về vào state sửa được — vi phạm khuyến nghị React mới. Đã tách thành 2 component (`ScoreTemplateEditorView` fetch dữ liệu, `ScoreTemplateEditorForm` nhận `template` qua prop, `key={template.publicId}`) khởi tạo state trực tiếp bằng `useState(() => ...)`, không còn effect nào — đúng pattern `BrandingEditor` đã dùng sẵn trong `tenancy`.
- Repo `vendor-web` **chưa có bộ test UI tự động** cho bất kỳ trang admin nào (đã grep xác nhận, kể cả `questionbank`/`tenancy`) — đúng như phase file dự đoán, nên không viết test mới cho `scoretemplate` (không lệch chuẩn hiện có). Verify bằng `tsc --noEmit`, `eslint`, và `next build` (đều pass) thay vì test tự động; luồng Clone → Edit → Activate qua UI thật **chưa được chạy tay** (cần dựng đủ Postgres+Redis+RabbitMQ+MinIO+pte-api+đăng nhập PLATFORM_ADMIN thật) — chấp nhận là giới hạn đã nêu rõ trong phase file, không phải bỏ sót.
- Đối chiếu lại `ScoreTemplateItemResponse`/`ScoreTemplateResponse`/`ScoreTemplateItemRequest`/`ReplaceScoreTemplateItemsRequest` Java thật với TS types vừa viết — khớp 100% tên field, không lệch chỗ nào.

### Next immediate action
Chờ user duyệt Phase 6 (Review Gate, `--hard`) rồi tiếp tục Phase 7 (pte-app Flutter: bỏ Enabling skills, ẩn Overall khi không đủ 4 skill) — phase cuối của Plan A.

---

**Last active:** 2026-09-16 21:35
**Phase in progress:** none — **Phase 7 done, toàn bộ Plan A (7/7 phase) đã hoàn thành**
**Status:** `flutter analyze` sạch, `flutter test` toàn bộ app **588/588 xanh**

### Decisions made this session (Phase 7 — phase cuối)
- TDD đầy đủ: viết lại `report_response_test.dart` và `report_screen_test.dart` trước, xác nhận đỏ (lỗi cast runtime / lỗi biên dịch), rồi mới sửa `ReportResponse`/`report_screen.dart`.
- `ReportResponse.overall` đổi thành `SkillScoreResponse?`; `report_screen.dart` dùng `if (overall != null) ...[...]` để ẩn toàn bộ mục Overall (tiêu đề + dòng điểm) khi `null` — phân biệt rõ với `sufficientData: false` (vẫn hiển thị nhãn "Insufficient data" như cũ).
- Xóa `enablingSkills` khỏi model, `report_screen.dart`, 2 hằng chuỗi trùng nhau (`report_strings.dart` và `app_strings.dart` — đã grep xác nhận `app_strings.dart` không còn nơi nào dùng trước khi xóa).
- Dọn sạch luôn 2 chỗ tên `enablingSkills` còn sót trong comment (model + tên 1 test case) để `grep -r "enablingSkills" pte-app/lib pte-app/test` trả về đúng 0 kết quả như success criterion yêu cầu — cùng cách xử lý như Phase 4/5.
- Test mới thêm: `overall: null` parse đúng; báo cáo 4 skill hiển thị Overall + không còn "Enabling skills" ở đâu cả (`find.textContaining('Enabling')` rỗng); báo cáo thi thiếu skill (`overall == null`) ẩn mục Overall nhưng vẫn hiện đúng các skill đã thi kèm nhãn insufficient data.
- Verify cuối: `flutter analyze` không có vấn đề gì; `flutter test` toàn bộ app (không chỉ module report) — **588/588 xanh**, xác nhận không phá vỡ tính năng nào khác.

## Tổng kết Plan A (7/7 phase)

Toàn bộ luồng: `pte-api` có module `scoretemplate` mới quản lý template V5 versioned (seed sẵn, admin CRUD qua vendor-web) → pin vào `ExamSnapshot` lúc publish → `attempt` lấy timing từ template đã pin → `scoring` lấy `scoringMethod` từ template đã pin (xóa `AiScoringTaskCatalog`) → `reporting` tính điểm có trọng số theo đúng FR-18/19/20 (xóa `task-skill-mapping.json`) → `pte-app` hiển thị đúng hợp đồng mới.

Số liệu kiểm thử cuối cùng:
- **Backend (`pte-api`):** `mvn test` **527/527 xanh**; 4 migration mới (V14–V17) đã verify tay trên Postgres 17 thật; `ApplicationModules.verify()` xác nhận không vi phạm ranh giới module.
- **Frontend admin (`pte-web`):** `tsc --noEmit` + `eslint` + `next build` sạch cho `vendor-web`/`tenant-web`/`api-client`.
- **Mobile (`pte-app`):** `flutter analyze` sạch; `flutter test` **588/588 xanh**.

Phát hiện quan trọng ngoài phạm vi Plan A (đã báo, chưa sửa): toàn bộ `pte-web/packages/api-client` cũ (question, blueprints, scoring, quota...) đang dùng path `/api/{service}/...` sót lại từ kiến trúc gateway đã gỡ bỏ, lệch với path thật của monolith hiện tại — nhiều màn hình admin có sẵn nhiều khả năng đang gọi sai endpoint.

### Code Review (Step 4, `--hard`)
Spawn `code-reviewer` độc lập review toàn bộ diff chưa commit của 7 phase, cả 3 codebase — **APPROVED**, 0 finding CRITICAL/HIGH/MEDIUM/LOW. Đã tự tay đối chiếu công thức chấm điểm, thứ tự ưu tiên timing, luồng tra `scoringMethod`, khóa race `activate`/`cloneToDraft`, và field JSON xuyên 3 codebase — không phát hiện sai lệch nào so với các phase file.

### Next immediate action
Không còn việc code. Chưa commit gì (theo yêu cầu không tự ý `git commit`) — chờ user xác nhận muốn commit khi nào.
