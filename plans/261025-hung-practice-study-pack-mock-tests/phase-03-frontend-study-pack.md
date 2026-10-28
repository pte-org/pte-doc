# Phase 3: Frontend — Study-Pack theo kỹ năng

Status: Not started
User stories: Study-Pack (P1)
FR: FR-07 (Study-Pack) · Spec §4.1

## Requirements

- `/study-pack` hiển thị danh sách 4 kỹ năng theo thứ tự Reading, Listening, Speaking, Writing (như ảnh tham chiếu): icon tròn xám (`iconForSection`), tên kỹ năng (i18n `skills.*`), dòng phụ "x trên N câu đã trả lời" (`answeredQuestionCount` / `practiceQuestionCount`), nút **Luyện tập** (`button-primary`, icon play).
- Kỹ năng không có dạng RUNNABLE hoặc `practiceQuestionCount = 0` → nút tắt, dòng phụ "Chưa có câu luyện tập".
- Bỏ `STUDY_PACKS` cứng và các key i18n `studyPacks.*`, `studyPackView.openPack` không còn dùng.
- Bấm Luyện tập → `PracticeModeDialog` ở chế độ kỹ năng: tiêu đề = tên kỹ năng, TIMED bật khi mọi dạng RUNNABLE của kỹ năng có `timedAvailable`, số câu 10/20/30/Tất cả; nhớ lựa chọn với khoá `skill:<CODE>`.
- Start: URL `/practice-tests/session?skill=READING&mode=…&count=…`; `useSessionLifecycle` gửi `skillCode` thay vì `taskTypeCodes`; `requestKey` gồm skill.
- Phiên kỹ năng dùng lại toàn bộ UI phiên (counter, ring, recorder, TIMED engine).

## Design Constraints

- Dùng lại: `PracticeModeDialog` (tổng quát hoá prop `task` thành `target: { key, title, timedAvailable }` — giữ API cũ qua adapter để Home/catalog không đổi), `usePracticeStart` (thêm `openForSkill`), `AppIcon`, `LockBadge`, i18n.
- Không thêm thư viện. CSS dùng token sẵn có trong `app/globals.css` (`--surface`, `--line`, `--surface-raised`, `--text`, `--muted`); class mới tiền tố `study-skill-`.
- `practice-url.ts`: thêm `practiceSkillSessionUrl(skill, preference)`; giữ `practiceSessionUrl`.
- Contracts: thêm `practiceQuestionCount`, `answeredQuestionCount` vào parser section (mặc định 0 khi thiếu để chạy với BE cũ).
- File > 300 dòng → tách (giữ chuẩn của plan trước).
- Hàm thuần có test vitest cùng file `.test.ts`.

## Related files

- `pte-practice/features/studyPack/StudyPackView.tsx` (viết lại), `features/studyPack/study-pack-rows.ts` + `.test.ts` (mới, thứ tự + trạng thái hàng)
- `features/practice/mode/PracticeModeDialog.tsx`, `usePracticeStart.tsx`, `mode-preference.ts`, `practice-url.ts` (+ tests)
- `features/practice/session/useSessionLifecycle.ts`
- `features/practice/contracts.ts` (section counts), `features/practice/constants.ts` (bỏ `STUDY_PACKS`)
- `common/i18n/{types,en,vi}.ts`
- `app/globals.css`

## Steps

1. Contracts: parse 2 số đếm của section; test parser với/không có trường.
2. `study-pack-rows.ts`: `studySkillRows(catalog, unlocked)` → thứ tự, `answered`, `total`, `canStart`, `timedAvailable`; test.
3. Tổng quát hoá dialog + `usePracticeStart.openForSkill`; `mode-preference` khoá `skill:<CODE>`; test khoá.
4. `practiceSkillSessionUrl` + test; `useSessionLifecycle` đọc `skill`, gửi `skillCode`.
5. Viết lại `StudyPackView` + CSS; i18n `studyPackView.answeredOf`, `studyPackView.noQuestions`, `studyPackView.practice`, `studyPackView.skills` (en/vi).
6. Xoá dữ liệu/i18n cũ không dùng.
7. Build gate: `npx tsc --noEmit`, `npx eslint .`, `npx vitest run`.

## Success Criteria

- Trang Study-Pack đúng bố cục ảnh (4 hàng, nút Luyện tập), light và dark mode.
- Reading → dialog → Không tính giờ, 10 câu → phiên có 10 câu ≥ 2 dạng bài.
- Reload trang phiên kỹ năng không tạo phiên mới (idempotency key giữ nguyên).
- tsc sạch, eslint 0 lỗi, vitest xanh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
