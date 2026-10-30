# Báo cáo: Practice — chế độ tính giờ / không tính giờ, recorder, vòng tiến độ

Ngày: 2026-10-25 · Nhánh: `hung/feat/practice-revamp` (pte-api, pte-practice, pte-doc) · Trạng thái: **chưa commit**

## 1. Đã làm
- **BE (pte-api):** migration V133 (`timing_mode`, timing pin theo item), chọn câu hỏi ngẫu nhiên/ưu tiên câu chưa làm (`PracticeQuestionPicker`), timing lấy từ Score Template + `task-timing.json` (`PracticeTimingService`), phát lại bản ghi (`PracticeRecordingPlaybackService`), lưu draft sau upload. Session không còn deadline mặc định.
- **FE (pte-practice):** dialog chọn chế độ, tự bắt đầu session, `SpeakingRecorder` (ghi WAV, sóng âm, nghe lại, ghi lại, phát lại từ server sau reload), engine tính giờ (reducer thuần, deadline theo đồng hồ thực), `TimedTaskFrame`, vòng tiến độ (Progress, Home, trong session, component chung).
- **Seed script:** `PerTask` nâng lên 1..12 (mẫu lặp theo 3 biến thể, tiêu đề khác nhau).

## 2. Lệnh và kết quả
| Lệnh | Kết quả |
|---|---|
| `./mvnw -q -pl app -am test` (toàn bộ BE) | EXIT 0 |
| `PracticeTimingServiceTest` + `PracticeQuestionPickerTest` | 4 + 5 test, 0 lỗi |
| `npx tsc --noEmit` (pte-practice) | sạch |
| `eslint` | 0 lỗi (còn warning unused-import có sẵn ở SkillTaskList, StudentShell) |
| `vitest` | 28 file / 155 test pass |
| DB | Flyway V133 thành công; không session OVERVIEW/IN_PROGRESS nào có deadline; session cũ có mode null (= UNTIMED) |

## 3. Kiểm thử thủ công trên trình duyệt (Playwright)
Đã xác nhận: dialog 2 lựa chọn; untimed ghi → sóng âm → nghe lại → ghi lại; phát lại từ server sau reload; timed Read Aloud tự ghi theo pha, dừng sớm, sang Done; câu timed đã có bản ghi mở lại ở trạng thái Done; vòng tiến độ ở Home và Progress (nhãn "Phiên gần nhất").

**Chưa chạy** (rủi ro còn lại): Repeat Sentence timed; khóa nhập khi hết giờ ở Listening/Writing; upload lỗi offline + "Lưu lại"; session legacy trước V133 trên UI; học viên khác gọi playback phải 404; đo độ dài WAV (TC4); spike CORS.

## 4. Quyết định
- Vòng dùng biến thể `empty`; vòng phiên gần nhất gắn nhãn "Phiên gần nhất".
- Câu timed không phải Speaking: hết giờ thì khóa nhập, học viên bấm Submit.
- Trần ghi âm 120 giây; icon MDI qua `@mdi/js`.
- Bản ghi đã lưu phát lại được sau reload; câu timed có bản ghi mở lại là Done (không làm lại).
- **Lệch spec §4:** không có Web Audio thì không ghi được (không có phương án dự phòng).

## 5. Rủi ro / việc tồn
- `RECORDING_TEXT` chưa chuyển sang i18n (chỉ key `timed.*` và `mode.*` mới ở i18n).
- Còn cảnh báo ScriptProcessor deprecated; lỗi console "instant navigation" của Next có sẵn.
- Lộ thứ tự đáp án ở Re-order Paragraphs (chưa sửa); sidebar còn brand Pearson.
- Seed script chưa chạy lại với `PerTask` > 3.
