# Research: giao diện Practice và các phương án AI

Date: 2026-10-22. Read-only source review; chưa thực thi UI/provider.

## Frontend cần hoàn thiện

| Source | Hiện tại | Đầu ra cần có |
|---|---|---|
| `pte-practice/features/practice/renderer-allowlist.ts` | 9 renderer được phép chạy | Ma trận task/runtime/media/answer/result cho catalog được xác nhận; không bật toàn bộ chỉ bằng mở allowlist |
| `renderers/BlankRenderer.tsx`, `task-content.ts` | 2 blank hardcode, mất blankIndex, option identity từ orderIndex | Stable option/blank/token IDs, dữ liệu blank thực tế, rule reuse và bàn phím |
| `features/practice/contracts.ts` | Prompt/word counts/options, chưa source media | Additive prompt audio/image, passage/token structure, timing/playback policy, schema version |
| `renderers/RecordingRenderer.tsx` | Capture WAV/upload | Source playback, recording preview, giữ blob retry, grant/upload/bind states, permission/device recovery |
| `PracticeSessionView.tsx` | Lifecycle có retry/idempotency, completion chỉ thống kê | Resume, review route, read-only responses, objective result, rubric, AI pending/failure/retry |
| `session-storage.ts` | Draft thiếu confidence; namespace session/item | Account/context namespace, draft version/confidence/pending state, logout/shared-PC cleanup |
| `features/progress/ProgressView.tsx` | Presentation thiên Speaking; không resume/review, hasMore chỉ nhãn | Dữ liệu 4 kỹ năng, cursor pagination, link vào phiên, tách hoạt động/điểm/confidence/AI |
| `features/studyPack/StudyPackView.tsx` | Static pack, mọi CTA về catalog chung | Filter group thực; chưa hứa completion theo pack khi D03 chưa chốt |

## Phương án đề xuất

Giải thích chuẩn theo question revision + giải thích cá nhân hóa theo bản nộp. Giải thích chuẩn cho phép Student học khi Gemini lỗi, nhưng không giả làm AI đã xử lý bài. Khách quan vẫn cần evaluator; Writing/Speaking có rubric và evidence thiếu thì báo hạn chế. Không cần open chat hoặc vector database cho bước này.

Trải nghiệm xem kết quả: bài đã nộp -> kết quả/đáp án cho phép hiển thị -> tiêu chí rubric -> nhận xét AI có dẫn chứng -> gợi ý luyện tiếp. Kết quả pending/failed độc lập trạng thái bài. Retry hiển thị cooldown; refresh đọc cùng explanation ID. Không mở đáp án trước khi item submit, kể cả response payload/HTML/media transcript ẩn.

## Quyết định kế thừa

- D01 Academic/Core: khuyến nghị Academic-oriented trên vocabulary backend hiện có; 23 canonical task types là inventory kiểm tra, chưa là cam kết 23 task thuộc cùng sản phẩm. `WRITE_EMAIL` chưa có contract, video chưa có evidence.
- D02: khuyến nghị email identity + explicit organization context; không auto-merge Student giữa tổ chức hoặc tự chọn context đầu tiên.
- D03: khuyến nghị nhóm luyện nhanh có filter thật; curated packs với progress riêng cần phạm vi được duyệt.
- Adaptive/diagnostic trong `quang-learning-quality-adaptive-practice/feedback-resolution.md` là proposal riêng, chưa là điều kiện của đợt hoàn thiện này.
- Report 3 FR-PRACTICE-001..009 và FR-CONTENT-006 là baseline mong muốn, không chứng minh ứng dụng đã chạy đủ.

## Chi phí/phạm vi

Không dùng Gemini để lặp lại đáp án mà evaluator đã biết nếu giải thích chuẩn đủ; personalized explanation theo yêu cầu hoặc policy đã duyệt. Chỉ auto-enqueue khi feature và budget policy cho phép. Repeated GET không tốn provider request. Budget chia sẻ với scoring exam nếu dùng chung Google project. Không dùng quota giả định như quota thực của key.
