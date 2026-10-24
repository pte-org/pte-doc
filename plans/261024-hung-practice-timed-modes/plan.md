# Plan: Practice có chế độ tính giờ / không tính giờ và trình ghi âm có sóng âm

Status: Ready
Date: 2026-10-24
Mode: Hard
Test: default
Owner/slug: Hung — `261024-hung-practice-timed-modes`
Scope: `pte-api` (module `practice`, facade nhỏ ở `itembank`, `attempt`, `media`), `pte-practice`, `pte-doc`
Related: [spec](./spec.md), [research](../reports/261024-hung-practice-timed-modes-research.md)

## Mục tiêu

Biến `pte-practice` từ "phiên thi thu nhỏ 1 câu + đồng hồ 60:00" thành app luyện tập thật:
học viên bấm một dạng bài → chọn **Tính giờ** hoặc **Không tính giờ** và số câu → vào thẳng
câu 1. Phiên có nhiều câu khác nhau (ưu tiên câu chưa làm), chế độ tính giờ đi đúng nhịp thi
(lấy từ Score Template đang active), trình ghi âm nghe lại / ghi lại được và có sóng âm thật.

Plan làm tiếp trên nhánh `hung/feat/practice-revamp` của cả hai repo (đang có thay đổi
chưa commit: V132, đăng nhập bằng tài khoản trung tâm). Không rebase/xoá các thay đổi đó.

## Scope challenge

### Đã có gì?

- `PracticeSessionService.start/begin` tạo phiên `OVERVIEW` rồi `IN_PROGRESS` với
  `deadlineAt = now + PRACTICE_TIME_LIMIT_SECONDS (3600)`; mọi check deadline đã coi `null` là
  "không hết hạn" (`isPastDeadline`, `PracticeMediaBindingService.isPastDeadline`).
- `PracticeSessionItemService.createItemsIfNeeded` tạo **1 item / dạng bài**, gọi
  `PracticeQuestionService.findPublishedQuestion` (luôn câu `ORDER BY publicId` đầu tiên) rồi
  `findPublishedQuestionForEvaluation` — 2 truy vấn mỗi item, trong lúc giữ khoá dòng session.
- Thời gian theo dạng bài đã có ở `ScoreTemplateService.getActive()` (V14 + V40 đổi tên) và
  `preListenSeconds` ở `config/task-timing.json` (đọc qua `attempt.internal.config.TaskTimingConfig`).
- Upload bản ghi đã có (`uploadPracticeRecording` → media `STUDENT_RESPONSE_AUDIO`, binding
  session/item). Chưa có đường lấy lại link phát bản ghi của chính học viên, chưa có lệnh lưu
  draft riêng (chỉ `save-and-exit`).
- FE: `PracticeSessionView.tsx` 501 dòng, `contracts.ts` 499 dòng (cả hai vượt chuẩn 300),
  `RecordingRenderer` chỉ có Start/Stop, chuỗi `RECORDING_TEXT` cứng tiếng Anh, không có Modal/Stepper.

### Tối thiểu là gì?

1. BE: V133 + trường `timingMode`/`questionCount` + bỏ deadline chung.
2. BE: chọn nhiều câu không trùng, ưu tiên chưa làm, đóng băng theo lô, ghim timing.
3. BE: link phát bản ghi của chính mình + lệnh lưu draft (để trạng thái "đã ghi" sống qua reload).
4. FE: tách view, thêm common `Modal`/`Stepper`/`ProgressRing`/`CountdownTimer` (vòng + số giây), contract mới.
5. FE: hộp chọn chế độ, luồng không tính giờ, trình ghi âm mới + sóng âm; `ProgressRing` thay
   `progress-empty-ring` ở Progress, gắn vào 4 ô kỹ năng ở Home và vòng câu x/y trong phiên (US-9).
6. FE: bộ điều phối nhịp tính giờ (vòng đếm ngược giai đoạn dùng `CountdownTimer`).
7. Kiểm chứng + handoff.

Không làm: Study-Pack, đổi chấm điểm/Review, đổi số liệu/logic Progress (US-9 chỉ đổi phần hiển thị vòng), ép thời gian ở server, `pte-app`,
đưa `@pte/ui` thành dependency thật.

### Độ phức tạp

Hard — chạm migration + dữ liệu phiên cũ, idempotency hash, ranh giới Modulith (practice →
itembank / scoretemplate / attempt / media), lock khi tạo item, Web Audio + autoplay policy,
và một state machine thời gian thực phía client.

## Phases

- [ ] Phase 1: Backend — V133, chế độ phiên, bỏ deadline chung — [phase-01-backend-session-mode-and-migration.md](./phase-01-backend-session-mode-and-migration.md) [quality: not evaluated; testing: not started]
- [ ] Phase 2: Backend — chọn câu, đóng băng theo lô, ghim timing — [phase-02-backend-question-selection-and-timing.md](./phase-02-backend-question-selection-and-timing.md) [quality: not evaluated; testing: not started]
- [ ] Phase 3: Backend — link phát bản ghi của chính mình và lưu draft — [phase-03-backend-recording-playback-and-draft.md](./phase-03-backend-recording-playback-and-draft.md) [quality: not evaluated; testing: not started]
- [ ] Phase 4: Frontend — tách `PracticeSessionView`, common components (Modal, Stepper, ProgressRing, CountdownTimer), `AppIcon` → MDI (`@mdi/js`), contract — [phase-04-frontend-foundation.md](./phase-04-frontend-foundation.md) [quality: not evaluated; testing: not started]
- [ ] Phase 5: Frontend — hộp chọn chế độ, luồng không tính giờ, trình ghi âm + sóng âm, ProgressRing ở Home/Progress/phiên — [phase-05-frontend-mode-chooser-and-recorder.md](./phase-05-frontend-mode-chooser-and-recorder.md) [quality: not evaluated; testing: not started]
- [ ] Phase 6: Frontend — bộ điều phối nhịp tính giờ — [phase-06-frontend-timed-phase-engine.md](./phase-06-frontend-timed-phase-engine.md) [quality: not evaluated; testing: not started]
- [ ] Phase 7: Kiểm chứng và handoff — [phase-07-verification-and-handoff.md](./phase-07-verification-and-handoff.md) [quality: not evaluated; testing: not started]

## Phase → user story → tiêu chí nghiệm thu (spec §7)

| Phase | User stories | Tiêu chí §7 |
|---|---|---|
| 1 | US-1 (trường request, bỏ 60 phút), US-8 (phiên cũ) | 1 (phần BE), 3 (không còn deadline), 8, 9 (mặc định chế độ, hash) |
| 2 | US-4, US-3/US-6 (timing ghim), US-1 (cờ TIMED trong catalog) | 2, 9 (chọn câu, timing ghim) |
| 3 | US-2, US-5 (nghe lại sau reload), US-3 (draft "đã ghi") | 5, 7 (phần BE) |
| 4 | US-8 (tách view, component chung), US-9 (P2: ProgressRing, CountdownTimer) | 9 (tsc/eslint/vitest) |
| 5 | US-1, US-2, US-5, US-7, US-9 (vòng ở Home, Progress, vòng câu x/y) | 1, 3, 5, 6, 7 |
| 6 | US-3, US-6, US-9 (vòng đếm ngược giai đoạn) | 4, 3 (không có đếm ngược ở untimed) |
| 7 | tất cả | 1–9 (bằng chứng) |

## Phụ thuộc và thứ tự

```text
P1 ──► P2 ──► P3 ──► (BE xong, rebuild docker app)
P1..P3 contract ──► P4 ──► P5 ──► P6 ──► P7
```

- P4 có thể bắt đầu song song với P2/P3 (phần tách view không đổi hành vi), nhưng bước
  "contract mới" của P4 cần tên trường đã chốt ở P1–P3.
- P5 cần P3 (link phát bản ghi, endpoint draft). P6 cần P5 (trình ghi âm, `PromptMedia`).
- Mỗi phase BE kết thúc với suite `practice` + `ModuleStructureTest` xanh; mỗi phase FE kết thúc
  với `npm run typecheck`, `npm run lint`, `npm run test:unit` xanh.

## Quyết định kỹ thuật chốt trong plan

- **D1 — `time_limit_seconds` NOT NULL:** giữ cột, phiên mới ghi `0` (= "không có giới hạn
  phiên"), V133 đặt `DEFAULT 0`. Không đổi `int` → `Integer` để tránh lan sang response/mapper.
  `PracticeSessionResponse.timeLimitSeconds`/`deadlineAt` và `PracticeCatalogResponse.timeLimitSeconds`
  giữ trên wire (giá trị `0`/`null`) để không phá client cũ; FE thôi đọc.
- **D2 — `question_count` null ở phiên cũ** = hành vi cũ (1 câu / dạng bài) khi `begin` một
  phiên `OVERVIEW` tạo trước V133.
- **D3 — TTL link đề:** `PRACTICE_PROMPT_MEDIA_TTL_SECONDS` thành hằng riêng `900` (đúng trần
  `SIGNATURE_TTL_SECONDS` của `CloudinaryMediaService`, giá trị lớn hơn vốn bị kẹp về 900).
  FE gọi lại `GET session` một lần khi `<audio>/<img>` báo lỗi tải.
- **D4 — draft:** thêm `POST .../items/{itemPublicId}/draft` (operation `SAVE_DRAFT`) thay vì
  dùng `save-and-exit` như lệnh lưu, vì FE xử lý `save-and-exit` như thoát phiên.
- **D5 — preListen:** thêm facade công khai ở gốc module `attempt` bọc `TaskTimingConfig`
  (không chép số, không đọc `internal` từ `practice`). Hiện không module nào phụ thuộc
  `practice` (media dùng port trong `shared`), nên practice → attempt/scoretemplate không tạo vòng.

- **D6 — ProgressRing (US-9, P2):** dựng lại hình học từ `C:\Users\Hung Pham\Downloads\pearson-inline-icons.json`
  (chỉ đọc: vòng 90/56/48/40 px, dày ~10/6/5/5 px, vòng 40 px 4 đoạn), SVG tự viết, màu bằng token
  (`--accent`, `--line`…), không tím Pearson `rgb(81,46,171)`, không chép markup. Không đổi API/logic
  Progress: vòng chỉ hiển thị số liệu đã có. Đã chốt (red-team #8): vòng tiến độ theo kỹ năng ở Progress
  dùng `empty` cho tới khi có spec dữ liệu theo kỹ năng; vòng answered/total đổi nhãn "Phiên gần nhất";
  ô kỹ năng Home = số dạng bài sẵn sàng / tổng của kỹ năng (xem P5).

## Risks

- **HIGH — Autoplay / activation:** cả `play()` của đề và `AudioContext.resume()` của recorder cần user
  activation; sau reload/resume dùng một cổng "Bắt đầu câu" cho mọi dạng Speaking (kể cả Read Aloud/Describe
  Image), `resume()` timeout quay về cổng. StrictMode chạy effect đôi → guard một-lần cho lần phát đề và lệnh tự ghi (P6).
- **HIGH — Phiên cũ có `deadline_at` 60 phút** bị `EXPIRED` ngay khi mở nếu V133 không xoá
  deadline của `OVERVIEW`/`IN_PROGRESS` (P1, có test chuỗi SQL).
- **HIGH — Trùng số Flyway:** kiểm số V cao nhất trên `origin/dev` ngay trước khi đặt tên
  `V133__...`; đổi số nếu nhánh khác đã dùng.
- **MEDIUM — `PracticeSessionView.tsx` ~501 dòng:** phải tách trước khi thêm tính năng (P4), nếu
  không P5/P6 sẽ vượt chuẩn 150/300 dòng.
- **MEDIUM — Kích thước WAV:** giữ trần 120 s (`MAX_RESPONSE_DURATION_SECONDS`); ở 48–96 kHz
  vẫn < 25 MB nhưng nên tạo `AudioContext({ sampleRate: 16000|24000 })` khi trình duyệt cho phép.
- **MEDIUM — CORS khi tải bản ghi để vẽ sóng:** URL ký `api.cloudinary.com/.../download` có thể
  không trả header CORS; khi `fetch` lỗi vẫn phát bằng `<audio src>` và ẩn sóng (P3 có bước spike).
- **LOW — Số liệu "theo kỹ năng" cho vòng Progress/Home:** `PracticeProgressEntry` không có section.
  Đã chốt (red-team #8): vòng kỹ năng `empty`, vòng "Phiên gần nhất" = answered/total, ô Home = ready/total
  dạng bài; số liệu thật theo kỹ năng để spec riêng.
- **LOW — Trần 500 ứng viên / dạng bài** thiên về UUID nhỏ nếu kho lớn hơn; ghi chú, chưa xử lý.
- **LOW — Hash idempotency đổi:** request `start` gửi lại cùng key từ trước deploy sẽ nhận 409;
  FE tạo key mới mỗi lần mở trang nên chấp nhận được.
- **LOW — Template thiếu dạng bài / không có template active:** TIMED bị vô hiệu với lời giải
  thích, UNTIMED vẫn chạy (P2).

- **MEDIUM — Lệch spec §4:** thiếu Web Audio thì không ghi được (WAV mã hoá từ `AudioContext`); chỉ đảm bảo
  "decode lỗi → ẩn sóng, vẫn phát". Ghi vào report P7.

## Rollout và kiểm chứng

- BE: `./mvnw -pl app test -Dtest=...` (Maven wrapper ở gốc `pte-api`) cho `com.pte.practice.*`, `com.pte.itembank.*`,
  `ModuleStructureTest`, `RouteContractTest`, rồi full suite ở P7.
- Rebuild container app sau P1–P3: `docker compose -f docker-compose.yml -f docker-compose.services.yml up -d --build app`
  (trong `pte-api`); kiểm log Flyway áp `V133` thành công trên DB local có dữ liệu phiên cũ.
- Seed nội dung: `pte-api/scripts/seed-local-practice-question-bank.ps1` (hiện `PerTask` tối đa 3;
  P7 nới để có ≥ 10 câu Repeat Sentence cho tiêu chí 2).
- FE: `npm run typecheck && npm run lint && npm run test:unit` trong `pte-practice`, chạy
  `npm run dev` (cổng 3014) và đi tay bằng tài khoản `pte-center.practice01`.
- Không push/merge/deploy trong cook nếu chưa được yêu cầu; báo cáo ở
  `pte-doc/plans/reports/`, commit theo từng feat, không commit `.superpowers`.

## Red-team review (2026-10-24)

Kết quả: REVISE → đã áp vào plan.md và các phase file (chưa commit).

| # | Mức | Phát hiện | Trạng thái | Áp ở |
|---|---|---|---|---|
| 1 | HIGH | Lưu draft qua `runMutation` đẩy màn hình sang submitting/error và đua với heartbeat → thêm `runBackgroundMutation` (chờ heartbeat, cập nhật version, không đổi phase, trả lỗi để recorder vào `SAVE_FAILED` và giữ blob) | ACCEPTED | P3 (test BE draft sau heartbeat), P4 bước 2 + test, P5 bước 8, P6 bước 5 |
| 2 | HIGH | Một cổng "Bắt đầu câu" phủ cả `play()` của đề và `AudioContext.resume()` (`audio-recorder.ts` ~44–46), kể cả Read Aloud/Describe Image; `resume()` timeout về cổng; guard một-lần cho lệnh tự ghi | ACCEPTED | P6 Design Constraints, bước 2/4/6, `timed-phase.test.ts` |
| 3 | MED | `durationSeconds` số nguyên trong [1,120] (`PracticeAnswerValidationService` ~180–187, `CloudinaryMediaService` ~192–194); TC4 đo độ dài thật từ WAV | ACCEPTED | P5 bước 7 + `audio-recorder.test.ts`, P6 bước 5, P7 TC4 |
| 4 | MED | Play-once với link đề hết hạn: claim guard sau khi `play()` resolve; refetch session trước item có link quá cũ; lỗi → refetch → play tính một lần | ACCEPTED | P5 bước 11, P6 Design Constraints + bước 4, `play-once.test.ts` |
| 5 | MED | Fixture/constructor `PracticeSessionServiceTest` (ctor 3 tham số, `practiceQuestionService` null) và wiring `PracticeQuestionPicker` | ACCEPTED | P2 bước 4, bước 7 |
| 6 | MED | "Thiếu Web Audio vẫn ghi/nghe được" sai → "decode lỗi → ẩn sóng, vẫn phát"; ghi lệch spec §4 vào report P7 | ACCEPTED | P5 Requirements + Success criteria, P7 bước 7, Risks |
| 7 | MED | Tên `preRecordSeconds` (không `prepSeconds`); javadoc `PracticeItemTimingResponse`: chỉ là preRecord của template (`PinnedItem.prepSeconds` của đề thi = preListen + audio + preRecord); test contract BE + FE | ACCEPTED | P1 (cột `pre_record_seconds`), P2 bước 8 + test, P4 bước 10 + test, P6 |
| 8 | — | Số liệu vòng theo kỹ năng ở Progress/Home | ACCEPTED — Hung chốt 2026-10-24 (trước đó PENDING-USER): vòng kỹ năng `empty` tới khi có spec dữ liệu theo kỹ năng; vòng answered/total đổi nhãn "Phiên gần nhất"; ô Home = số dạng bài sẵn sàng / tổng; không bịa số | P5 Design Constraints, bước 12, test; D6 |
| 9 | LOW | Template mất giữa `start` và `begin` → `begin` chuyển phiên sang UNTIMED (lưu vào phiên), không kẹt ở OVERVIEW | ACCEPTED | P2 bước 7 + test |
| 10 | LOW | Tự động hoá: `shouldMountTimedFrame` (tiêu chí 3), `seekFraction` (tiêu chí 6), test BE tiêu chí 8 (IN_PROGRESS cũ deadline null nhận answer; OVERVIEW cũ mode/count null begin ra 1 item) | ACCEPTED | P1 test, P2 test, P5 `waveform.test.ts`, P6 `timed-frame.test.ts` |

Thêm: phương thức playback mới ở media **không** gọi `requirePracticeBinding` (đi qua `assertCanUseResponseAudio`,
vốn đòi IN_PROGRESS + PENDING) — P3 bước 1 + test.

Quyết định khác của Hung (2026-10-24): giữ `Test: default` (không --tdd); TIMED không ghi âm hết giờ thì khoá ô
trả lời, học viên tự bấm Nộp (như P6); tên nhánh Hung tự cập nhật.

## Next command

```text
/ck:cook --hard plans/261024-hung-practice-timed-modes/plan.md
```
