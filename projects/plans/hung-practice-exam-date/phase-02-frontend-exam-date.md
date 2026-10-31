# Phase 2: Frontend — dòng Ngày thi + cây bút + modal, kiểm chứng
Preflight: Use existing Modal, AppIcon, toast; formatExamDate with UTC projection.

Status: Completed · FR-04, 05, 06

## Requirements
- API client: `getProfile()`, `updateProfile(examDate | null)` (thêm vào `features/practice/api.ts` hoặc file riêng `features/home/exam-date-api.ts` nếu `api.ts` vượt 300 dòng); parser `{ examDate: string | null }` (chỉ nhận dạng `YYYY-MM-DD`).
- `exam-date.ts` (+ test): `formatExamDate(iso, locale, today)` → vi "7 tháng 11" / en "7 November", thêm năm khi khác năm hiện tại; `examDateBounds(today)` → min/max cho input.
- `ExamDateLine` trên Trang chủ thay dòng "Exam date: Not scheduled": icon lịch + "Ngày thi: …" / "Chưa đặt lịch" + nút bút (`aria-label` "Sửa ngày thi"). Bấm → `Modal` với `<input type="date">` (min/max), nút Lưu, Xoá ngày thi (khi đang có), Đóng. Lưu/xoá → gọi API, cập nhật dòng, toast success; lỗi → toast error, giữ giá trị cũ.
- i18n `examDate.*` (en/vi); bỏ key cũ `home.examDate`/`home.notScheduled` nếu không còn dùng.

## Design Constraints
- Dùng `Modal`, `AppIcon`, toast đã có; CSS token; không thư viện date picker.
- Tải profile khi vào Trang chủ (không chặn render; đang tải hiện "…").

## Related files
`features/home/{HomeView.tsx, ExamDateLine.tsx, exam-date.ts, exam-date.test.ts}`, `features/practice/api.ts` (hoặc file api riêng), `common/i18n/*`, `app/globals.css`, `common/components/icon-paths.ts` (icon `edit` nếu thiếu)

## Steps
1. Hàm thuần + test.
2. API client + component + i18n + CSS.
3. Build gate: tsc, eslint, vitest.
4. Kiểm chứng trên trình duyệt: đặt 7/11 → hiện đúng; tải lại vẫn còn; xoá → "Chưa đặt lịch"; ngày quá khứ bị chặn. Xoá `.playwright-mcp`.

## Success Criteria
- Mọi tiêu chí trong spec §Success Criteria.

## Quality and Testing State
- Quality: skipped_by_user (user_confirmed_skip)
- Testing: passed (7 unit tests in exam-date.test.ts, 183 total vitest tests, tsc, eslint)
