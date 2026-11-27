# Phase 02 — Chia giọng theo vị trí trong lô

**Trạng thái:** [x] [quality: findings fixed, gate not rerun] · **Phụ thuộc:** phase 01
**Story:** P1 "lô tự dùng nhiều giọng" (FR-03, FR-04)

## Vấn đề

Mỗi job chọn giọng độc lập từ `jobPublicId`. `JobClaim` không mang thông tin lô, nên pipeline không biết câu đứng thứ mấy trong lô. Hai câu liền nhau vẫn có thể trùng giọng.

## Quyết định thiết kế

Giọng là **hàm xác định** của `(seed lô, vị trí toàn lô)`, không lưu theo slot.
- Vị trí toàn lô **chỉ đếm câu có audio** = tổng `requested_count` của các job cùng lô **có dạng bài phát audio** và `batchSeq` nhỏ hơn, cộng index câu trong job. Câu text không chiếm vị trí, nên lô hỗn hợp vẫn xen kẽ accent và cân bằng. `BatchSplitter` đánh `seq` liên tục nên tổng này khớp thứ tự lô.
- **Cần xác minh trước khi code:** `requested_count` và `batch_seq` không đổi sau khi tạo job, kể cả khi job được retry, bị hủy hoặc bị tách lại. Đọc `QuestionGenerationBatchService`, `BatchChainingService`, `BatchReconciler` và đường retry của job.
  - Nếu có đường nào tạo job thay thế hoặc giảm `requested_count`, thì job đó đi đường cũ (`batchPosition` null) và ghi chú lại.
  - Ghi kết quả xác minh vào "Ghi chú khi làm".
- Seed lô = `batch.publicId.getLeastSignificantBits()`.
- Thuật toán (lớp `VoiceAssigner`): xáo từng nhóm (accent, giới tính) bằng seed lô (`SplittableRandom`). Vị trí `p`: accent đổi mỗi bước (`p` chẵn/lẻ, accent bắt đầu theo seed); giới tính đổi mỗi 2 bước; giọng trong nhóm = nhóm[(p / 4) mod kích thước]. Hai câu liền nhau luôn khác accent nên khác giọng; mỗi accent 50%; nam/nữ 40-60% với lô ≥ 6 câu. Nhóm rỗng (do tắt giọng) thì lùi về giới tính khác cùng accent, rồi accent khác.
- Không lưu: tránh cột mới, migration, và đồng bộ khi job bị hủy hay chạy lại. Job chạy lại có cùng vị trí nên cùng giọng.

## Thay đổi

Đường dẫn gốc: `pte-api/app/src/main/java/com/pte/itembank/internal/generation/`.

1. **Claim mang vị trí lô.** `pipeline/JobClaim.java` thêm thành phần `batchPosition` (record nhỏ `BatchPosition(long seed, int offset)`, null cho job đứng riêng); giữ các constructor phụ hiện có để test cũ không vỡ.
2. **Tạo claim.** `worker/JobLeaseService.claimOf` điền `batchPosition`: lấy `batchId` (đã có `jobs.findBatchIdById`), đọc `publicId` lô và truy vấn tổng `requested_count` của các job cùng lô có `batch_seq` nhỏ hơn (thêm một truy vấn vào repository job hiện có). Lô khóa trước, job sau đúng thứ tự khóa hiện tại; truy vấn đọc không đổi thứ tự khóa.
3. **`VoiceAssigner`** (`media/VoiceAssigner.java`, mới, hàm thuần, không Spring ngoài việc nhận `EnabledVoices`): trả mã giọng cho `(seed, position)`.
4. **`VoicePicker`**: thêm `pick(itemIndex, seed, batchPosition)`; `batchPosition` null thì đi đường cũ (FR-04), khác null thì gọi `VoiceAssigner` với `offset + itemIndex`.
5. **Truyền xuống.** `pipeline/GenerationPipeline.java` (dòng ~166) truyền `claim.batchPosition()` vào `MediaRenderer.render`; `media/MediaRenderer.java` chuyển tham số xuống `speak` và `converse`. Với hội thoại, người nói đầu tiên (hoặc người dẫn) lấy giọng của lô, các người còn lại lấy giọng khác theo `distinctVoices` hiện có, ưu tiên khác giới tính.
6. **Meta.** `generation_meta.media.voice` đã có; không thêm trường.

## Design Constraints

- Tuân thủ `docs/CODING_STANDARDS_API.md`: không đọc giờ trực tiếp (không cần `Clock` ở đây), hằng số trong `*Constants.java`, file ≤ 300 dòng (`MediaRenderer.java` đang 239 dòng, chỉ thêm tham số; nếu gần trần thì trích phần hội thoại ở phase 5), service ≤ 5 phương thức public, gói `media` ≤ 15 class (sau phase này có 11).
- Job đứng riêng và job chạy lại cho kết quả như cũ khi cùng seed.
- Không thêm cột hay migration; không đổi API công khai của lô.
- `@Transactional` chỉ ở service; truy vấn thêm là đọc.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Test

- `VoiceAssignerTest`: lô 10 vị trí với nhiều seed: US/UK mỗi bên 4-6, có cả nam và nữ, 0 cặp liền nhau trùng giọng; cùng seed cho cùng kết quả; seed khác cho thứ tự khác; tắt hết giọng nam của một accent vẫn trả giọng hợp lệ và không trùng liền kề.
- `VoicePickerTest`: `batchPosition` null giữ hành vi cũ.
- `JobLeaseServiceTest` (sửa):
  - Claim của job trong lô có `offset` đúng: job `seq` 2 đứng sau hai job audio 5 câu và 3 câu thì có offset 8.
  - Job text đứng giữa không làm tăng offset.
  - Job đứng riêng có `batchPosition` null.
- Lô hỗn hợp `[audio, text, audio, text, …]`: các câu audio vẫn xen kẽ accent.
- Job retry: cùng vị trí thì cùng giọng. Nếu đi đường job thay thế, kiểm tra nó dùng đường cũ.
- `GenerationPipelineTest` (sửa): pipeline truyền vị trí cho `MediaRenderer`.
- Chạy: `.\mvnw.cmd -pl app test -Dtest=VoiceAssignerTest,VoicePickerTest,JobLeaseServiceTest,GenerationPipelineTest,PackageDensityTest,SourceFileSizeTest` (`SourceFileSizeTest` fail sẵn ở `ExamPublishService.java`, không thuộc phase).

## Hoàn thành khi

- [x] Lô 10 câu Repeat Sentence ở test: US/UK mỗi bên 4-6, có nam và nữ, 0 cặp liền nhau trùng giọng.
- [x] Giọng lặp lại được với cùng seed lô, kể cả khi job chạy lại.
- [x] Job đứng riêng chọn giọng như trước.
- [x] Compile và test nhắm đích qua; build lại container `app` local.

## Ghi chú khi làm

- Đã xác minh: `requested_count` và `batch_seq` là `updatable=false` trong `QuestionGenerationJob`, và không có đường retry nào tạo job thay thế, nên vị trí trong lô ổn định.
- `BatchPosition` đặt trong gói `media` (không phải `pipeline`) để tránh vòng phụ thuộc media → pipeline. Gói `media` có 13 class.
- Chỉ dạng bài có `requiresAudioPrompt()` chiếm vị trí. `READ_ALOUD` không dùng audio nên không chiếm.
- Hội thoại: mỗi người nói lấy vị trí kế tiếp của dãy lô (`offset + n`), nên khác accent và giới tính với người trước.
- Khi một accent bị tắt hết, hai câu liền nhau cùng accent và chỉ khác nhau nhờ giới tính và thứ tự xáo; không đảm bảo khác giọng tuyệt đối. Đã ghi trong Javadoc của `VoiceAssigner.assign`.
- Cổng quality: CHANGES_REQUIRED lần đầu (`GenerationPipeline.java` 301 dòng, hội thoại, thiếu test). Đã sửa hết; user yêu cầu bỏ cổng quality từ đây nên không chạy lại.
- Chưa có test cho đường hội thoại của `MediaRenderer` (cần dựng nhiều mock).
