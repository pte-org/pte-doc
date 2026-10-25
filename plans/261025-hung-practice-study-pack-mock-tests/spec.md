# Spec: Study-Pack theo kỹ năng và Luyện đề (Full Mock Test) trong pte-practice

**Ngày:** 2026-10-25
**Owner:** Hung
**Repo bị ảnh hưởng:** `pte-api` (module `practice`, đọc `itembank`, `scoretemplate`), `pte-practice`
**Phụ thuộc:** làm tiếp trên nhánh `hung/feat/practice-revamp`, sau plan `261024-hung-practice-timed-modes` (V133, engine tính giờ, recorder). Migration mới bắt đầu từ **V134**.
**Trạng thái:** Chờ duyệt

Quy ước: **[Đã chốt]** là điều Hung đã quyết; **[Quyết định của Claude]** là mặc định Claude chọn, Hung đổi được khi đọc.

---

## 1. Vì sao làm

- Trang **Bài thi thử** hiện chỉ là catalog theo dạng bài, trùng với Trang chủ. Học viên cần **luyện cả đề** đúng cấu trúc thi để quen nhịp 2 giờ và có điểm ước lượng theo kỹ năng.
- Trang **Study-Pack** đang là các thẻ gói học viết cứng, bấm vào chỉ chuyển sang trang Bài thi thử. Học viên cần **luyện theo cả kỹ năng** (ví dụ cả phần Reading) trong một phiên.

Tham chiếu giao diện: ảnh app PTE Official AI Practice (danh sách "PTE Academic Full Mock Test 1…8" có chip "65 câu" và "2h 15m"; Study-Pack là danh sách 4 kỹ năng, mỗi hàng có số mục đã trả lời và nút Luyện tập).

## 2. Mục tiêu, không làm, thất bại

### Mục tiêu
1. Study-Pack: danh sách 4 kỹ năng; bấm **Luyện tập** mở dialog chọn chế độ (tính giờ / không tính giờ, số câu) cho **cả kỹ năng**, rồi vào phiên gồm mọi dạng bài của kỹ năng đó. **[Đã chốt]**
2. Bài thi thử: danh sách đề luyện; mỗi đề 65 câu, ước tính 2h 15m; bấm vào làm, thoát giữa chừng thì **Tiếp tục** được. **[Đã chốt]**
3. Đề được **tự ghép theo Score Template đang active** (minCount mỗi dạng bài, tổng hiện là 65) từ pool **PRACTICE**, danh sách câu được **ghim** khi tạo đề để đề không đổi khi ngân hàng thay đổi. **[Đã chốt]**
4. Kết quả đề: điểm từng câu (chấm như hiện có) + **điểm ước lượng 4 kỹ năng và tổng** theo trọng số Score Template, ghi rõ "tham khảo". **[Đã chốt]**
5. Đề luôn chạy chế độ **TIMED theo từng câu** bằng engine đã có; lưu và tiếp tục được. **[Đã chốt]**
6. Số đề hiển thị = **số đề đã được tạo** (không giới hạn cố định). **[Đã chốt]**

### Không làm
- Đồng hồ tổng liên tục 2h15m, nghỉ giữa section, khoá màn hình kiểu thi thật.
- UI admin ở pte-web để tạo đề (vòng này tạo bằng API admin + script seed).
- Dùng ExamBlueprint hay câu pool EXAM cho luyện đề (tránh lộ câu thi thật).
- Gói premium / nhãn "Mở khoá": học viên của tổ chức đã có quyền practice.

### Coi là thất bại dù chạy được
- Hai học viên mở "Đề 3" thấy câu khác nhau, hoặc đề đổi câu sau khi ngân hàng thay đổi.
- Đề luyện chứa câu không thuộc pool PRACTICE.
- Thoát giữa đề rồi quay lại bị mất câu đã trả lời hoặc phải làm lại từ đầu.
- Điểm ước lượng hiển thị như điểm chính thức.

## 3. Quyết định đã chốt và quyết định của Claude

| # | Nội dung | Loại |
|---|---|---|
| D1 | Nguồn đề: tự ghép theo minCount của Score Template active, pool PRACTICE, seed cố định theo số thứ tự đề, ghim câu vào bảng | Đã chốt |
| D2 | Kết quả: điểm từng câu + ước lượng 4 kỹ năng/tổng theo trọng số template, nhãn "tham khảo" | Đã chốt |
| D3 | Giờ: TIMED từng câu, thứ tự Speaking → Writing → Reading → Listening, lưu/tiếp tục được; 2h15m chỉ là ước tính hiển thị (tổng prep+response của template, làm tròn 5 phút) | Đã chốt / Claude (cách tính) |
| D4 | Số đề = số đề đã tạo và PUBLISHED | Đã chốt |
| D5 | Ai tạo đề: **hệ thống tự tạo** khi học viên mở danh sách đề, số đề = sức chứa ngân hàng Practice không lặp câu (trần 20); endpoint admin chỉ để thao tác tay | Đã chốt (cách B) |
| D6 | Ghép nhiều đề: trong một lần generate, ưu tiên câu chưa dùng ở đề khác (dùng lại `PracticeQuestionPicker` với "seen" = câu đã ghim ở các đề trước); nếu ngân hàng không đủ thì được lặp câu giữa các đề | Quyết định của Claude |
| D7 | Làm lại đề: được, mỗi lần là một lượt (session) mới; danh sách đề hiển thị lượt gần nhất (Tiếp tục nếu đang làm dở, "Làm lại" + điểm nếu đã xong) | Quyết định của Claude |
| D8 | Phiên kỹ năng (Study-Pack): dùng lại start API với `taskTypeCodes` = mọi dạng bài RUNNABLE của kỹ năng; `questionCount` là **tổng số câu của phiên**, chia đều cho các dạng bài (dư chia cho các dạng đầu); URL `?skill=READING&mode=…&count=…` | Quyết định của Claude |
| D9 | Study-Pack hiển thị "x trên N câu đã trả lời", N = số câu PRACTICE đang có của kỹ năng, x = số câu khác nhau học viên đã trả lời; không có nhãn "Bao gồm mục miễn phí" | Quyết định của Claude |
| D10 | Phiên kỹ năng chọn TIMED chỉ khi mọi dạng bài trong kỹ năng có timing (dùng `PracticeTimingService.covers`) | Quyết định của Claude |

## 4. Hành vi chi tiết

### 4.1 Study-Pack
- Trang liệt kê 4 kỹ năng theo thứ tự Reading, Listening, Speaking, Writing như ảnh tham chiếu (icon tròn xám, tên kỹ năng, dòng phụ "x trên N câu đã trả lời", nút **Luyện tập** màu chính).
- Kỹ năng không có dạng bài nào RUNNABLE → nút tắt, dòng phụ "Chưa có câu luyện tập".
- Bấm Luyện tập → `PracticeModeDialog` với tiêu đề tên kỹ năng; lựa chọn số câu: 10 / 20 / 30 / Tất cả. Ghi nhớ lựa chọn theo khoá `skill:<CODE>`.
- Phiên kỹ năng hiển thị và làm như phiên dạng bài hiện tại (counter, rings, recorder, engine tính giờ cho từng câu).

### 4.2 Danh sách đề (trang Bài thi thử)
- Mỗi hàng: icon, "PTE Academic Full Mock Test N", chip "65 câu" (số câu thực của đề), chip "2h 15m" (ước tính), nút: **Bắt đầu** (chưa làm), **Tiếp tục** (lượt gần nhất đang dở, kèm vòng tiến độ x/65), **Làm lại** + điểm tổng ước lượng (lượt gần nhất đã xong).
- Không có đề nào → trạng thái trống "Chưa có đề luyện".

### 4.3 Làm đề
- Bắt đầu → tạo session `kind = MOCK_TEST`, `timing_mode = TIMED`, items theo đúng thứ tự đã ghim của đề (Speaking → Writing → Reading → Listening, trong mỗi kỹ năng theo `sequence` của template).
- Không có dialog chọn chế độ (đề luôn TIMED). Timing ghim theo từng item như phiên TIMED hiện có.
- Thoát → session giữ IN_PROGRESS; mở lại đề → vào câu chưa trả lời đầu tiên.
- Session mock test không có deadline tổng.

### 4.4 Kết quả đề
- Sau khi nộp: trang kết quả gồm điểm tổng ước lượng, 4 điểm kỹ năng ước lượng (thang 10–90), nhãn "Điểm tham khảo, không phải điểm chính thức", danh sách câu với điểm từng câu (dùng review hiện có).
- Câu đang chấm (AI) → điểm kỹ năng hiển thị "Đang chấm" cho tới khi đủ; câu chấm lỗi bị loại khỏi ước lượng và ghi chú số câu bị loại.

## 5. Ràng buộc kỹ thuật
- Dùng lại: `PracticeQuestionPicker`, `PracticeTimingService`, `PracticeSessionService`/`PracticeSessionItemService`, engine `timed/*`, `PracticeModeDialog`, `ProgressRing`, `AppIcon` (MDI), i18n `common/i18n`.
- Bảng mới (V134): `practice_mock_tests` (public_id, sequence_no unique, title, template_public_id, template_version, status, created_at) và `practice_mock_test_items` (mock_test_id, question_public_id, task_type_code, section, order_index). `practice_sessions` thêm `kind` (`TASK` mặc định, `SKILL`, `MOCK_TEST`) và `mock_test_id` nullable.
- Không gọi `ExamGenerationService` (nó lấy pool EXAM/SHARED).
- Mọi chuỗi UI mới đi qua i18n (en, vi).
- Không phá client cũ: request start không có `skillCode`/`mockTestId` chạy như hiện tại.

## 6. User stories

- **[P1]** Là học viên, tôi muốn luyện cả một kỹ năng từ Study-Pack để ôn một phần thi trong một phiên.
  Đạt khi: bấm Luyện tập ở Reading, chọn Không tính giờ / 10 câu → phiên có 10 câu thuộc ≥ 2 dạng bài Reading (khi ngân hàng có ≥ 2 dạng RUNNABLE).
- **[P1]** Là học viên, tôi muốn thấy danh sách đề luyện và làm một đề đủ 65 câu theo nhịp thi.
  Đạt khi: trang Bài thi thử liệt kê đúng số đề đã tạo; mở Đề 1 → 65 item theo thứ tự Speaking → Writing → Reading → Listening, mỗi câu chạy engine TIMED.
- **[P1]** Là học viên, tôi muốn thoát giữa đề và quay lại làm tiếp.
  Đạt khi: trả lời 5 câu, thoát, mở lại Đề 1 → hàng hiện "Tiếp tục 5/65", vào thẳng câu 6, 5 câu cũ còn nguyên.
- **[P1]** Là quản trị nội dung, tôi muốn tạo thêm đề từ ngân hàng PRACTICE.
  Đạt khi: gọi generate count=2 khi đã có 3 đề → có Đề 4, Đề 5; mỗi đề có đúng minCount câu mỗi dạng; mọi câu thuộc pool PRACTICE; gọi lại GET đề 4 hai lần cho cùng danh sách câu.
- **[P2]** Là học viên, tôi muốn xem điểm ước lượng 4 kỹ năng sau khi làm xong đề.
  Đạt khi: đề đã chấm xong hiển thị 4 điểm kỹ năng + tổng (10–90) và nhãn "tham khảo".
- **[P2]** Là học viên, tôi muốn làm lại một đề.
  Đạt khi: đề đã xong có nút Làm lại; tạo session mới, lượt cũ vẫn trong lịch sử Tiến trình.
- **[P3]** _(ngoài phạm vi)_ UI admin tạo/ẩn đề ở pte-web; đồng hồ tổng 2h15m; xếp hạng giữa học viên.

## 7. Yêu cầu chức năng
1. FR-01: Catalog (`PracticeConstants.PRACTICE_CATALOG_PATH`) trả thêm, cho mỗi section: `practiceQuestionCount` và `answeredQuestionCount` của học viên hiện tại.
2. FR-02: Start session (`PRACTICE_SESSION_PATH`) nhận `skillCode` (tuỳ chọn). Có `skillCode` → server tự lấy mọi dạng bài RUNNABLE của kỹ năng, chia `questionCount` theo D8. `skillCode` và `taskTypeCodes` không được gửi cùng nhau (400).
3. FR-03: `GET /api/v1/practice/mock-tests` trả danh sách đề PUBLISHED theo `sequence_no`, mỗi đề: publicId, title, itemCount, estimatedMinutes, lượt gần nhất của học viên (sessionPublicId, status, answered/total, estimated overall score nếu có).
4. FR-04: Start session (`PRACTICE_SESSION_PATH`) nhận `mockTestId` (tuỳ chọn) → tạo session MOCK_TEST TIMED từ danh sách câu đã ghim. Nếu học viên đã có lượt IN_PROGRESS của đề đó → trả lại lượt đó (idempotent) thay vì tạo mới, trừ khi `restart=true`.
5. FR-05: `POST /api/v1/admin/practice/mock-tests:generate {count: 1..20}` tạo `count` đề mới theo D1/D5/D6; trả danh sách đề đã tạo. Không đủ câu → 422 với dạng bài thiếu.
6. FR-06: `GET {PRACTICE_SESSION_PATH}/{publicId}/review` của session MOCK_TEST trả thêm `estimatedScores {overall, speaking, writing, reading, listening, excludedItemCount, pending}`.
7. FR-07: FE Study-Pack, danh sách đề, nút Tiếp tục/Làm lại, trang kết quả đề như §4.
8. FR-08: Seed script local có tham số `-MockTests N` gọi FR-05.

## 8. Yêu cầu phi chức năng
- Hiệu năng: `GET /mock-tests` p95 < 300 ms với 50 đề trên dữ liệu local; generate 10 đề < 5 s.
- Bảo mật: endpoint generate chỉ cho PLATFORM_ADMIN, ACADEMIC_MANAGER; học viên chỉ thấy đề PUBLISHED và session của chính mình.
- Toàn vẹn: ghim câu trong transaction; tạo đề song song không trùng `sequence_no` (unique constraint + retry).

## 9. Tiêu chí thành công
- [ ] Generate 3 đề trên seed local (`-PerTask 12`) → 3 đề, mỗi đề 65 câu, 100% câu pool PRACTICE.
- [ ] Hai tài khoản học viên mở cùng Đề 2 → cùng 65 `questionPublicId` cùng thứ tự.
- [ ] Phiên kỹ năng Reading 10 câu → đúng 10 item, ≥ 2 dạng bài.
- [ ] Thoát ở câu 6 của đề → quay lại vào câu 6, 5 câu trước còn đáp án.
- [ ] Trang kết quả đề hiển thị 4 điểm kỹ năng + tổng sau khi mọi câu chấm xong, kèm nhãn "tham khảo".
- [ ] BE: test service/controller mới pass; toàn bộ suite pass. FE: tsc, eslint 0 lỗi, vitest pass.

## 10. Câu hỏi còn mở
- Công thức ước lượng điểm kỹ năng: trung bình có trọng số (overallWeight/skillWeight của template) của điểm từng câu quy về thang 10–90 — chấp nhận làm bản đầu, chỉnh sau khi có dữ liệu thật.
