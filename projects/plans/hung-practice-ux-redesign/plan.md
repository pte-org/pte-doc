# Plan: Thiết kế lại UI/UX pte-practice + kiểm tra dữ liệu + race condition cơ bản

Status: Completed
Date: 2026-10-25
Mode: Hard (bỏ research — đã đọc trực tiếp pte-app/pte-web làm tham chiếu; bỏ agent red-team để tiết kiệm token, đã có builder check cho design)
Test: default (test viết kèm từng task, xem `tasks.md`)
Owner/slug: Hung — `hung-practice-ux-redesign`
Scope: `pte-practice` (chính), `pte-api` module `practice` (2 bổ sung DTO)
Related: [design](./design.md) · [tasks chi tiết](./tasks.md)

Nhánh `hung/feat/practice-revamp`; **không commit** khi Hung chưa bảo.

## Quy tắc chung (bắt buộc mọi phase)
- **Tái sử dụng trước khi code UI** (design §5): `pte-practice/common/components` → port từ `pte-web/packages/ui` (giữ tên + API, ghi nguồn) → chỉ tạo mới khi cả hai không có.
- Cột nội dung 840px cho trang thường; **màn làm bài là trang riêng không sidebar** theo ảnh phiên học Pearson (thanh trên có "Tạm dừng phiên", tiến độ phân đoạn, audio đề có sóng âm, toolbar Copy/Cut/Paste, "Tiếp theo ›", hộp "Kiểm tra phát âm thanh"), không dùng Fullscreen API; màu nhấn màn làm bài `#004787`.
- Được tự build lại Docker service `app` (`--no-deps`) khi cần kiểm chứng (Hung cho phép 2026-10-25).
- **Không đổi logic** tính giờ / không tính giờ / recorder; giữ `AudioWaveform`.
- Mọi chuỗi qua i18n; không mã thô trên giao diện.

## Phases

- [x] Phase 1: Backend — thống kê theo dạng bài + loại phiên — [phase-01-backend-stats-and-kind.md](./phase-01-backend-stats-and-kind.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: tests viết kèm pass — SkillStats 2, Progress 4, Mapper 4, SessionService 17, ModuleStructure 3; `mockTestPublicId` bỏ (không cần: tên đề có sẵn trong `title`); thêm `score` = điểm TB phiên]
- [x] Phase 2: Frontend nền tảng — token/CSS chung, hàm trình bày, contract, token single-flight, latest-request gate — [phase-02-frontend-foundation.md](./phase-02-frontend-foundation.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: presentation 5, token-refresh 2, latest-request 2 — vitest 192 pass; BE full suite 2769 test, 3 lỗi ECJ của VS Code trong target, chạy lại sau `clean` pass]
- [x] Phase 3: Trang chủ, Luyện đề, Study-Pack — [phase-03-home-mock-studypack.md](./phase-03-home-mock-studypack.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: recommendations 2 — vitest 194 pass; tái sử dụng: ProgressRing/AppIcon/ExamDateLine/DeviceCheckDialog (common), carousel bằng CSS; `SkillTaskList` sửa tại chỗ thay vì tạo `SkillGroups`]
- [x] Phase 4: Màn làm bài (khung pte-app), kết quả, hoàn thành, xem lại + xung đột 2 tab, mất mạng, kiểm tra bài Viết/bản ghi — [phase-04-session-experience.md](./phase-04-session-experience.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: session-chrome 3, answer-checks 2, isVersionConflict 1, complete-actions 3, prompt-peaks 3 — vitest 206 pass, test `timed/*` không sửa vẫn pass. Port từ @pte/ui: ConfirmDialog, Checkbox, CollapsibleSection; mới: SegmentedProgress, PromptAudioPlayer, SessionHeader/Footer, AudioPlaybackCheckDialog. Đồng hồ tính giờ giữ trong `TimedTaskFrame` (không chuyển lên thanh trên để không đổi logic); thẻ kết quả từng câu giữ `ScoreView` hiện có]
- [x] Phase 5: Tiến trình, Đăng nhập, đề trống — [phase-05-progress-signin.md](./phase-05-progress-signin.md) [quality: skipped_by_user; decision: user_confirmed_skip] [testing: progress-summary 2, useSignInValidation 2 — vitest 210 pass. Port từ @pte/ui: Tabs/TabPanel, useSignInValidation (thêm cờ `requireEmail` vì tài khoản roster không phải email)]
- [x] Phase 6: Kiểm chứng và báo cáo — [phase-06-verification.md](./phase-06-verification.md) [quality: skipped_by_user; decision: user_confirmed_skip] — báo cáo: ../reports/261025-hung-practice-ux-redesign-report.md (một số kiểm tra trình duyệt chưa chạy, xem mục "Chưa kiểm")

## Phase → task (tasks.md) → design
| Phase | Tasks | Design |
|---|---|---|
| 1 | 1, 2 | §4.1, §4.7, §6.1, §6.6 |
| 2 | 3, 4, 5, 13, 14 (phần gate) | §3, §6.2, §8.2, §8.5 |
| 3 | 6, 7, 14 (áp vào Home/Luyện đề) | §4.1–4.3, §6.4 |
| 4 | 8, 9, 15, 16, 17 | §4.4–4.6, §6.7–6.8, §7.1–7.3, §8.1, §8.3 |
| 5 | 10, 11, 18, 14 (áp vào Tiến trình/Ngày thi) | §4.7–4.8, §7.4–7.5, §8.4 |
| 6 | 12 | §6.9 + mọi tiêu chí |

## Risks
- **R1** Khung làm bài trong trang (thanh trên/dưới riêng) có thể chồng với thanh trên của app trên màn hẹp → kiểm 390px trong Phase 6.
- **R2** Bọc lại recorder có thể vô tình đổi hành vi tính giờ → Phase 4 bắt buộc `npx vitest run features/practice/timed` PASS không sửa test.
- **R3** Port component từ `@pte/ui` dùng Tailwind → chuyển sang CSS token, giữ API.
- **R4** Thống kê điểm theo dạng bài tính trên mọi phiên có thể chậm khi lịch sử lớn → một truy vấn GROUP BY, không N+1.
