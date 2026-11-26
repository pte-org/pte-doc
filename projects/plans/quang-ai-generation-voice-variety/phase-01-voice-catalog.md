# Phase 01 — Danh mục giọng và cấu hình tắt giọng

**Trạng thái:** [x] [quality: changes fixed, gate not rerun] · **Phụ thuộc:** không
**Story:** nền cho P1 (FR-01, FR-02, FR-04)

## Vấn đề

Giọng nằm trong hai chuỗi CSV `voicesUs`/`voicesUk` (5 giọng) của `QuestionGenerationProperties.Kokoro`; `VoicePicker` tự tách chuỗi. Không có thông tin giới tính, nhãn hiển thị, và không có cách tắt từng giọng.

## Thay đổi

Đường dẫn gốc: `pte-api/app/src/main/java/com/pte/itembank/internal/generation/`.

1. **Danh mục hằng số** `media/KokoroVoiceCatalog.java` (mới). Mỗi giọng gồm mã Kokoro, accent (`US`/`UK`), giới tính (`F`/`M`), nhãn.
   - US nữ: af_heart, af_bella, af_nicole, af_sarah, af_sky.
   - US nam: am_michael, am_adam, am_eric, am_liam, am_onyx.
   - UK nữ: bf_emma, bf_alice, bf_isabella, bf_lily.
   - UK nam: bm_george, bm_daniel, bm_fable, bm_lewis.
   - Đủ yêu cầu ≥ 6 giọng Mỹ và ≥ 4 giọng Anh. Danh mục là record + enum nhỏ, không có logic chọn.
2. **Cấu hình tắt giọng** (`config/QuestionGenerationProperties.java`).
   - Bỏ `voicesUs`, `voicesUk`. Thêm `voicesDisabled` (CSV, mặc định rỗng).
   - Một lớp nhỏ `media/EnabledVoices.java` (bean) lọc danh mục theo `voicesDisabled`. Mã không có trong danh mục: bỏ qua và ghi một dòng cảnh báo khi khởi động (không lặp theo từng lần gọi).
3. **`VoicePicker`** (`media/VoicePicker.java`): bỏ tự tách CSV, đọc danh sách từ `EnabledVoices`. Giữ nguyên hành vi `pick(itemIndex, seed)` cho job đứng riêng (FR-04): seed chọn accent bắt đầu, xoay vòng trong accent. Giọng dự phòng khi không còn giọng nào bật vẫn là `af_heart`.
4. **Biến môi trường.** Trong `application.yml` (dòng 331-332), `pte-api/.env.example` (dòng 238-239) và `docker-compose.services.yml` (dòng 105-106): xóa `QUESTION_GEN_VOICES_US/UK`, thêm `QUESTION_GEN_VOICES_DISABLED` (rỗng). Sửa tay `pte-api/.env.local` (gitignore, không nằm trong kho).
5. **Chuyển cấu hình an toàn.**
   - Lúc khởi động, nếu biến môi trường `QUESTION_GEN_VOICES_US` hoặc `QUESTION_GEN_VOICES_UK` vẫn được đặt thì ghi WARN một lần: "đã bỏ, dùng `QUESTION_GEN_VOICES_DISABLED`". Đọc qua `Environment`; không lỗi và không chặn khởi động.
   - Chạy `docker compose ... config` với cả ba file compose khi không có hai biến cũ, để chắc bước validate của workflow deploy vẫn qua.
   - Ghi vào "Ghi chú khi làm" một bước dọn `.env` trên VPS: xóa hai dòng cũ, thêm `QUESTION_GEN_VOICES_DISABLED` nếu Kokoro thiếu giọng.
   - Đổi giọng khi deploy là **thay đổi có chủ đích**, vì danh mục rộng hơn 5 giọng cũ. Không cố giữ danh mục giống danh sách cũ.
   - Nếu tắt hết giọng của một accent: ghi WARN và lùi về accent còn lại. Nếu tắt hết toàn bộ danh mục: lỗi cấu hình khi khởi động.
5. **Kiểm tra Kokoro thật.** Gọi `GET {KOKORO_BASE_URL}/v1/audio/voices` một lần (qua `curl` với key trong env, không in key). Đối chiếu 18 mã; mã nào thiếu thì ghi vào `QUESTION_GEN_VOICES_DISABLED` của local và prod, và ghi kết quả vào mục "Ghi chú khi làm" của file này.
6. **Test** viết ở phần dưới.

## Design Constraints

- Danh mục là hằng số trong code, không bảng DB, không thêm trường vào form tạo lô (ngoài phạm vi spec).
- Tuân thủ `docs/CODING_STANDARDS_API.md`: hằng số, nhãn và thông báo log cố định đặt trong `*Constants.java` của gói; mỗi file ≤ 300 dòng; mỗi service ≤ 5 phương thức public; gói `internal/**` ≤ 15 class (`media` hiện 9 class, phase này thêm 2).
- Không đổi hành vi chọn giọng của job đứng riêng.
- Log không ghi API key hay text đề.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- `KokoroVoiceCatalogTest`: ≥ 6 US, ≥ 4 UK, mã không trùng, mỗi giọng có accent và giới tính.
- `EnabledVoicesTest`: tắt một giọng thì biến mất khỏi danh sách; mã lạ bị bỏ qua và chỉ ghi cảnh báo một lần; CSV có khoảng trắng và dòng trống vẫn đúng.
- `VoicePickerTest` (sửa test hiện có): job đứng riêng cho kết quả như trước với cùng seed; khi tắt hết một accent thì dùng accent còn lại.
- Chạy: `.\mvnw.cmd -pl app -DskipTests compile`, rồi `.\mvnw.cmd -pl app test -Dtest=KokoroVoiceCatalogTest,EnabledVoicesTest,VoicePickerTest,PackageDensityTest`.

## Hoàn thành khi

- [x] Danh mục có đủ 18 giọng, mỗi giọng có accent, giới tính, nhãn.
- [x] `QUESTION_GEN_VOICES_US/UK` không còn ở code, yml, compose, `.env.example`; `QUESTION_GEN_VOICES_DISABLED` có mặt.
- [x] Đã đối chiếu danh sách giọng với Kokoro thật; giọng thiếu đã bị tắt.
- [x] Job đứng riêng chọn giọng như trước.
- [x] Compile, test nhắm đích và `PackageDensityTest` qua.

## Ghi chú khi làm

- Đối chiếu Kokoro thật (`GET /v1/audio/voices`, 2026-11-26): cả 18 mã trong danh mục đều có trên server, nên `QUESTION_GEN_VOICES_DISABLED` để rỗng ở local. Server còn nhiều giọng khác (ví dụ `af_alloy`, `af_kore`), chưa đưa vào danh mục.
- `docker compose` với cả ba file (`config -q`) qua khi không còn `QUESTION_GEN_VOICES_US/UK`.
- Cổng quality: lần đầu CHANGES_REQUIRED (2 MEDIUM): thiếu WARN khi tắt hết một accent, thông báo lỗi nằm trong code. Đã sửa: WARN ở `EnabledVoices`, hằng `CONFIG_ALL_VOICES_DISABLED`, test bắt log. Chưa chạy lại cổng; 4 test lớp nhắm đích và `PackageDensityTest` qua.
- "Như trước" ở job đứng riêng nghĩa là cùng thuật toán (seed chọn accent đầu, xen kẽ theo index), không phải cùng mã giọng: danh mục tăng từ 5 lên 18 giọng nên mã cụ thể đổi.
- `SourceFileSizeTest` fail sẵn ở `ExamPublishService.java` (322 dòng), không thuộc phase.
- Dọn `.env` trên VPS khi deploy: xóa `QUESTION_GEN_VOICES_US` và `QUESTION_GEN_VOICES_UK`. Không cần thêm `QUESTION_GEN_VOICES_DISABLED` vì Kokoro có đủ 18 giọng. App ghi WARN nếu hai biến cũ còn tồn tại.
- `AGENTS.md` (gốc kho) còn nhắc `QUESTION_GEN_VOICES_US/UK`; để phase 5 dọn.
