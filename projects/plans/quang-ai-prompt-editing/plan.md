# Plan: Chỉnh sửa prompt AI có duyệt (JSON trong DB, không khóa)

Ngày: 2026-11-08. Tác giả: quang. Trạng thái: **phase 1 xong; phase 3 và 4 xong cho prompt sinh đề + khối chung (API, cổng test, duyệt, giao diện soạn); reviewer và scoring chưa chuyển vào DB**.

## Yêu cầu (giáo viên hướng dẫn + xác nhận của người dùng)

1. Người có thẩm quyền sửa được prompt trên giao diện: mọi vai trò academic (`ACADEMIC_STAFF`, `PLATFORM_AUTHOR`,
   `ACADEMIC_MANAGER`, `PLATFORM_ADMIN`).
2. Backend lưu prompt dạng **JSON** (cột JSONB trong DB), không còn file `.md`.
3. **Không có mục bị khóa** (hiện `PromptMarkdownParser` khóa các mục reply format).
4. Sửa xong **cần người thứ hai duyệt** mới có hiệu lực (người duyệt không phải tác giả, trừ `PLATFORM_ADMIN`).
5. Phạm vi: prompt sinh đề (22 dạng bài + khối chung), reviewer **và prompt chấm điểm** (scoring).
6. Nội dung hiện có (file `.md`, hằng số trong code) nạp vào DB lần đầu; sau đó DB là nguồn duy nhất.

## Hiện trạng đã đọc

- `PromptDocumentService`: chỉ trình bày chỉ đọc (`GET /ai-admin/prompts`, `/prompts/{category}/{key}`); model thực sự nhận gì thì do
  `LlmItemGenerator`, `ReviewPromptBuilder`, scoring tự dựng.
- Generator: 23 file `.md` trong `resources/question-generation/prompts/`, thay biến `{cefr} {topicHint} {avoidTopics} {lengthRules}`.
- Reviewer: văn bản nằm trong code (`ReviewPromptBuilder`, `ReviewPromptContent`).
- Scoring: `ScoringPromptSource` (SPI) do `ScoringPromptCatalogService` hiện thực.
- Mẫu quy trình duyệt đã có: rubric phase 9 (`quang-scoring-rubric-transparency/phase-09-rubric-editing-workflow.md`):
  DRAFT -> PENDING -> ACTIVE|REJECTED, diff trước khi kích hoạt, bảng audit, chặn tự duyệt.

## Rủi ro chính (vì bỏ khóa)

- Sửa nhầm reply format làm bộ parse không đọc được -> job sinh đề/chấm điểm hỏng hàng loạt. Giảm bằng: kiểm tra khi lưu/gửi duyệt
  (đủ biến bắt buộc, ví dụ trả lời parse được bằng đúng parser), phiên bản bất biến, quay lại bản trước.
- Prompt chấm điểm ảnh hưởng điểm thật của thí sinh: duyệt bắt buộc, audit, và chỉ áp dụng cho lượt chấm sau khi kích hoạt
  (ghi phiên bản prompt vào kết quả chấm để truy vết).
- Cùng model viết và review: sửa prompt reviewer có thể làm lỏng kiểm tra; cần diff rõ khi duyệt.

## Quyết định bổ sung (2026-11-08)

- Prompt chấm điểm **được sửa**; người sửa là người có chuyên môn và chịu trách nhiệm. Phần tham số số học của rubric vẫn đi theo quy trình
  phiên bản rubric đã có (phase 9 của kế hoạch rubric), không đưa vào bảng prompt.
- **Một bảng chung `ai_prompt_versions`**, phân biệt bằng cột `kind` (enum: `GENERATOR`, `REVIEWER`, `SCORER`, `SHARED`) cộng khóa `prompt_key`
  (dạng bài hoặc tên khối chung). Không gộp vật lý với `scoring_rubric_versions`: bảng đó được đề thi ghim
  (`exam_definitions.rubric_version_public_id`), có trigger bất biến V32 và tham số số học có kiểu riêng; gộp buộc viết lại phần chấm điểm
  mà không được lợi gì. Dùng chung **quy trình** (cùng máy trạng thái và dạng audit), không dùng chung bảng.
- **Cổng test prompt**: sửa xong phải chạy "test prompt" và qua mới được gửi duyệt (`PLATFORM_ADMIN` được bỏ qua cổng này).
  Test gắn với băm nội dung của đúng phiên bản; sửa lại nội dung thì kết quả test cũ mất hiệu lực. Test thế nào theo kind:
  generator = sinh thử 1 câu và qua parser + validator; reviewer = chấm thử một bản nháp mẫu và parse được verdict;
  scorer = chấm thử một bài mẫu và parse được điểm trait. Kết quả test lưu kèm phiên bản (ai chạy, khi nào, đạt hay không, lý do).

## Câu hỏi còn mở (cần chốt trước khi làm)

- Prompt chấm điểm hiện được dựng từ catalog rubric trong code (`ScoringPromptCatalogService`). Cần xem phần văn bản nào tách được thành
  block sửa được mà không nhân đôi nguồn sự thật với tham số rubric.
- Test prompt gọi LLM thật nên tốn token và cần khóa API; cần quy định giới hạn tần suất và nơi lưu kết quả.
- Mô tả CEFR từng mức: nội dung do tài liệu nguồn quyết định (xem báo cáo 261107-cefr-level-differentiation-research.md); chưa có
  nguồn đọc/nghe, nên chưa viết vào prompt.

## Phases

1. **(XONG cho generator + shared) Mô hình JSON + lưu trữ**: schema JSON một prompt (id, nhóm, dạng bài, các section, block TEXT/LIST/CODE/LEVELS, biến cho phép);
   bảng `ai_prompt_versions` (JSONB, trạng thái, tác giả, người duyệt, lock_version, bất biến khi ACTIVE/RETIRED) và
   `ai_prompt_activation_audits`; migration `V36` (V35 đã dùng cho lý do kích hoạt rubric); seed từ `.md` + hằng số; test seed khớp nội dung cũ từng byte.
2. **Dùng prompt từ DB**: `PromptRegistry`/`ReviewPromptBuilder`/scoring đọc bản ACTIVE (cache có vô hiệu hóa khi kích hoạt);
   xóa file `.md` và hằng số sau khi test tương đương xanh; ghi phiên bản prompt vào job/kết quả chấm.
3. **API ghi + quy trình duyệt**: tạo/sửa nháp, gửi duyệt, duyệt = kích hoạt, từ chối có lý do, diff, chặn tự duyệt,
   kiểm tra hợp lệ khi lưu; quyền theo vai trò academic; mã lỗi vào `*Constants.java`.
4. **Giao diện chỉnh sửa**: biến trang chỉ đọc thành trình soạn từng section/block, hiển thị biến, diff khi duyệt, lịch sử và khôi phục;
   không còn biểu tượng khóa.
5. **Kiểm thử + tài liệu**: suite backend, vitest, báo cáo xác minh trong `pte-doc/plans/reports/`, cập nhật `AGENTS.md`.

## Ghi chú thực hiện

- Đọc bắt buộc trước khi code: `docs/CODING_STANDARDS_API.md`, `CODING_STANDARDS_WEB.md`, `API_RESPONSE_SETUP.md`,
  `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md` (vì có phân quyền).
- Chạy migration: V35 là bản mới nhất; prompt dùng V36.
- Tách khỏi việc A1/A2 và khối mô tả CEFR: hai việc đó nên làm **sau** khi prompt đã sửa được trong DB, để nội dung CEFR vào bằng
  chính quy trình duyệt này thay vì sửa file.

## Tiến độ 2026-11-08 (API + giao diện cho generator và shared)

- Migration `V37`: cột kết quả test (`test_passed`, `tested_content_hash`, `test_note`, `tested_by_user_public_id`, `tested_at`) và chỉ mục
  chỉ cho một bản DRAFT/PENDING mỗi prompt.
- API (`/api/v1/ai`): lịch sử `GET/POST /prompts/{category}/{key}/versions`, `GET/PUT /prompt-versions/{id}`, `POST .../test`,
  `PATCH .../status {SUBMIT|APPROVE|REJECT|DISCARD}`. Quyền: staff/author soạn, test, gửi; manager/admin duyệt hoặc từ chối;
  người soạn không tự duyệt (trừ admin); admin được bỏ qua cổng test và kích hoạt thẳng bản nháp.
- Không làm bảng audit kích hoạt riêng: dòng phiên bản đã giữ người soạn, người duyệt, thời điểm kích hoạt và thay thế.
- Test prompt gọi LLM thật: sinh thử một câu (CEFR B2) bằng prompt đang sửa rồi cho qua parser và validator như câu hỏi sinh ra.
  Khối chung được thử trên dạng bài MC_READING_SINGLE.
- Giao diện: trang prompt có nút sửa và lịch sử; trang phiên bản `/admin/ai/prompts/{category}/{key}/versions/{id}`.
  Các trang prompt mở cho vai trò academic (trước đây chỉ PLATFORM_ADMIN).
- Còn lại: chuyển reviewer và scoring vào cùng bảng, ghi phiên bản prompt vào job/kết quả chấm, diff khi duyệt.

## Đổi mô hình sang "đề xuất thay đổi" (2026-11-08)

- Người dùng không còn thấy "bản nháp" hay "phiên bản": trang prompt là một form, sửa và lưu sẽ tạo hoặc cập nhật **đề xuất thay đổi** của prompt đó.
  Mỗi prompt có tối đa một đề xuất mở. Đề xuất được chấp nhận thì ghi đè bản đang dùng (bản cũ vào lịch sử).
- API: `GET /prompts/{category}/{key}/workspace` (bản đang dùng, đề xuất, lịch sử), `PUT .../proposal`, `GET /prompt-versions/{id}`,
  `POST .../test`, `PATCH .../status` (SUBMIT = gửi duyệt, APPROVE = chấp nhận hoặc áp dụng ngay với admin, REJECT = trả lại, DISCARD = bỏ đề xuất).
- Giao diện: một trang với ba tab Prompt, Thay đổi (diff kiểu git với bản đang dùng), Lịch sử (từng thay đổi đã chấp nhận, mở ra xem diff).
- Chưa làm: nhiều đề xuất song song (gộp theo từng phần, báo xung đột).
