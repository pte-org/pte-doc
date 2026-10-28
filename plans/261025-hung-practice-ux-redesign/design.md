# Thiết kế lại UI/UX pte-practice (phần 1/3: giao diện)

**Ngày:** 2026-10-25 · **Owner:** Hung · **Trạng thái:** Chờ duyệt
**Repo:** `pte-practice` (chính), `pte-api` (module `practice`, vài API thống kê)
**Thứ tự đã thống nhất:** (1) giao diện — tài liệu này; (2) kiểm tra dữ liệu & nghiệp vụ còn thiếu; (3) race condition cơ bản. Phần 2 và 3 brainstorm riêng sau.

Quy ước: **[Đã chốt]** = Hung quyết; **[Claude]** = mặc định Claude chọn, Hung đổi được.

## 1. Vì sao
App luyện thi đang chạy được nhưng nhìn chưa như sản phẩm phát hành: bố cục lệch, nhiều khoảng trống hoặc khối vô nghĩa (hàng "—" bấm không được ở Tiến trình), chữ thô ("SPEAKING", "ANSWERED"), chuỗi tiếng Anh cứng ở Review, thiếu xác nhận cho thao tác mất dữ liệu. Mục tiêu: mọi màn trông gọn, hiện đại, nhất quán, **lấy cảm hứng từ app PTE Official AI Practice của Pearson** (không sao chép thương hiệu). **[Đã chốt]**

## 2. Mục tiêu / không làm / thất bại
**Mục tiêu**
- Một ngôn ngữ thiết kế chung cho mọi màn: cột nội dung giữa ~840px trên nền xám nhạt, thẻ trắng bo góc lớn, chữ và thẻ to, khoảng cách rộng rãi (theo ảnh Trang chủ Pearson Hung gửi). **[Đã chốt]**
- Thiết kế lại: Trang chủ, Luyện đề, Study-Pack, Tiến trình, Màn làm bài, Kết quả từng câu, Hoàn thành + Xem lại, Đăng nhập. **[Đã chốt]**
- Toàn bộ chữ qua i18n (en/vi), không còn chuỗi kỹ thuật thô.

**Không làm (phần này)**
- Tính năng mới không có trong các màn đã chốt (mục tiêu ngày, chuỗi ngày học, xếp hạng, premium).
- Đổi sidebar/brand, logic chấm điểm, luồng phiên.

**Thất bại dù chạy được**
- Màn nào còn khối bấm được mà không làm gì, hoặc hiện mã kỹ thuật (SPEAKING, ANSWERED, IN_PROGRESS).
- Vỡ bố cục ở điện thoại (390px) hoặc cuộn ngang.
- Thoát/Bỏ qua làm mất bài mà không hỏi.

## 3. Ngôn ngữ thiết kế chung
- **Bố cục:** cột giữa `max-width ~840px` cho mọi trang; màn làm bài cùng cột. **[Đã chốt — thay quyết định "giãn 1440px" của plan ui-polish; ghi chú để không bị coi là mâu thuẫn]**
- **Thẻ:** nền `--surface`, viền mảnh `--line`, bo 16px, padding 24px; trong thẻ chia dòng bằng đường kẻ mảnh như ảnh mẫu.
- **Chữ:** tiêu đề trang 1.5–1.75rem, tiêu đề thẻ 1.05–1.15rem, chữ thân 1rem, chữ phụ 0.8rem `--muted`.
- **Nút:** đặc (chính, bo tròn), viền (phụ), chữ (thứ cấp); cao ≥ 44px.
- **Chip thông tin:** nền xám nhạt, icon + số ("13 câu", "34 phút").
- **Vòng tiến độ** quanh icon cho thẻ đề/nhóm kỹ năng (đã có `ProgressRing`).
- **Thông báo:** toast cho trạng thái tức thời (đã có); dải gợi ý tím nhạt + icon bóng đèn cho câu gợi ý trong thẻ.
- **Theme:** giữ token light hiện tại và dark xám (`#1e1e1e`) đã làm.

## 4. Từng màn

### 4.1 Trang chủ **[Đã chốt theo ảnh mẫu]**
1. **Thẻ đầu trang:** trái — logo tròn lớn, tên sản phẩm, "Ngày thi: 7 tháng 11 ✎" (đã có `ExamDateLine`); phải — lưới 2×2 bốn thẻ có viền (icon, tên kỹ năng, dòng trạng thái). Bốn thẻ **vẫn là kiểm tra thiết bị** (Mic/Phím/Cỡ chữ/Loa), dòng trạng thái "✓ Đã kiểm tra" / "Kiểm tra ngay". Đáy thẻ: dải gợi ý tím nhạt + bóng đèn (nội dung gợi ý hiện có).
2. **"Đề xuất cho bạn":** hàng thẻ trượt ngang (thẻ thứ 3 ló ra; mũi tên/vuốt). Mỗi thẻ: vòng tiến độ quanh icon, tiêu đề, mô tả 2 dòng, chip "N câu", "N phút", nút "Tiếp tục" (viền, khi đang làm dở) hoặc "Bắt đầu bài thi" (đặc). Nguồn dữ liệu: **đề luyện** (danh sách mock test + lượt gần nhất) và **phiên đang làm dở** (từ Tiến trình). **[Claude: thứ tự — phiên/đề đang dở trước, rồi đề chưa làm theo số thứ tự; tối đa 6 thẻ]**
3. **"Kỹ năng":** mỗi nhóm một thẻ: dòng tiêu đề (icon, "Các mục Nói", "6 câu trả lời", vòng tiến độ bên phải), dưới là từng dạng bài: icon, tên, "N câu trả lời", ô phần trăm (điểm trung bình dạng bài; 0% màu đỏ, thấp đỏ, vừa vàng, cao xanh), mũi tên → bắt đầu luyện dạng đó (không tính giờ, như hiện tại).
4. Dòng "Không gian: {trung tâm}" chữ nhỏ cuối trang (giữ).
- Sửa kèm: tiêu đề gợi ý không lặp tên sản phẩm; "Xem tất cả" mở Study-Pack; tên kỹ năng tiếng Việt.
- **Cần backend:** số câu đã trả lời và điểm trung bình **theo dạng bài** của học viên (mở rộng catalog student hoặc API thống kê riêng).

### 4.2 Luyện đề **[Đã chốt từ ảnh mẫu trước]**
Danh sách thẻ đề: icon tròn tím, tên, chip "65 câu", "2h 15m", nút Bắt đầu/Tiếp tục/Làm lại (giữ hành vi hiện có, kể cả hộp chọn tính giờ). Cùng kiểu thẻ với "Đề xuất cho bạn".

### 4.3 Study-Pack **[Đã chốt từ ảnh mẫu trước]**
Dải tóm tắt "N câu luyện tập" + danh sách 4 kỹ năng (vòng xám quanh icon, tên, "x trên N câu đã trả lời", nút Luyện tập). Giữ hành vi hiện có.

### 4.4 Màn làm bài — theo khung phòng thi của pte-app **[Đã chốt, thay bản mô tả bên dưới]**
Tham chiếu: `pte-app/lib/core/widgets/exam/{exam_shell,exam_header_bar,exam_footer_bar}.dart`, `features/exam_attempt/speaking_writing/presentation/widgets/{recorded_answer_status_card,auto_record_status_card}.dart`, `core/widgets/components/subheader_banner.dart`.
- **Trang làm bài riêng, theo ảnh mẫu Pearson phiên học (app.practice.pearsonpte.com/session) [Đã chốt 2026-10-25]:** route session **không có sidebar và thanh trên của app** (layout riêng), nhưng **không** dùng chế độ toàn màn hình của trình duyệt.
  - **Thanh trên:** trái — tên phiên (đậm) + dòng phụ kỹ năng; phải — "Phần 2 / 3" + "Câu 1 / 1", đồng hồ (icon + `0:09:53`, chỉ khi tính giờ), nút viền "Tạm dừng phiên" (= Lưu & thoát, có xác nhận).
  - **Thanh tiến độ phân đoạn** ngay dưới thanh trên: mỗi phần (kỹ năng / nhóm dạng bài trong phiên) một đoạn, đoạn đã xong đậm, đoạn chưa tới nhạt.
  - **Thân:** hướng dẫn chữ thường cỡ lớn; audio đề là **thanh phát có nút play tròn + dải sóng âm + thời gian `0:00 / 1:24`** (sóng tính từ file, lỗi thì sóng giả lập); bài Viết có **thanh công cụ Copy / Cut / Paste** trên khung soạn thảo và dòng gợi ý "Viết từ 50–70 từ để nộp câu trả lời"; bài Nói dùng thẻ ghi âm (sóng âm `AudioWaveform` khi ghi).
  - **Thanh dưới:** nút viền "Tiếp theo ›" góc phải (nộp câu hiện tại rồi sang câu sau); "Bỏ qua" bên trái (có xác nhận).
  - **Hộp "Kiểm tra phát âm thanh"** khi bắt đầu phiên có Nghe/Nói: icon nốt nhạc, mô tả, trình phát câu mẫu có sóng âm + thời gian, "Bạn sẽ nghe thấy: *This is a test playback…*", mục gập "Khắc phục sự cố âm thanh", ô "Bỏ qua bước kiểm tra này vào lần sau" (lưu trình duyệt), nút "Xác nhận âm thanh". Dùng chung logic với kiểm tra loa ở Trang chủ (đánh dấu đã kiểm tra).
  - Nền theo token theme; nội dung trái rộng tối đa ~960px (bài Đọc 1160px) như ảnh.
- **Thanh trên 56px** (nền trắng, viền dưới): trái "PTEPrep" | tên phiên; phải nút kiểm tra âm thanh (mở `DeviceCheckDialog` loa), "Câu 3 / 10", đồng hồ (icon + số tabular, chỉ khi tính giờ), nút "Lưu & thoát". < 1080px: một hàng rút gọn.
- **Banner đề bài:** nền `#EDF4FF`, viền mảnh, bo 3px; tên dạng bài (đậm) + hướng dẫn.
- **Thẻ "Câu trả lời ghi âm"** (bài Nói): nền xanh lá nhạt, "Trạng thái:" + dòng đậm ("Bắt đầu sau 25 giây" / "Đang ghi · còn 30 giây" / "Đã lưu · sẵn sàng tiếp tục"), **sóng âm khi đang ghi (giữ `AudioWaveform` hiện tại)**, thanh tiến độ. Chế độ không tính giờ: thêm nút Ghi / Nghe lại / Ghi lại trong thẻ.
- **Thanh dưới 56px** (nền trắng, viền trên): trái "Bỏ qua" (viền), phải "Nộp & tiếp →" (đặc, có trạng thái đang tải).
- **Giữ nguyên y hệt logic hiện tại** của chế độ tính giờ / không tính giờ (`timed/*`, `TimedTaskFrame`, `SpeakingRecorder`): chỉ đổi phần trình bày, không đổi pha, thời gian, phát-một-lần, tự ghi, hay luồng lưu bản ghi. **[Đã chốt]**
- Màu nhấn màn làm bài: dùng màu của pte-app — `--exam-primary #004787`, hover `#094C8B`, active `#073B6D`, thanh tiến độ ghi âm `#004787`. **[Đã chốt]** (Phạm vi: màn làm bài; các màn khác giữ màu nhấn hiện tại — **[Claude]**, đổi cả app thì thay token `--accent`.)
- Vẫn giữ: thẻ kết quả từng câu sau khi nộp, xác nhận Thoát/Bỏ qua, cảnh báo đóng tab khi đang ghi.

#### (Bản mô tả cũ, đã được thay bằng mục trên)
- Thanh trên: nút Thoát, thanh tiến độ, "Câu 3/10 · Nói · Read Aloud", đồng hồ khi tính giờ.
- Thẻ lớn: hướng dẫn (chữ phụ) → đề bài chữ to (≤ 75 ký tự/dòng) → khu trả lời (recorder/ô nhập/lựa chọn).
- Thanh hành động dính đáy: "Bỏ qua" (trái), "Nộp bài →" (phải).
- Thoát và Bỏ qua hỏi xác nhận (Modal). Đóng tab/tải lại khi đang ghi âm hoặc đang tải bản ghi → cảnh báo trình duyệt (`beforeunload`).
- Tên kỹ năng tiếng Việt; bỏ "×" trùng với "Lưu & thoát".

### 4.5 Kết quả từng câu **[Đã chốt]**
Thẻ: vòng điểm lớn (x/100), điểm thành phần dạng thanh ngang, nhận xét AI, nghe lại bản ghi, transcript (nếu có), nút "Câu tiếp theo →". Đang chấm: vòng xoay + "thường mất khoảng 20 giây", không chặn sang câu sau.

### 4.6 Hoàn thành phiên + Xem lại **[Đã chốt]**
- Thẻ hoàn thành: "Hoàn thành", số câu đã làm/tổng, điểm trung bình; nút "Xem lại bài", "Luyện tiếp dạng này" (cùng dạng bài / kỹ năng, không tính giờ), "Trang chủ".
- Xem lại: danh sách câu dạng thẻ thu gọn (tên dạng bài, trạng thái tiếng Việt, điểm) → bấm mở chi tiết câu trả lời + điểm. Phiên đề luyện: khối điểm ước lượng 4 kỹ năng ở đầu (đã có). Bỏ chuỗi tiếng Anh cứng (`UI_TEXT`).

### 4.7 Tiến trình **[Đã chốt]**
- 4 ô số: Phiên, Hoàn thành, Câu đã trả lời, Điểm trung bình (thay ô "Tasks reviewed" sai nghĩa).
- Tab Nói | Viết | Đọc | Nghe: mỗi dạng bài — số câu, điểm trung bình (%), nút Luyện.
- Lịch sử: tên rõ ("Luyện Reading · 10 câu", "Mock Test 1", "Read Aloud · 10 câu"), ngày, trạng thái tiếng Việt, nút "Tiếp tục" (đang làm) / "Xem lại" (đã xong). Bỏ hàng "—" bấm không được.
- **Cần backend:** dùng chung thống kê theo dạng bài với Trang chủ; tên hiển thị phiên theo loại (TASK/SKILL/MOCK_TEST).

### 4.8 Đăng nhập **[Đã chốt]**
Giữ bố cục; báo lỗi ngay dưới ô, nút có trạng thái đang tải rõ, Enter để gửi, bỏ "Confidence: high" trong minh hoạ.

## 5. Ràng buộc

**Quy tắc tái sử dụng (bắt buộc, trước khi viết bất kỳ UI nào)** **[Đã chốt]**
1. Tìm trước trong `pte-practice/common/components` — có thì dùng.
2. Chưa có → tìm trong `pte-web/packages/ui/src` (`@pte/ui`: components, hooks, icons). Có thì **port** vào `pte-practice/common/components` giữ **nguyên tên và API props** (như đã làm với `Modal`, `Toast`), comment đầu file ghi nguồn port, style bằng token CSS của practice — để sau này đổi sang import `@pte/ui` chỉ cần sửa import.
3. Cả hai đều không có → tạo component mới trong `pte-practice/common/components` với API theo phong cách `@pte/ui` (props, tên), không viết thẳng trong view.
4. Ghi trong báo cáo cuối: component nào dùng lại, port từ đâu, component nào tạo mới và lý do.

- Dùng lại component có sẵn: `Modal`, `Toast`, `ProgressRing`, `AppIcon`, `CountdownTimer`, `Stepper`, `ExamDateLine`, `DeviceCheckDialog`. Không thêm thư viện UI.
- CSS thuần + token trong `app/globals.css`; light và dark (xám) đều đạt tương phản AA.
- File > 300 dòng tách nhỏ; hàm thuần có test vitest.
- Không đổi hợp đồng API phiên hiện có; API mới chỉ thêm.

## 6. Làm rõ sau builder check **[Claude — Hung kiểm tra khi đọc]**
1. **Thống kê theo dạng bài** (Trang chủ 4.1.3, Tiến trình 4.7): *số câu trả lời* = số câu hỏi khác nhau học viên đã trả lời (giống Study-Pack, đếm `sourceQuestionPublicId` của item ANSWERED, mọi loại phiên). *Điểm trung bình* = trung bình điểm (0–100) của các item ANSWERED **đã chấm xong** (bỏ qua câu bỏ qua / đang chấm / chấm lỗi), mọi loại phiên. Chưa có điểm nào → hiện "—" xám, **không** hiện 0% đỏ (0% chỉ khi điểm thật là 0).
2. **Ngưỡng màu điểm:** < 40 đỏ, 40–69 vàng, ≥ 70 xanh.
3. **Tiêu đề nhóm kỹ năng:** "N câu trả lời" và vòng tiến độ dùng lại `answeredQuestionCount` / `practiceQuestionCount` của section (đã có trong catalog, giống Study-Pack).
4. **Thẻ "Đề xuất":** vòng = câu đã làm / tổng câu. Phiên TASK/SKILL đang dở: tiêu đề "Read Aloud" / "Luyện Đọc", mô tả "Đang làm dở · x/y câu", không có chip phút. Mỗi phiên / đề là một thẻ riêng. "Xem tất cả" cạnh "Đề xuất" → Luyện đề; "Xem tất cả" cạnh "Kỹ năng" → Study-Pack.
5. **Thẻ thiết bị:** trạng thái lưu trên trình duyệt, hiệu lực 7 ngày (đã có, không đổi).
6. **Tên phiên ở Tiến trình:** backend thêm vào mục lịch sử `kind`, `skillCode`, `taskCode` (phiên 1 dạng), `mockTestTitle`; frontend ghép chuỗi theo i18n.
7. **"Luyện tiếp dạng này":** chỉ hiện với phiên TASK/SKILL; phiên đề luyện không hiện nút này.
8. **Thoát:** hỏi xác nhận rồi **lưu & thoát** (giữ bài nháp như hiện tại); nếu bản ghi đang tải lên → chờ xong rồi mới thoát. **Bỏ qua:** hỏi xác nhận, câu bị bỏ qua không làm lại được trong phiên.
9. **Kiểm chứng:** không có test hình hiện tại; kiểm chứng tay bằng Playwright ảnh chụp 390px và 1280px × light/dark cho mọi màn; không thêm visual regression.

## 7. Phần 2 — kiểm tra dữ liệu & nghiệp vụ còn thiếu **[Đã chốt]**
1. **Số từ bài Viết:** dưới min / trên max → bộ đếm đổi màu cảnh báo; bấm Nộp → hỏi "Bài viết có {n} từ (yêu cầu {min}–{max}), vẫn nộp?"; vẫn cho nộp.
2. **Bản ghi quá ngắn / im lặng:** < 1 giây hoặc mức âm lớn nhất < 0.01 → cảnh báo "Bản ghi quá ngắn / không có tiếng" với nút "Ghi lại" và "Vẫn lưu".
3. **Mất mạng:** `offline` → toast "Mất kết nối", khoá Nộp/Bỏ qua/Thoát; `online` → toast "Đã kết nối lại", mở khoá; bài nháp giữ nguyên.
4. **Danh sách đề trống:** nói lý do "Ngân hàng câu hỏi chưa đủ để tạo đề luyện. Hãy quay lại sau."
5. **Đăng nhập:** trim ô tài khoản, báo ngay ô trống, khoá nút khi đang gửi.

## 8. Phần 3 — race condition cơ bản **[Đã chốt]**
1. **Hai tab cùng phiên:** lỗi xung đột version (409 / `PRACTICE_STALE_SESSION_VERSION`) → tự tải lại phiên mới nhất + toast "Phiên đã thay đổi ở tab khác"; bài nháp cục bộ của câu hiện tại giữ nguyên.
2. **Phản hồi cũ ghi đè:** Trang chủ, Luyện đề, Tiến trình, Ngày thi chỉ nhận kết quả lần tải mới nhất (bộ đếm yêu cầu / AbortController), huỷ khi rời trang.
3. **Rời trang khi đang ghi/tải bản ghi:** ngoài `beforeunload`, bấm menu trong app → hỏi xác nhận.
4. **Bấm liên tục:** lưu ngày thi, bắt đầu/làm lại đề, bắt đầu luyện → khoá nút đến khi xong.
5. **Làm mới token đồng thời:** nhiều request cùng 401 → chỉ một lần gọi refresh, các request khác chờ kết quả đó (single-flight); refresh thất bại → đăng xuất một lần.

## 9. Để lại cho người làm
- Chi tiết spacing/màu từng thành phần trong khuôn khổ mục 3.
- Cách trượt ngang của "Đề xuất" (CSS scroll-snap là đủ).
- Hình dạng API thống kê theo dạng bài (một endpoint hay mở rộng catalog).
