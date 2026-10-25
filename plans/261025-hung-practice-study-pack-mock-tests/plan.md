# Plan: Study-Pack theo kỹ năng và Luyện đề (Full Mock Test)

Status: Ready
Date: 2026-10-25
Mode: Hard
Test: default
Owner/slug: Hung — `261025-hung-practice-study-pack-mock-tests`
Scope: `pte-api` (module `practice`; đọc `itembank`, `scoretemplate`), `pte-practice`, `pte-doc`
Related: [spec](./spec.md), [brainstorm](../reports/261025-hung-practice-mock-tests-brainstorm.md), plan trước [261024-hung-practice-timed-modes](../261024-hung-practice-timed-modes/plan.md)

## Mục tiêu

1. Study-Pack thành danh sách 4 kỹ năng; "Luyện tập" mở dialog chế độ cho **cả kỹ năng** và tạo phiên gồm mọi dạng bài của kỹ năng.
2. Trang Bài thi thử thành **danh sách đề luyện** 65 câu, tự ghép theo Score Template active từ pool PRACTICE, câu được ghim; làm theo nhịp TIMED từng câu, lưu/tiếp tục, có điểm ước lượng 4 kỹ năng.

Làm tiếp trên nhánh `hung/feat/practice-revamp` (cả `pte-api`, `pte-practice`, `pte-doc`), **trên các thay đổi chưa commit của plan 261024**. Không commit khi Hung chưa bảo.

## Scope challenge

### Đã có gì?
- Start API đã nhận nhiều `taskTypeCodes`; `PracticeSessionItemService.pickAndPin` chọn `questionCount` câu **mỗi dạng bài** bằng `PracticeQuestionPicker` (ưu tiên câu chưa gặp qua `findSeenSourceQuestionIds`), ghim nội dung qua `findPublishedQuestionsForPinning`, ghim timing qua `PracticeTimingService`.
- Engine TIMED từng câu, recorder, `PracticeModeDialog`, `ProgressRing`, review page (`/practice-tests/session/review`) đã có.
- Công thức điểm 10–90 có ở `reporting.internal.service.ScoreAggregationService` (FR-18: `10 + 80 × Σ(w×avgRaw/100)/Σw`, bỏ câu chưa SCORED) — **internal**, practice không import được.
- Score Template active: 22 dạng bài, tổng `minCount` = 65.
- `ExamGenerationService` lấy pool PUBLISHED+SHARED cho thi → **không dùng**.

### Tối thiểu là gì?
1. BE: V134 (`practice_sessions.kind`, `mock_test_id`; bảng đề + câu ghim), start theo `skillCode` (chia đều số câu), số câu/đã trả lời theo kỹ năng trong catalog.
2. BE: generate đề (admin), danh sách đề + lượt gần nhất, start/resume phiên MOCK_TEST từ câu ghim, điểm ước lượng trong review.
3. FE: Study-Pack + dialog kỹ năng + URL `?skill=`.
4. FE: danh sách đề, Bắt đầu/Tiếp tục/Làm lại, điểm ước lượng ở trang review.
5. Seed `-MockTests`, kiểm chứng, báo cáo.

Không làm: UI admin ở pte-web, đồng hồ tổng 2h15m, xếp hạng, dùng ExamBlueprint/pool EXAM, đổi `reporting`.

### Độ phức tạp
Hard — migration + dữ liệu phiên cũ, ranh giới Modulith, tính tất định của đề giữa học viên, idempotency start/resume, phiên 65 câu dài, 2 repo.

## Phases

- [x] Phase 1: Backend — V134, phiên theo kỹ năng, số câu theo kỹ năng — [phase-01-backend-skill-session-and-migration.md](./phase-01-backend-skill-session-and-migration.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: unit tests written alongside (allocation, skill start, skill stats); full suite pending]
- [x] Phase 2: Backend — đề luyện: generate, danh sách, phiên MOCK_TEST, điểm ước lượng — [phase-02-backend-mock-tests.md](./phase-02-backend-mock-tests.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: unit tests written alongside code; browser check pending in phase 5]
- [x] Phase 3: Frontend — Study-Pack theo kỹ năng — [phase-03-frontend-study-pack.md](./phase-03-frontend-study-pack.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: unit tests written alongside code; browser check pending in phase 5]
- [x] Phase 4: Frontend — Luyện đề — [phase-04-frontend-mock-tests.md](./phase-04-frontend-mock-tests.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: unit tests written alongside code; browser check pending in phase 5]
- [x] Phase 5: Seed, kiểm chứng và handoff — [phase-05-seed-verification-and-handoff.md](./phase-05-seed-verification-and-handoff.md) [quality: skipped_by_user; decision: user_confirmed_skip] — báo cáo: ../reports/261025-hung-practice-study-pack-mock-tests-report.md (một số TC chưa chạy)

## Phase → user story → tiêu chí (spec §6, §9)

| Phase | User stories | Tiêu chí §9 / FR |
|---|---|---|
| 1 | US Study-Pack (P1) phần BE | FR-01, FR-02; "Phiên kỹ năng Reading 10 câu" |
| 2 | US danh sách + làm đề (P1), US tiếp tục (P1), US tạo đề (P1), US điểm ước lượng (P2), US làm lại (P2) phần BE | FR-03..06; generate 3 đề, 2 học viên cùng đề, tiếp tục câu 6 |
| 3 | US Study-Pack (P1) | FR-07 (Study-Pack) |
| 4 | US danh sách/làm/tiếp tục đề, điểm ước lượng, làm lại | FR-07 (đề) |
| 5 | tất cả | FR-08 + mọi tiêu chí §9 (bằng chứng) |

## Kiến trúc quyết định

- **A1. Một bảng phiên cho cả 3 loại:** `practice_sessions.kind` (`TASK` | `SKILL` | `MOCK_TEST`, null = TASK cho dữ liệu cũ) + `mock_test_id` (FK nullable). Không tạo bảng phiên mới → dùng lại toàn bộ answer/draft/scoring/review/progress.
- **A2. Đề là dữ liệu ghim:** `practice_mock_tests` + `practice_mock_test_items` (question_public_id, task_code, section, order_index). Ghép một lần lúc generate; phiên MOCK_TEST đọc danh sách này, **không** gọi picker.
- **A3. Tất định:** generate dùng `PracticeQuestionPicker` với `Random(seed)`, seed = `sequence_no` (cố định, ghi vào bảng); "seen" = câu đã ghim ở các đề trước để giảm trùng (D6).
- **A4. Công thức ước lượng:** `PracticeScoreEstimator` thuần trong practice, chép công thức FR-18 (ghi nguồn trong Javadoc + test đối chiếu cùng bộ số). Không đổi `reporting`. Rủi ro lệch công thức ghi ở Risks.
- **A5. Chia số câu phiên kỹ năng:** `questionCount` của phiên SKILL là tổng; `perTask = floor(total / n)`, dư cộng cho các dạng đầu theo thứ tự catalog; dạng thiếu câu không bù sang dạng khác (giữ đơn giản), `totalItemCount` phản ánh số thật.
- **A6. FE định tuyến:** cùng route `/practice-tests/session` với `?skill=` hoặc `?mockTest=`; danh sách đề ở `/practice-tests`; catalog theo dạng bài vẫn ở Trang chủ.

## Risks

- **R1** Công thức ước lượng lệch với `reporting` khi FR-18 đổi → test đối chiếu + ghi nguồn; P3: tách công thức ra API công khai của `scoretemplate`.
- **R2** Câu ghim bị gỡ publish sau khi tạo đề → phiên bỏ qua câu đó (log WARN), itemCount < 65; danh sách đề hiển thị itemCount thật.
- **R3** Ngân hàng PRACTICE local ≤ 3 câu/dạng → nhiều đề trùng câu; seed `-PerTask 12` trước khi kiểm chứng.
- **R4** Phiên 65 câu: `begin` tạo 65 item + ghim nội dung trong một transaction giữ khoá phiên → đo thời gian (mục tiêu < 2 s local).
- **R5** Hash idempotency start phải gồm `skillCode`/`mockTestId`/`restart`, nếu không hai request khác nhau dùng chung key sẽ trả nhầm phiên.
- **R6** `kind` null ở phiên cũ → mọi chỗ đọc qua `effectiveKind()`.

## Red-team review (2026-10-25) — đã chấp nhận, áp vào các phase

Nguồn: agent `plan-reviewer` đối chiếu plan với code. Verdict ban đầu: BLOCK → đã xử lý như dưới.

| # | Phát hiện | Xử lý |
|---|---|---|
| B1 | `question_count` bị CHECK 1..50 (V133) và `@Max(50)` → đề 65 câu không insert được | V134 tạo lại CHECK: `<= 50 OR kind = 'MOCK_TEST'`; mock không đi qua `questionCount` của request (**đã làm, phase 1**) |
| H1 | Phân bổ 0 câu làm `pickAndPin` ném 422 | Bỏ qua dạng có phân bổ 0; chỉ lỗi khi không dạng nào có câu (**đã làm, phase 1**) |
| H2 | `resolveStartableTasks` không lọc RUNNABLE theo section | Thêm `runnableTaskCodesForSkill` (**đã làm, phase 1**); thứ tự theo catalog |
| H3 | `begin`/`createItemsIfNeeded` toàn-hoặc-không, và `timingsFor` hạ cả phiên về UNTIMED nếu thiếu 1 dạng | Phase 2: nhánh MOCK_TEST riêng, mỗi item tự dựng từ catalog task, bỏ qua + WARN từng item, timing theo item |
| H4 | Retry `sequence_no` trong cùng transaction không chạy (Postgres abort) | Phase 2: `pg_advisory_xact_lock` trước khi lấy `max(sequence_no)` |
| H5 | Câu bỏ qua làm điểm ước lượng cao giả | Phase 2: SKIPPED / chưa trả lời khi hoàn thành tính 0 điểm, ghi `skippedItemCount`; dùng template ghim `template_public_id` |
| H6 | Hai tab có thể tạo hai lượt đang làm của cùng đề | Partial unique index `uk_practice_sessions_active_mock_test` (**đã có trong V134**); restart: discard + flush trước khi insert |
| M1 | Câu ghim mất khi bị sửa (revision mới, `current=true`) | Ghi nhận rủi ro; item bị bỏ qua + WARN, `itemCount` hiển thị theo số thật; P3: ghim theo lineage |
| M2 | Pool check phải dùng cùng predicate với candidate query | Tiêu chí kiểm chứng dùng predicate `availableForPractice` thay vì chỉ `pool = PRACTICE` |
| M3 | `PracticeSessionResponseMapper` tính tổng trước begin sai cho SKILL/MOCK | **Đã làm, phase 1** (dùng `questionCount` khi kind ≠ TASK) |
| M4 | Tiêu đề phiên vẫn là tên sản phẩm | Phase 2: `session.title = mock.title` |
| M5 | Tuỳ chọn số câu thật là `[5,10,50]`, "Tất cả" = 50 | Phase 3: dùng đúng bộ này; với kỹ năng "Tất cả" = 50 câu chia đều |
| M6 | Seed không đếm được đề hiện có (token admin không gọi endpoint student) | Phase 2: thêm `GET` ở admin path; seed so sánh rồi generate phần thiếu |
| M7 | `estimatedOverall` trong danh sách cần thêm truy vấn | Ngân sách 3 truy vấn gộp |
| M8 | Đường dẫn FE: parser section ở `catalog-contracts.ts`, review ở `api.ts`; `api.ts` đã 300 dòng | Phase 3/4: `features/mockTests/api.ts` riêng, sửa `catalog-contracts.ts` |
| M9 | `useSessionLifecycle` thoát sớm khi `!taskCode` và chặn bằng `canStartPractice(task)` | Phase 3/4: viết lại request-key + guard cho skill/mockTest |
| L1–L5 | Kiểu cột/tên cột, `sourceQuestionPublicId`, lượt DISCARDED che điểm cũ, `@ConditionalOnProperty` cho admin controller, link "Xem tất cả" ở Home | Áp khi làm; lượt gần nhất = lượt **không bị DISCARDED**; admin controller dùng cùng property; chỉ PLATFORM_ADMIN cho generate (mock là dữ liệu toàn cục) |
