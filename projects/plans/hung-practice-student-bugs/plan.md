# Plan: pte-practice — sửa lỗi và bổ sung phía học viên (đợt test tay 2026-11-23/24)

Status: Completed (code) — chờ Hung test tay rồi mới merge
Date: 2026-11-24
Mode: Fast (từng bug gửi lần lượt qua `/ck:cook --fast`)
Test: skipped_by_user (Hung test tay; chỉ chạy build, eslint và các test sẵn có liên quan)
Owner/slug: Hung — `hung-practice-student-bugs`
Scope: `pte-api` (`practice`, `identity`), `pte-practice`, `pte-doc`
Related: [hung-password-reset-email](../hung-password-reset-email/plan.md) (quyết định "học viên không tự đặt lại qua e-mail" bị đảo ở Phase 3), [ninh-practice-answer-leak-backend](../ninh-practice-answer-leak-backend/plan.md) (đáp án chỉ trả sau khi câu đã chấm), [ninh-refresh-token-single-use](../ninh-refresh-token-single-use/plan.md)

Làm trên nhánh `hung/fix/practice-bugs` ở `pte-api` và `pte-practice`, mở PR vào `dev`. Không commit khi Hung chưa bảo.

## Mục tiêu

Hung test pte-practice bằng tay, mỗi lỗi tìm thấy được ghi thành một bug rồi sửa riêng. Plan này gom các bug và tính năng đó thành năm phase để reviewer đọc theo từng chủ đề.

## Phases

- [x] Phase 1: Chấm và hiện đúng/sai ngay cho câu có đáp án sẵn — [phase-01-instant-feedback.md](./phase-01-instant-feedback.md) [quality: skipped_by_user; testing: skipped_by_user]
- [x] Phase 2: Học viên bị tạm ngưng không xem được practice — [phase-02-suspended-student-access.md](./phase-02-suspended-student-access.md) [quality: skipped_by_user; testing: skipped_by_user]
- [x] Phase 3: Quên mật khẩu và đổi mật khẩu cho học viên — [phase-03-student-passwords.md](./phase-03-student-passwords.md) [quality: skipped_by_user; testing: skipped_by_user]
- [x] Phase 4: Thẻ tài khoản — tên, e-mail, giới tính và ảnh đại diện — [phase-04-account-card.md](./phase-04-account-card.md) [quality: skipped_by_user; testing: skipped_by_user]
- [x] Phase 5: Sửa giao diện nhỏ — trang xem lại và thanh trên — [phase-05-ui-fixes.md](./phase-05-ui-fixes.md) [quality: skipped_by_user; testing: skipped_by_user]

## Phase → commit

| Phase | `pte-api` | `pte-practice` |
|---|---|---|
| 1 | `4fb793dc` | `b67f9ed`, `cce1f3a` |
| 2 | `fdb05bcc` | `a056da3` |
| 3 | `6b8ed8e7`, `75424e58` (`APP_WEB_PRACTICE_URL` ở `docker-compose.deploy.yml`) | `7034b05`, `5a9b8ad`, `1e0b6f5`, `f8bfd5c`, `77ddc3b` |
| 4 | `c76e1d15`, `c4483bfd` (V57) | `cf17e89`, `7f199bc`, `ac27482` |
| 5 | — | `40475df`, `d9866e8`, `18858c2`, `c1e9e81`, `1f17cf5`, `5b3a1e9` |

## Architecture decisions

- **A1.** Mọi thay đổi hợp đồng API đều **chỉ cộng thêm** (field mới, endpoint mới). Không đổi tên hay xoá field nào client hiện tại đang đọc. Ngoại lệ có chủ đích: các endpoint đọc của practice trả 403 cho học viên bị tạm ngưng (Phase 2).
- **A2.** Ảnh đại diện có endpoint ghi riêng `PUT /student/practice/profile/avatar`. `PUT /profile` coi `examDate: null` là "xoá ngày thi", nên gộp chung sẽ làm mỗi lần đổi avatar xoá mất ngày thi đã đặt. `PracticeProfileUpdateRequest` và `update()` giữ nguyên.
- **A3.** Chặn học viên bị tạm ngưng ở **controller** (`unlockedCaller()`), không sửa năm service, để không đổi constructor và test của chúng. `/entitlement` và `/catalog` cố ý để mở để màn hình "Đã khóa" vẫn hiện được.
- **A4.** Form quên/đặt lại mật khẩu của practice theo đúng form của `pte-web` (cùng trường, cùng thứ tự kiểm tra, cùng lời văn), bộ kiểm tra mật khẩu tách ra `password-rules.ts` dùng chung với form đổi mật khẩu.
- **A5.** Cột `gender` ở `practice_student_profiles` cho phép `NULL`, không default, không backfill; học viên chưa chọn thì thấy avatar nam.

## Risks

- **R1 — Đảo quyết định chính sách.** `hung-password-reset-email` đặt "học viên tự đặt lại mật khẩu qua e-mail" ngoài phạm vi (P3) và hiện hướng dẫn liên hệ trung tâm. Phase 3 mở lại luồng đó cho học viên. Hệ quả: ai kiểm soát được hộp thư của học viên thì chiếm được tài khoản. Giảm nhờ các giới hạn có sẵn: phải khớp cả username lẫn e-mail, 3 yêu cầu mỗi e-mail và 10 mỗi địa chỉ trong 15 phút, link dùng một lần và hết hạn sau 30 phút, đặt lại xong thì mọi phiên bị đăng xuất. **Cần leader xác nhận.**
- **R2 — Link e-mail của học viên trỏ sai.** `app.web.practice-url` mặc định `http://localhost:3014`. Môi trường deploy phải đặt `APP_WEB_PRACTICE_URL`; `docker-compose.deploy.yml` đã thêm dòng lấy từ `PRACTICE_DOMAIN` (`75424e58`), nhưng nơi nào không dùng file đó phải tự đặt.
- **R3 — Đáp án lộ sớm.** `optionVerdicts` mang cờ đúng/sai của từng lựa chọn. Chỉ trả khi câu đã chấm, và với MOCK_TEST thì giấu cho tới khi nộp bài (xem `ninh-practice-answer-leak-backend`).
- **R4 — Hai kiểu 401.** Mật khẩu hiện tại sai khi đổi mật khẩu cũng trả 401. Client từng coi mọi 401 là "token hết hạn" nên đá học viên ra. Đã sửa ở Phase 3; mọi chỗ mới gọi endpoint có thể trả 401 vì lý do khác phải dùng `allowRefresh: false`.
- **R5 — Chuyển giao.** Local chạy profile `local-schema` nên Flyway tắt và cột `gender` do Hibernate tạo; V57 chỉ chạy ở môi trường dùng Flyway. Migration này ban đầu là V54 và đã đổi thành **V57** khi gộp `dev` (dev đã dùng V54 đến V56); nó chưa chạy ở đâu nên đổi số là an toàn.

- **R6 — Mâu thuẫn với hợp đồng practice đã duyệt.** [`quang-pte-practice-student-web`](../quang-pte-practice-student-web/plan.md) viết: lịch sử "vẫn đọc được sau khi thu hồi gói, **vô hiệu hoá học viên** hoặc rollback" (plan.md mục 7; `phase-01-contract-matrix.md`; `phase-07`; spec FR-09), và chỉ các thao tác *ghi* mới bị chặn. Phase 2 làm ngược lại: chặn cả thao tác đọc (phiên, xem lại, ghi âm, lịch sử). Nó cũng **rộng hơn một học viên bị tạm ngưng**: `assertUnlocked` ném lỗi với mọi trạng thái khác `UNLOCKED`, nên học viên của một tổ chức hết gói hoặc vượt hạn mức cũng mất quyền xem lại lịch sử. Phase 2 theo đúng yêu cầu của bug do Hung ghi, nhưng **cần leader xác nhận** trước khi merge. Nếu giữ hợp đồng cũ cho trường hợp hết gói thì chỉ cần chặn khi `entitlement.practice.state == UNAVAILABLE` (học viên không còn active trong tổ chức) thay vì mọi trạng thái khóa.

## Kết quả thực hiện (2026-11-24)

Đã chạy:

- `pte-api`: `PasswordReset*Test` và `AuthControllerPasswordResetTest` 52 test đạt; `PracticeProfileServiceTest` 8 test đạt; `PackageDensityTest` đạt; `mvn package -DskipTests` build được.
- `pte-practice`: `eslint` sạch; `vitest` 919 test đạt; `tsc --noEmit` chỉ còn một lỗi có sẵn ở `tests/unit/features/mascot/pip-assets.test.tsx` (import `sharp` mà `sharp` không có trong `package.json`, thêm ở `d6f88c5`), kéo theo `next build` dừng ở bước type-check.

Chưa kiểm chứng:

- Chưa chạy toàn bộ test của `pte-api`.
- `SourceFileSizeTest` **đang đỏ sẵn**: `session/internal/service/draft/ExamPublishService.java` dài 322 dòng (giới hạn 300). Không file nào của đợt này vượt giới hạn.
- Chưa gọi thật `PUT /profile/avatar` để xác nhận ngày thi giữ nguyên (không có token học viên khi làm). Đây là ca test tay quan trọng nhất của Phase 4.
- Chưa chụp thanh trên với nền ảnh, thẻ tài khoản và bố cục trang xem lại sau khi sửa. Hung kiểm tra bằng mắt.
- `b67f9ed` có kèm khoảng 10 file unit test, được commit trước khi Hung bảo bỏ test; các commit sau không viết thêm. Chưa quyết định giữ hay bỏ.

Ghi chú phụ, không thuộc phạm vi: log nginx 8–24/11 có 8 lần refresh bị 401 trên 119 lần. Các lần của practice đều do Host bật/tắt tạm ngưng học viên lúc test; một lần của tenant-web là hai refresh đồng thời. Chưa thấy ca đá ra không rõ lý do.
