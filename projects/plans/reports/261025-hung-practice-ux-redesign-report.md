# Báo cáo: Thiết kế lại UI/UX pte-practice + kiểm tra dữ liệu + race condition cơ bản

Ngày: 2026-10-25 · Nhánh `hung/feat/practice-revamp` · Plan: `plans/hung-practice-ux-redesign/` · **Chưa commit**

## Kết quả lệnh
| Lệnh | Kết quả |
|---|---|
| `./mvnw -q -pl app -am clean test` (pte-api) | EXIT 0 |
| `npx tsc --noEmit` / `npx eslint features common app` | sạch / 0 lỗi |
| `npx vitest run` | 45 file, 210 test pass (test `timed/*` không sửa vẫn pass) |
| Docker `app` build lại (`--no-deps`) | healthy |

## Đã làm theo phase
1. **Backend:** catalog student thêm `answeredQuestionCount`, `averageScore` mỗi dạng bài (1 truy vấn GROUP BY); progress entry thêm `score` (TB phiên), `kind`, `skillCode`, `taskCode`; session response thêm `kind`, `skillCode`, `taskCode`. Bỏ `mockTestPublicId` (không cần — tên đề có sẵn trong `title`).
2. **Nền tảng FE:** token + lớp chung (`.page-column` 840px, `.card`, `.chip`, `.hint-strip`, `.score-badge`, `.carousel`, token `--exam-*` màu pte-app `#004787`); `presentation.ts`; contract mới; `refreshOnce` (làm mới token một lần cho mọi request 401 đồng thời + bỏ qua refresh khi token đã đổi); `createLatestGate`/`useLatestRequest`.
3. **Trang chủ** theo ảnh Pearson (thẻ đầu: logo, Ngày thi ✎, 2×2 thẻ thiết bị, dải gợi ý; "Đề xuất cho bạn" trượt ngang; "Kỹ năng" theo nhóm có vòng tiến độ và huy hiệu điểm); Luyện đề, Study-Pack dùng thẻ chung.
4. **Trang làm bài** theo ảnh phiên học Pearson: trang riêng không sidebar, thanh trên (tên phiên, Phần/Câu, "Tạm dừng phiên" có xác nhận = lưu & thoát), thanh tiến độ phân đoạn, audio đề có sóng âm + thời gian, bài Viết có toolbar Copy/Cut/Paste + dòng gợi ý số từ, thẻ "Câu trả lời ghi âm" (giữ `AudioWaveform`), thanh dưới "Bỏ qua" (xác nhận) / "Tiếp theo ›", hộp "Kiểm tra phát âm thanh" đầu phiên Nghe/Nói (có "Bỏ qua lần sau"); hoàn thành phiên (điểm TB, Xem lại, Luyện tiếp dạng này, Trang chủ); xem lại i18n, thẻ gập, trạng thái tiếng Việt + điểm.
   An toàn: xung đột 2 tab tự tải lại + toast; mất mạng toast + khoá Nộp/Bỏ qua/Tạm dừng; cảnh báo rời trang khi đang ghi/tải; Tạm dừng/Tiếp theo bị khoá ("Đang lưu bản ghi…") tới khi tải xong; bài Viết ngoài khoảng số từ → hỏi "Vẫn nộp"; bản ghi < 1 giây hoặc im lặng → "Ghi lại / Vẫn lưu" (chỉ chế độ không tính giờ).
5. **Tiến trình:** 4 ô số (có Điểm TB), tab kỹ năng (điểm TB từng dạng bài + nút Luyện), lịch sử tên rõ + Tiếp tục/Xem lại. **Đăng nhập:** kiểm tra ô trống ngay dưới ô, chặn gửi trùng, bỏ "Confidence" ở minh hoạ. **Đề trống:** nêu lý do ngân hàng chưa đủ.

## Tái sử dụng component (quy tắc design §5)
| Component | Nguồn |
|---|---|
| Modal, Toast, ProgressRing, AppIcon, CountdownTimer, LoadingState, LockBadge, ExamDateLine, DeviceCheckDialog | dùng lại `pte-practice/common` |
| ConfirmDialog, Checkbox, CollapsibleSection, Tabs/TabPanel, useSignInValidation | **port từ `@pte/ui`** (giữ tên + API; `useSignInValidation` thêm cờ `requireEmail`, `CollapsibleSection` thêm `icon`) |
| SegmentedProgress, PromptAudioPlayer, SessionHeader/SessionFooter, AudioPlaybackCheckDialog, RecommendationCarousel, useLatestRequest, useOnlineStatus | **tạo mới** (không có tương đương trong `@pte/ui`) |

## Kiểm chứng trên trình duyệt (Playwright, 1280px + 390px, light)
- Đăng nhập → Trang chủ; Trang chủ: thẻ đầu khớp ảnh mẫu, đề xuất lấy phiên đang dở, nhóm kỹ năng có 31% / 50% / 100% / "—"; không cuộn ngang ở 1280 và 390.
- Trang làm bài (phiên Reading): thanh trên "Reading practice · 10 questions / Part 1 of 1 / Question 2 of 10 / Pause session", tiến độ phân đoạn, "Next ›"; hộp "Tạm dừng phiên" và "Bỏ qua" mở đúng; không cuộn ngang ở 390.
- Sửa thêm khi kiểm: bố cục thẻ đầu Trang chủ bị chia 3 cột (CSS cũ `.home-hero`) → sửa; trang làm bài bị lỗi "instant-unrendered-segment" của Next → thêm `instant = false`.

## Chưa kiểm trên trình duyệt (có test đơn vị cho phần logic)
- Hộp "Kiểm tra phát âm thanh" (phiên Nghe/Nói), xác nhận số từ bài Viết, 2 tab cùng phiên, chế độ offline, Thoát khi đang tải bản ghi, dark mode, các trang Tiến trình / Study-Pack / Luyện đề / Xem lại sau thay đổi.

## Việc tồn / ghi chú
- Đồng hồ tính giờ vẫn nằm trong khung câu hỏi (`TimedTaskFrame`), không lên thanh trên — để không đổi logic tính giờ.
- Thẻ kết quả từng câu dùng `ScoreView` hiện có, chưa làm vòng điểm lớn + thanh điểm thành phần.
- Nút "Bỏ qua" ở góc trái dưới bị huy hiệu Next.js dev che khi chạy `next dev` (không có ở bản build).
- `RECORDING_TEXT` trong recorder vẫn là chuỗi tiếng Anh cứng (chỉ chuỗi mới qua i18n).
