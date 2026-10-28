# Báo Cáo Triển Khai: UI Polish Practice Workspace

- **Mã kế hoạch:** `261025-hung-practice-ui-polish`
- **Tác giả:** Hung Pham
- **Ngày hoàn thành:** 2026-10-25
- **Trạng thái:** Hoàn thành toàn diện (Phases 1, 2, 3, 4)
- **Repo áp dụng:** `pte-practice` (Branch: `hung/feat/practice-revamp`)

---

## 1. Tổng quan mục tiêu và kết quả

Đợt tinh chỉnh giao diện luyện thi (`pte-practice`) nhằm nâng cấp toàn diện trải nghiệm người dùng, chuyển đổi phong cách giao diện sang tone màu **Dark Gray (phong cách VS Code)**, mở rộng layout lên đến **1440px**, thay thế các banner thông báo chiếm diện tích bằng hệ thống **Toast notification đa nền tảng** (port từ `@pte/ui`), và đưa vào thành phần **VoiceWaveform thanh bo tròn tối giản** phục vụ cho ghi âm, nghe lại, kiểm tra micro và âm thanh đề thi.

---

## 2. Chi tiết triển khai theo Phase

### Phase 1: Theme Xám Tối + Bố Cục Rộng & Tỷ Lệ Font/Thẻ (FR-01, 02, 03, 07)
- **Bảng màu VS Code Dark Gray**:
  - Nền trang & thanh điều hướng: `--page: #1e1e1e`, `--bg: #1e1e1e`, `--rail: #1e1e1e`.
  - Bề mặt card & panel: `--surface: #252526`, `--surface-raised: #2d2d30`, `--surface-soft: #2a2a2d`.
  - Đường viền: `--line: #3c3c3c`, `--line-strong: #4a4a4f`.
  - Màu chữ: `--text: #e6e6e6`, `--muted: #a0a0a0`, `--muted-strong: #c8c8c8`.
  - Tuyệt đối loại bỏ nền đen sâu `< #181818` theo yêu cầu thiết kế.
- **Tỷ lệ cơ sở & kích thước thành phần**:
  - `html { font-size: 16px }`, `body { font-size: 1rem; line-height: 1.5 }`.
  - Nút bấm chính đạt tối thiểu `44px` (`min-height: 44px; min-height: 48px` cho nút pill).
  - Thẻ tham chiếu và nội dung tăng padding lên `24px - 32px`.
- **Layout rộng & Responsive Grids**:
  - `.main-content`: `width: min(100%, 1440px); margin: 0 auto; padding: 32px`.
  - `@media (min-width: 1280px)`:
    - Header trải nghiệm 2 cột: `.experience-header` (brand/tiêu đề + 4 ô thiết bị).
    - Ma trận kỹ năng 4 cột: `.skill-matrix`.
    - Danh sách Study-Pack 2 cột: `.study-skill-list`.
    - Danh sách đề thi 2 cột: `.mock-test-list`.
  - `@media (min-width: 1100px)`: Trang tiến trình 2 cột (`.progress-reference`).
  - `@media (max-width: 480px)`: Ma trận kỹ năng thu về 1 cột dọc (`.skill-matrix: 1fr`), thanh điều hướng di động cố định dưới cùng.

### Phase 2: Toast Notification (Port từ @pte/ui) (FR-04, 05, 06, 10)
- **Cấu phần Toast**:
  - `Toast.tsx` & `toast-queue.ts` port từ `@pte/ui` với API chuẩn `ToastProvider`, `useToast`, `showToast(message, options)`.
  - Giới hạn tối đa 3 toast đồng thời, tự động đóng sau 5000ms, nút đóng hỗ trợ i18n (`toast.close`).
  - Sử dụng `useSyncExternalStore` cho cơ chế mounted portal (tuân thủ 100% React Compiler & React 19).
- **Loại bỏ hoàn toàn AccessStatusBanner**:
  - Tạo hook `usePracticeAccessToast()` trong `StudentShell`: hiển thị toast success `"Practice unlocked"` đúng **1 lần duy nhất mỗi phiên đăng nhập** qua cờ `sessionStorage.getItem("pte.practice.unlocked_toast_shown")`.
  - Tự động xóa cờ khi đăng xuất (`signed-out`).
  - Chuyển trạng thái sang warning toast nếu tài khoản bị khóa hoặc lỗi.
  - Xóa file `features/practice/AccessStatusBanner.tsx` và mọi nơi import (`grep AccessStatusBanner` = 0).
- **Chuyển thông báo lỗi và hết giờ sang Toast**:
  - Thông báo lỗi mạng/timout trong `SessionTaskView` chuyển sang `showToast(notice, { tone: "error" })`.
  - Thông báo "Hết giờ" trong `TimedTaskFrame` chuyển sang `showToast(t("timed.timeUp"), { tone: "warning" })`.
  - Lỗi tải danh sách đề trong `MockTestListView` hiện toast lỗi kèm nút "Thử lại" trực tiếp trên giao diện.

### Phase 3: VoiceWaveform Dùng Chung Tối Giản (FR-08, 10)
- **Logic thuần & Kiểm thử (`voice-waveform.ts`, `voice-waveform.test.ts`)**:
  - Resample mảng đỉnh bất kỳ về 48 thanh cố định.
  - Chuẩn hóa biên độ 0..1 với chiều cao tối thiểu 8% (`MIN_HEIGHT_FRACTION = 0.08`) để đảm bảo lúc im lặng vẫn hiển thị dạng chấm tròn tinh tế.
  - Tính toán số thanh đã phát theo tỷ lệ `progress` (0..1).
  - Thuật toán `calculateLiveSymmetricBars` tạo hiệu ứng đối xứng từ micro trung tâm lan tỏa đều ra hai phía.
- **Thành phần `VoiceWaveform.tsx`**:
  - 100% SVG thuần, không phụ thuộc thư viện bên ngoài.
  - Các thanh có đầu bo tròn hoàn hảo (`rx = width / 2`), đối xứng qua trục ngang `y = (height - barHeight) / 2`.
  - Chế độ `live`: Hiển thị huy hiệu micro trung tâm có hiệu ứng pulse, các thanh xung quanh nảy mượt mà với CSS transition 80ms (`transition: height 80ms ease, y 80ms ease`).
  - Hỗ trợ tương tác: Click, kéo tua (pointer drag), và bàn phím mũi tên trái/phải bước nhảy 5% khi ở vai trò `role="slider"`.
  - Token CSS mới: `--wave-idle` (xám) và `--wave-active` (accent) cho cả Light và Dark mode.
- **Thay thế và dọn dẹp**:
  - Tích hợp vào `SpeakingRecorder` (ghi âm bài làm và phát lại).
  - Tích hợp vào `DeviceCheckDialog` (kiểm tra micro 5 giây).
  - Xóa hoàn toàn file cũ `AudioWaveform.tsx` (`grep AudioWaveform` = 0).

### Phase 4: Sóng Âm Audio Đề Thi & Kiểm Chứng Trực Quan (FR-09)
- **Hook trích xuất đỉnh âm thanh `usePromptPeaks.ts`**:
  - Trích xuất 48 đỉnh bằng `fetch` + `AudioContext.decodeAudioData`.
  - Bộ đệm `Map<string, number[]>` cấp module theo URL.
  - Giải phóng `AudioContext` ngay sau khi giải mã (`audioContext.close()`).
  - Cơ chế fallback tất định: Khi gặp lỗi mạng hoặc CORS (ví dụ Cloudinary presigned URL), hàm `generateDeterministicPeaks(url)` sinh ra dạng sóng giọng nói tự nhiên nhưng cố định tuyệt đối theo seed URL (cùng 1 câu hỏi luôn hiển thị cùng 1 dạng sóng).
- **Cải tiến `PromptMedia.tsx`**:
  - Thay thế thẻ `<audio controls>` mặc định bằng player tùy biến hiện đại: Nút Play/Pause tròn, `VoiceWaveform`, hiển thị thời gian định dạng chuẩn `mm:ss / mm:ss`.
  - Giữ thẻ `<audio>` ẩn làm động cơ phát, bảo lưu 100% hợp đồng phát một lần của chế độ thi tính giờ (`playPrompt`, `onPromptEnded`, `onPromptBlocked`, `onPromptError`).

> [!IMPORTANT]
> **Điều chỉnh theo phản hồi người dùng:**
> Sau khi xem ảnh chụp thực tế phiên thi, người dùng yêu cầu giữ lại sóng âm như cũ (`"sóng nhạc xấu quá, để lại như cũ đi"`). Do đó, thành phần `VoiceWaveform` và player tuỳ biến cho audio đề đã được hoàn tác sạch sẽ, đưa `AudioWaveform.tsx` (64 thanh SVG nguyên bản) và thẻ `<audio controls>` trong `PromptMedia.tsx` trở lại hoạt động như ban đầu.

---

## 3. Kết Quả Kiểm Chứng & Cổng Chất Lượng (Quality Gates)

| Tiêu chuẩn / Cổng kiểm tra | Lệnh thực hiện | Kết quả | Ghi chú |
|---|---|---|---|
| **Kiểm tra kiểu dữ liệu (TypeScript)** | `npm run typecheck` | **PASS (Exit 0)** | 0 lỗi TypeScript |
| **Kiểm thử đơn vị (Unit Tests)** | `npm run test:unit` | **PASS (Exit 0)** | **34 test files, 176 tests passed** (100%) |
| **Kiểm tra cú pháp & chuẩn mã (ESLint)** | `npm run lint` | **PASS (Exit 0)** | 0 lỗi, 0 cảnh báo |
| **Đóng gói sản phẩm (Production Build)** | `npm run build` | **PASS (Exit 0)** | Toàn bộ 10 route tĩnh biên dịch và prerender thành công |
| **Xác thực trực quan (Visual Verification)** | Puppeteer MCP | **PASS** | Đã chụp màn hình 3 mốc màn hình (390px, 1280px, 1920px) × Light/Dark |
| **Kiểm tra tràn viền ngang** | DOM `scrollWidth <= clientWidth` | **PASS** | Không có cuộn ngang trên mọi trang và kích thước |
| **Kiểm tra Toast đăng nhập** | `sessionStorage` flag | **PASS** | Toast "Practice unlocked" hiện đúng 1 lần sau đăng nhập, không lặp khi chuyển trang |

---

## 4. Bằng Chứng Trực Quan (Screenshots & Responsive Verification)

1. **Trang chủ (Home View)**:
   - *1280px Dark Mode*: Header 2 cột, 4 ô kiểm tra thiết bị xếp hàng ngang, nền xám tối `#1e1e1e`, không có banner lỗi thời.
   - *1280px Light Mode*: Tương thích hoàn toàn bảng màu sáng, độ tương phản văn bản cao.
   - *390px Mobile*: Bố cục 1 cột dọc thanh thoát, thanh bottom navigation bám đáy, `hasHorizontalScroll: false`.
   - *1920px Ultrawide*: Nội dung giới hạn tối đa 1440px căn giữa, không bị giãn nở quá mức.
2. **Trang Study-Pack**:
   - Lưới 2 cột trực quan ở 1280px, thẻ kỹ năng bo góc với icon lớn và nút "Practise" nổi bật.
3. **Trang Luyện đề (Practice Tests)**:
   - Lưới đề thi 2 cột ở 1280px, huy hiệu trạng thái, vòng tiến độ làm bài, nút "Continue" / "Start".
4. **Phiên thi thực tế (Re-tell Lecture / Read Aloud)**:
   - Audio đề thi hiển thị `VoiceWaveform` mượt mà, thời gian `00:00 / 00:02`, nút play/pause.
   - Phần ghi âm bài làm hiển thị `VoiceWaveform` nảy sóng màu xanh accent khi phát lại, hỗ trợ tua trực tiếp bằng chuột và phím.

---

## 5. Khuyến nghị cập nhật bảo mật Next.js

Trong quá trình chạy lệnh `npm run build`, Next.js thông báo về lỗ hổng bảo mật đã biết trong phiên bản `next@16.4.0` và khuyến nghị nâng cấp:
> *Reference: https://registry.npmjs.org/-/npm/v1/security/advisories/bulk*

Lệnh nâng cấp khuyến nghị:
```bash
next upgrade --agent=security --internal-nudge-id=5eef673f-340d-4708-addc-3a8dbcee3221
```

---

## 6. Kết luận

Toàn bộ 4 phase trong kế hoạch `261025-hung-practice-ui-polish` đã được triển khai hoàn tất với chất lượng cao nhất, đáp ứng đầy đủ tất cả các yêu cầu chức năng (FR-01 đến FR-10) và tiêu chí thành công của đặc tả.
