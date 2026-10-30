# Thiết kế lại UI/UX pte-practice (phần 1 giao diện + phần 2 kiểm tra dữ liệu + phần 3 race condition) — Implementation Plan

> Thứ tự thực hiện: Task 1–11, rồi 13–18, cuối cùng Task 12 (kiểm chứng).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mọi màn pte-practice theo một ngôn ngữ thiết kế (cột giữa ~840px, thẻ to bo góc) như design đã duyệt, kèm 2 bổ sung backend nhỏ (thống kê theo dạng bài, thông tin loại phiên).

**Architecture:** Backend chỉ thêm trường vào DTO có sẵn (catalog task, progress entry, session response) — không API mới. Frontend: token + lớp bố cục chung trong `app/globals.css`, logic trình bày thuần ở file `.ts` có test, các view chỉ ghép.

**Tech Stack:** Next.js 16 / React 19 / vitest / CSS thuần; Spring Boot 4 / JPA / JUnit 5 + Mockito.

**Spec:** `pte-doc/projects/plans/hung-practice-ux-redesign/design.md`

## Global Constraints
- **Tái sử dụng trước khi code UI (design §5):** mỗi task UI phải (1) dùng component trong `pte-practice/common/components` nếu có; (2) nếu không có, tìm trong `pte-web/packages/ui/src` và port vào `common/components` giữ nguyên tên + API props, ghi nguồn port; (3) chỉ tạo mới khi cả hai không có, đặt trong `common/components` theo phong cách API `@pte/ui`. Bước đầu tiên của mỗi task UI (6–11, 14, 16–18) là: liệt kê component cần dùng và nguồn của từng cái. Báo cáo Task 12 có bảng "dùng lại / port / tạo mới".
- Cột nội dung `max-width: 840px`, canh giữa, cho mọi trang (thay quyết định 1440px của plan ui-polish).
- Thẻ: bo 16px, padding 24px, viền `--line`; nút cao ≥ 44px.
- Ngưỡng màu điểm: `< 40` đỏ, `40–69` vàng, `≥ 70` xanh; chưa có điểm → "—" xám.
- Mọi chuỗi giao diện qua i18n `common/i18n/{types,en,vi}.ts`; không còn `UI_TEXT`/`RECORDING_TEXT` trong view đã sửa; không hiện mã thô (SPEAKING, ANSWERED, IN_PROGRESS).
- Không thêm thư viện; dùng lại `Modal`, `Toast`, `ProgressRing`, `AppIcon`, `ExamDateLine`, `DeviceCheckDialog`.
- File > 300 dòng phải tách. Dark mode giữ token xám (`#1e1e1e`).
- **Không commit** — Hung tự bảo khi nào commit (thay mọi bước commit bằng "không commit").

## Review Focus
1. Học viên chưa làm câu nào → mọi ô điểm hiện "—", không hiện "0%" đỏ (test ở Task 1 và Task 4).
2. Bấm Thoát khi bản ghi âm đang tải lên → chờ tải xong rồi mới lưu & thoát, không mất bản ghi (test ở Task 8).
3. Màn 390px: không cuộn ngang ở Trang chủ (hàng "Đề xuất" trượt trong khung) (kiểm ở Task 12).
4. Phiên đề luyện xong → không hiện "Luyện tiếp dạng này" (test ở Task 9).
5. Mục lịch sử phiên cũ (kind null, trước V134) → tên hiển thị như phiên một dạng bài, không lỗi (test ở Task 4).

---

### Task 1: Backend — thống kê theo dạng bài trong catalog student

**Files:**
- Modify: `pte-api/app/src/main/java/com/pte/practice/internal/dto/response/PracticeCatalogTaskResponse.java`
- Modify: `.../repository/PracticeSessionItemRepository.java`
- Modify: `.../service/PracticeSkillStatsService.java`
- Test: `.../test/.../service/PracticeSkillStatsServiceTest.java`

**Interfaces:**
- Produces: `PracticeCatalogTaskResponse` thêm 2 trường cuối `long answeredQuestionCount`, `Integer averageScore` (null = chưa có điểm); constructor tương thích cũ (giá trị 0, null); `withStats(long answered, Integer average)`.
- Produces: repository `List<Object[]> averageScoreByTaskCode(UUID studentPublicId)` → `[taskCode, avg]` với avg = trung bình `coalesce(aiScore, objectiveScore)` của item `ANSWERED` có điểm, mọi loại phiên.

- [ ] **Step 1: Test** `fillsAnsweredAndAverageScorePerTaskType`: catalog có `READ_ALOUD`, `REPEAT_SENTENCE`; repo đếm `READ_ALOUD=3`; avg `READ_ALOUD=71.6`. Kỳ vọng task READ_ALOUD `answeredQuestionCount=3`, `averageScore=72` (làm tròn HALF_UP); REPEAT_SENTENCE `0`, `null`.
- [ ] **Step 2:** `./mvnw -q -pl app -am test -Dtest=PracticeSkillStatsServiceTest` → FAIL.
- [ ] **Step 3:** Thêm trường + query JPQL `select item.taskCode, avg(coalesce(item.aiScore, item.objectiveScore)) ... where status = ANSWERED and coalesce(item.aiScore, item.objectiveScore) is not null group by item.taskCode`; `withCounts` điền thêm từng task.
- [ ] **Step 4:** Test PASS; `ModuleStructureTest` PASS.
- [ ] **Step 5:** Không commit.

### Task 2: Backend — loại phiên trong progress entry và session response

**Files:**
- Modify: `.../dto/response/PracticeProgressEntry.java`, `.../service/PracticeProgressService.java`
- Modify: `.../dto/response/PracticeSessionResponse.java`, `.../mapper/PracticeSessionResponseMapper.java`
- Test: `.../service/PracticeProgressServiceTest.java`, `.../mapper/PracticeSessionResponseMapperTest.java`

**Interfaces:**
- Produces: `PracticeProgressEntry` thêm cuối `String kind` (`TASK|SKILL|MOCK_TEST`, từ `effectiveKind()`), `String skillCode`, `String taskCode` (khi phiên chỉ có 1 dạng bài, ngược lại null), `UUID mockTestPublicId` (null nếu không phải đề).
- Produces: `PracticeSessionResponse` thêm `String kind`, `String skillCode`, `String taskCode` (cùng quy tắc).

- [ ] **Step 1: Test** `progressEntryCarriesTheSessionKind`: phiên SKILL READING → `kind="SKILL"`, `skillCode="READING"`, `taskCode=null`; phiên kind null 1 dạng `READ_ALOUD` → `kind="TASK"`, `taskCode="READ_ALOUD"`. Mapper test tương tự cho session response.
- [ ] **Step 2:** Chạy 2 test → FAIL.
- [ ] **Step 3:** Thêm trường; `mockTestPublicId` lấy qua `PracticeMockTestRepository.findById(session.getMockTestId())` gom một lần cho cả trang progress (không N+1).
- [ ] **Step 4:** Test PASS.
- [ ] **Step 5:** Không commit.

### Task 3: Frontend — token và lớp bố cục chung

**Files:**
- Modify: `pte-practice/app/globals.css`

**Interfaces:**
- Produces lớp CSS: `.page-column` (max-width 840px, canh giữa, gap 24px), `.card` (bo 16px, padding 24px, viền), `.card-divider`, `.chip` (nền xám, icon + số), `.button-outline`, `.hint-strip` (nền tím nhạt + icon), `.score-badge` + `.score-badge-low|mid|high|none`, `.carousel` (scroll-snap ngang, thẻ 46% để thẻ thứ 3 ló ra; ≤ 480px thẻ 85%).

- [ ] **Step 1:** Thay `.main-content` về `width: min(100%, 840px)`; thêm các lớp trên; xoá lớp bố cục 1440 không còn dùng.
- [ ] **Step 2:** `npx tsc --noEmit && npx eslint features common app` → 0 lỗi.
- [ ] **Step 3:** Không commit.

### Task 4: Frontend — hàm trình bày thuần

**Files:**
- Create: `pte-practice/features/practice/presentation.ts`, `presentation.test.ts`

**Interfaces:**
- Produces: `scoreTone(score: number | null): "none" | "low" | "mid" | "high"`; `formatScore(score: number | null): string` ("—" hoặc "72%"); `skillKey(code: string): TranslationKey` (`skills.speaking`…); `itemStatusKey(status): TranslationKey`; `sessionDisplayName(entry: { kind: string | null; skillCode: string | null; taskCode: string | null; title: string; totalItemCount: number }, taskName: (code: string) => string, t): string`.

- [ ] **Step 1: Test:** `scoreTone(null)="none"`, `scoreTone(0)="low"`, `39→low`, `40→mid`, `69→mid`, `70→high`; `formatScore(null)="—"`, `formatScore(0)="0%"`; `sessionDisplayName` — MOCK_TEST → `title` ("PTE Academic Full Mock Test 1"); SKILL READING 10 câu → "Luyện Đọc · 10 câu"; TASK READ_ALOUD → "Read Aloud · 10 câu"; kind null + taskCode READ_ALOUD → giống TASK; kind null + taskCode null → `title`.
- [ ] **Step 2:** `npx vitest run features/practice/presentation.test.ts` → FAIL.
- [ ] **Step 3:** Cài đặt; i18n thêm `presentation.skillPractice` ("Luyện {skill}") và `presentation.questions` ("câu").
- [ ] **Step 4:** Test PASS.
- [ ] **Step 5:** Không commit.

### Task 5: Frontend — contract cho trường mới

**Files:**
- Modify: `features/practice/catalog-contracts.ts`, `features/practice/contracts.ts` (progress entry), `features/practice/session-contracts.ts`
- Test: `features/practice/contracts.test.ts`

**Interfaces:**
- Consumes: Task 1, 2.
- Produces: `PracticeCatalogTask.answeredQuestionCount: number`, `.averageScore: number | null`; `PracticeProgressEntry.kind/skillCode/taskCode/mockTestPublicId: string | null`; `PracticeSession.kind/skillCode/taskCode: string | null`.

- [ ] **Step 1: Test:** parser đọc đủ trường; thiếu trường → 0 / null; `averageScore` không phải số → null.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** Không commit.

### Task 6: Trang chủ

**Files:**
- Create: `features/home/recommendations.ts`, `recommendations.test.ts`, `features/home/RecommendationCarousel.tsx`, `features/home/SkillGroups.tsx`
- Modify: `features/home/HomeView.tsx`
- Delete khi không còn dùng: `features/catalog/SkillTaskList.tsx`

**Interfaces:**
- Consumes: Task 3 lớp CSS, Task 4 `scoreTone/formatScore`, Task 5 trường mới, `api.listMockTests()`, `api.getProgress()`.
- Produces: `buildRecommendations(mockTests: MockTest[], entries: PracticeProgressEntry[], taskName, t): Recommendation[]` với `Recommendation = { id; title; description; itemCount: number | null; minutes: number | null; progress: { done: number; total: number }; action: "continue" | "start"; href: string }`; tối đa 6; thứ tự: phiên TASK/SKILL đang dở (mới nhất trước) → đề đang dở → đề chưa làm theo số thứ tự.

- [ ] **Step 1: Test** `buildRecommendations`: 1 phiên SKILL IN_PROGRESS 4/10 + đề 1 IN_PROGRESS + đề 2 chưa làm → thứ tự [phiên SKILL (action continue, minutes null, mô tả "Đang làm dở · 4/10 câu"), đề 1 (continue), đề 2 (start, minutes 135)]; 8 nguồn → cắt còn 6; phiên COMPLETED không vào.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** `HomeView`: thẻ đầu (logo tròn, tên, `ExamDateLine`, lưới 2×2 thẻ thiết bị có viền với dòng "✓ Đã kiểm tra"/"Kiểm tra ngay", `.hint-strip` ở đáy) → "Đề xuất cho bạn" + "Xem tất cả" → `/practice-tests` → `RecommendationCarousel` → "Kỹ năng" + "Xem tất cả" → `/study-pack` → `SkillGroups` (mỗi nhóm: tiêu đề + "N câu trả lời" + `ProgressRing answered/practiceQuestionCount`; dòng dạng bài: icon, tên, "N câu trả lời", `.score-badge`, mũi tên → `openFor(task)`) → dòng trung tâm.
- [ ] **Step 6:** tsc + eslint + vitest → xanh. **Step 7:** Không commit.

### Task 7: Luyện đề và Study-Pack theo kiểu thẻ chung

**Files:** Modify `features/mockTests/MockTestListView.tsx`, `features/studyPack/StudyPackView.tsx`, `app/globals.css`

- [ ] **Step 1:** Thẻ đề dùng `.card` + `.chip` + nút đặc/viền như `RecommendationCarousel` (cùng hành vi hiện tại). Study-Pack dùng `.card`, `.hint-strip` cho dải tóm tắt.
- [ ] **Step 2:** tsc + eslint → 0 lỗi. **Step 3:** Không commit.

### Task 8: Màn làm bài

**Files:**
- Create: `features/practice/session/ConfirmDialog.tsx`, `features/practice/session/useLeaveGuard.ts`, `useLeaveGuard.test.ts`
- Modify: `features/practice/session/SessionTaskView.tsx`, `features/practice/PracticeSessionView.tsx`, `features/practice/renderers/RendererTypes.ts`, `features/practice/renderers/SpeakingRecorder.tsx`

**Interfaces:**
- Produces: `TaskRendererProps.onActivityChange?: (busy: boolean) => void` (recorder báo true khi `recording|uploading`); `shouldWarnOnLeave(busy: boolean): boolean`; `useLeaveGuard(busy: boolean): void` (gắn/gỡ `beforeunload`); `ConfirmDialog({ open, title, message, confirmLabel, onConfirm, onCancel })`.
- Hành vi: Thoát → ConfirmDialog → nếu recorder bận thì chờ `busy=false` (tối đa 30s, quá thì toast lỗi và giữ màn) → `saveAndExit`. Bỏ qua → ConfirmDialog → `skip`.

- [ ] **Step 1: Test** `shouldWarnOnLeave(true)=true`, `false=false`; `useLeaveGuard` gắn listener khi busy, gỡ khi hết busy (dùng `window.addEventListener` spy).
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** Bố cục theo khung phòng thi pte-app (design §4.4): theo ảnh phiên học Pearson (design §4.4): route `app/(student)/practice-tests/session` dùng **layout riêng không sidebar/thanh trên app** (`StudentShell` bỏ khung khi pathname bắt đầu bằng `/practice-tests/session`, vẫn giữ provider và kiểm tra đăng nhập; không dùng Fullscreen API). Tạo `features/practice/session/SessionHeader.tsx` (trái: tên phiên `sessionDisplayName` + dòng phụ kỹ năng; phải: "Phần {p} / {P}", "Câu {n} / {N}", đồng hồ khi tính giờ, nút viền "Tạm dừng phiên" → xác nhận → lưu & thoát), `SegmentedProgress.tsx` (`segments: { done: boolean; current: boolean }[]`; phần = nhóm item liên tiếp cùng `section`), `SessionFooter.tsx` ("Bỏ qua" trái có xác nhận; nút viền "Tiếp theo ›" phải = nộp), `PromptAudioPlayer.tsx` (nút play tròn + `AudioWaveform` peaks từ `usePromptPeaks(url)` có fallback sóng giả lập + `0:00 / 1:24`; giữ nguyên hợp đồng phát-một-lần của chế độ tính giờ), `EditorToolbar.tsx` (Copy / Cut / Paste qua Clipboard API trên textarea bài Viết) + dòng "Viết từ {min}–{max} từ để nộp câu trả lời", `AudioPlaybackCheckDialog.tsx` (icon nốt nhạc, câu mẫu có sóng âm, "Bạn sẽ nghe thấy: …", mục gập khắc phục sự cố, ô "Bỏ qua bước kiểm tra này vào lần sau", nút "Xác nhận âm thanh"; mở khi bắt đầu phiên có item Nghe/Nói trừ khi đã chọn bỏ qua; xác nhận → `markPassed("speaker")`). Bài Nói: thẻ ghi âm với `AudioWaveform` khi ghi. Tái sử dụng: kiểm `pte-web/packages/ui` (AudioPlayer, Accordion, Checkbox) trước khi tạo mới.
- [ ] **Step 5a:** Màu nhấn màn làm bài: thêm token `--exam-primary: #004787`, `--exam-primary-hover: #094C8B`, `--exam-primary-active: #073B6D`, `--exam-canvas: #F7F9FF`, `--exam-banner: #EDF4FF`, `--exam-record-card: #EAF5EE` (dark: biến thể tương phản AA trên nền xám); lớp `.exam-shell` đặt `--accent: var(--exam-primary)` để nút/tiến độ/sóng âm trong màn làm bài dùng màu này.
- [ ] **Step 5b: Không đổi logic** của `timed/*`, `TimedTaskFrame`, `SpeakingRecorder` (pha, thời gian, phát-một-lần, tự ghi, lưu bản ghi): chỉ đổi JSX/CSS bọc ngoài. Kiểm: `npx vitest run features/practice/timed` vẫn PASS không sửa test.
- [ ] **Step 6:** tsc + eslint + vitest. **Step 7:** Không commit.

### Task 9: Kết quả từng câu, hoàn thành phiên, xem lại

**Files:**
- Modify: `features/practice/session/SessionResultCard.tsx`, `features/practice/ScoreView.tsx`, `features/practice/session/SessionStateCards.tsx`, `features/practice/PracticeReviewView.tsx`
- Create: `features/practice/session/complete-actions.ts`, `complete-actions.test.ts`

**Interfaces:**
- Consumes: Task 4 (`itemStatusKey`, `formatScore`), Task 5 (`session.kind/skillCode/taskCode`).
- Produces: `continueHref(session: PracticeSession): string | null` → TASK: `practiceSessionUrl(taskCode, {UNTIMED, 10})`; SKILL: `practiceSkillSessionUrl(skillCode, {UNTIMED, 10})`; MOCK_TEST hoặc thiếu dữ liệu → null; `sessionAverageScore(items): number | null`.

- [ ] **Step 1: Test** `continueHref`: TASK READ_ALOUD → `/practice-tests/session?task=READ_ALOUD&mode=UNTIMED&count=10`; SKILL READING → `...skill=READING...`; MOCK_TEST → null. `sessionAverageScore([80, null, 60])=70`, `([])=null`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** Kết quả câu: vòng điểm lớn, điểm thành phần thanh ngang, nhận xét, nghe lại, transcript, "Câu tiếp theo →"; đang chấm: vòng xoay + "thường mất khoảng 20 giây" không chặn. Hoàn thành: số câu, điểm TB, nút Xem lại / Luyện tiếp dạng này (chỉ khi `continueHref` khác null) / Trang chủ. Xem lại: thẻ thu gọn mở được, trạng thái tiếng Việt, bỏ `UI_TEXT`.
- [ ] **Step 6:** tsc + eslint + vitest. **Step 7:** Không commit.

### Task 10: Tiến trình

**Files:** Modify `features/progress/ProgressView.tsx`; Create `features/progress/progress-summary.ts`, `progress-summary.test.ts`, `features/progress/SkillTabs.tsx`

**Interfaces:**
- Consumes: Task 4, 5; `catalog` (task stats).
- Produces: `progressMetrics(progress: PracticeProgress): { sessions; completed; answered; averageScore: number | null }` (TB của `entry.score` không null).

- [ ] **Step 1: Test** `progressMetrics`: 3 entry score [80, null, 60] → averageScore 70; không entry → null.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** 4 ô số (Phiên, Hoàn thành, Câu đã trả lời, Điểm TB); `SkillTabs` (Nói|Viết|Đọc|Nghe → dòng dạng bài: số câu, `.score-badge`, nút Luyện → `openFor(task)`); lịch sử: `sessionDisplayName`, ngày, trạng thái tiếng Việt, nút Tiếp tục (`?sessionId=`) / Xem lại (`/practice-tests/session/review?sessionId=`). Bỏ hàng "—".
- [ ] **Step 6:** tsc + eslint + vitest. **Step 7:** Không commit.

### Task 11: Đăng nhập

**Files:** Modify `features/auth/SignInForm.tsx`, `features/auth/SignInShowcase.tsx`

- [ ] **Step 1:** Lỗi hiển thị ngay dưới ô (dùng `FieldWarning`), nút hiện trạng thái đang tải và bị khoá khi gửi, form `onSubmit` để Enter gửi; bỏ "Confidence: high" trong minh hoạ.
- [ ] **Step 2:** tsc + eslint. **Step 3:** Không commit.

### Task 13: Làm mới token single-flight

**Files:** Modify `features/practice/api.ts` (tách `refreshSession` sang `features/practice/token-refresh.ts` để giữ < 300 dòng); Create `token-refresh.test.ts`

**Interfaces:**
- Produces: `refreshOnce(refreshToken: string, doRefresh: (token: string) => Promise<boolean>): Promise<boolean>` — trong lúc một lần refresh đang chạy, mọi lời gọi trả về cùng promise; xong thì reset.

- [ ] **Step 1: Test:** 3 lời gọi đồng thời → `doRefresh` chạy đúng 1 lần, cả 3 nhận cùng kết quả; gọi lại sau khi xong → chạy lần mới.
- [ ] **Step 2–4:** FAIL → cài đặt, `request()` dùng `refreshOnce` → PASS. **Step 5:** Không commit.

### Task 14: Tải dữ liệu chỉ nhận kết quả mới nhất

**Files:** Create `common/hooks/useLatestRequest.ts`, `useLatestRequest.test.ts`; Modify `features/home/HomeView.tsx` (đề xuất), `features/mockTests/MockTestListView.tsx`, `features/progress/ProgressView.tsx`, `features/home/ExamDateLine.tsx`

**Interfaces:**
- Produces: `createLatestGate(): { begin(): number; isLatest(id: number): boolean; cancel(): void }` (thuần) và hook `useLatestRequest()` trả về gate, tự `cancel()` khi unmount.

- [ ] **Step 1: Test** `createLatestGate`: begin→1, begin→2, `isLatest(1)=false`, `isLatest(2)=true`; sau `cancel()` → `isLatest(2)=false`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** Áp vào 4 view: chỉ `setState` khi `isLatest(id)`. Nút lưu Ngày thi, Bắt đầu/Làm lại đề, Bắt đầu luyện khoá khi đang xử lý. **Step 6:** tsc + eslint + vitest. **Step 7:** Không commit.

### Task 15: Xung đột hai tab tự đồng bộ

**Files:** Modify `features/practice/session/useSessionMutations.ts`, `features/practice/PracticeSessionView.tsx`; Test `features/practice/session/session-draft.test.ts`

**Interfaces:**
- Produces: `isVersionConflict(reason: unknown): boolean` trong `session-draft.ts` (409 hoặc code `PRACTICE_STALE_SESSION_VERSION`).
- Hành vi: `runMutation` gặp xung đột → `getSession` mới nhất, `dispatch({ type: "received" })`, giữ bài nháp cục bộ của câu hiện tại, toast warning "Phiên đã thay đổi ở tab khác"; không hiện thẻ lỗi.

- [ ] **Step 1: Test** `isVersionConflict({status:409})=true`, `({code:"PRACTICE_STALE_SESSION_VERSION"})=true`, `({status:500})=false`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS. **Step 5:** tsc + eslint + vitest. **Step 6:** Không commit.

### Task 16: Mất mạng và rời trang khi đang ghi

**Files:** Create `common/hooks/useOnlineStatus.ts`; Modify `features/practice/session/SessionTaskView.tsx`, `features/shell/StudentShell.tsx`, `features/practice/session/useLeaveGuard.ts` (Task 8)

**Interfaces:**
- Consumes: `useLeaveGuard(busy)` từ Task 8.
- Produces: `useOnlineStatus(): boolean` (theo `navigator.onLine` + sự kiện `online`/`offline`, dùng `useSyncExternalStore`); `LeaveGuardContext` để `StudentShell` hỏi xác nhận trước khi điều hướng menu khi `busy`.

- [ ] **Step 1:** Offline → toast "Mất kết nối" + khoá Nộp/Bỏ qua/Thoát; online → toast "Đã kết nối lại".
- [ ] **Step 2:** Link menu trong `StudentShell` kiểm `LeaveGuardContext.busy` → `ConfirmDialog` (Task 8) trước khi đi.
- [ ] **Step 3:** tsc + eslint + vitest. **Step 4:** Không commit.

### Task 17: Kiểm tra bài Viết và bản ghi

**Files:** Create `features/practice/answer-checks.ts`, `answer-checks.test.ts`; Modify `features/practice/renderers/TextRenderer.tsx`, `features/practice/PracticeSessionView.tsx`, `features/practice/renderers/SpeakingRecorder.tsx`

**Interfaces:**
- Produces: `wordCountIssue(words: number, min: number | null, max: number | null): "under" | "over" | null`; `recordingIssue(durationSeconds: number, maxLevel: number): "short" | "silent" | null` (short < 1 giây, silent < 0.01).

- [ ] **Step 1: Test:** `wordCountIssue(42,200,300)="under"`, `(301,200,300)="over"`, `(250,200,300)=null`, `(10,null,null)=null`; `recordingIssue(0.5,0.2)="short"`, `(5,0.005)="silent"`, `(5,0.2)=null`.
- [ ] **Step 2–4:** FAIL → cài đặt → PASS.
- [ ] **Step 5:** Bộ đếm đổi màu khi có issue; Nộp bài Viết có issue → `ConfirmDialog` "Bài viết có {n} từ (yêu cầu {min}–{max}), vẫn nộp?". Recorder có issue → cảnh báo với "Ghi lại" / "Vẫn lưu" trước khi upload.
- [ ] **Step 6:** tsc + eslint + vitest. **Step 7:** Không commit.

### Task 18: Danh sách đề trống và đăng nhập

**Files:** Modify `features/mockTests/MockTestListView.tsx`, `features/auth/SignInForm.tsx`, `common/i18n/*`

- [ ] **Step 1:** Trạng thái trống: "Ngân hàng câu hỏi chưa đủ để tạo đề luyện. Hãy quay lại sau."
- [ ] **Step 2:** Đăng nhập: `trim()` tài khoản; ô trống → `FieldWarning` ngay dưới ô, không gọi API; nút khoá khi gửi (gộp với Task 11).
- [ ] **Step 3:** tsc + eslint. **Step 4:** Không commit.

### Task 12: Kiểm chứng và báo cáo (chạy cuối cùng, sau Task 18)

- Bổ sung kiểm thêm: 2 tab cùng phiên (nộp ở tab A rồi nộp ở tab B → tab B tự tải lại + toast); tắt mạng (DevTools offline) → nút bị khoá + toast; bài Viết 10 từ → hỏi xác nhận.


- [ ] **Step 1:** BE: `./mvnw -q -pl app -am test` → EXIT 0.
- [ ] **Step 2:** FE: `npx tsc --noEmit`, `npx eslint features common app`, `npx vitest run` → xanh.
- [ ] **Step 3:** Playwright (tài khoản `pte-center.practice01`): ảnh 390px và 1280px × light/dark cho Đăng nhập, Trang chủ, Luyện đề, Study-Pack, Tiến trình, màn làm bài (Read Aloud + một bài Reading), kết quả, hoàn thành, xem lại. Kiểm: không cuộn ngang; học viên chưa có điểm → "—"; Thoát khi đang tải bản ghi chờ xong.
- [ ] **Step 4:** Báo cáo `pte-doc/projects/plans/reports/261025-hung-practice-ux-redesign-report.md` (lệnh + kết quả, ảnh, việc tồn); xoá `.playwright-mcp`. Không commit.
