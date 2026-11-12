# Brainstorm: minh bạch và cấu hình cơ chế chấm điểm PTE trên giao diện

**Date:** 2026-11-04
**Đầu vào:** [261104-pte-scoring-pearson-alignment-review.md](261104-pte-scoring-pearson-alignment-review.md) (các điểm lệch L1–L9)
**Spec:** [`pte-doc/projects/plans/quang-scoring-rubric-transparency/spec.md`](../../projects/plans/quang-scoring-rubric-transparency/spec.md)

## Mục tiêu người dùng nêu

Hội đồng phải hiểu được hệ thống chấm như thế nào: từng task type tính điểm ra sao, từ điểm câu đến điểm 10–90.
Mục tiêu chính là **minh bạch**, việc cho chỉnh cấu hình là thứ yếu.

## Hiện trạng đã kiểm tra

- Điểm AI chạy theo một trong ba provider, chọn bằng `SCORING_AI_PROVIDER`:
  - `stub`: mặc định ở local;
  - `openai-compatible`: chỉ có 2 prompt chung cho mọi dạng viết và mọi dạng nói, LLM tự trả `rawScore`;
  - `azure-gemini`: mỗi task type một class.
- Với `azure-gemini`, luật chấm nằm rải ở 4 chỗ:
  - hằng chuỗi prompt `EXAMINER` trong từng scorer;
  - danh sách tiêu chí trong constructor;
  - các hằng số trong `FormCheck`;
  - công thức gộp trong `GeminiSpeakingScorer`, `GeminiWritingScorer`, `PronunciationFormula`.
- Chỉ trọng số kỹ năng (`exam_definition_items`) là sửa được trên giao diện, qua màn Score Template.
- **Điểm lệch mới, L10:** prompt không đưa cho LLM thang mô tả từng mức của Pearson (ví dụ Content 0–6). LLM tự chọn
  thang 0–100 cho mỗi tiêu chí, nên điểm khó lặp lại giữa các lần chấm và khó giải thích.

## Các hướng đã xem xét

| Hướng | Nội dung | Kết luận |
|---|---|---|
| A. Trang luật chấm | Chỉ xem: tiêu chí, thang điểm, mô tả mức, điều kiện chặn, các mức Form và trọng số kỹ năng của từng task type | Chọn |
| B. Giải thích một bài | Đi từ điểm tiêu chí → điểm câu → trung bình task type → 10–90, dùng số thật | Chọn |
| C. Bộ mô phỏng | Nhập điểm tiêu chí giả định rồi xem điểm câu | Chọn |
| D1. Chỉnh các con số | Thang và tỉ trọng tiêu chí, các mức Form, bật/tắt điều kiện chặn; có phiên bản | Chọn |
| D2. Chỉnh mô tả mức và prompt | Sửa câu chữ LLM nhận được | Loại: rủi ro prompt injection, chất lượng chấm tụt mà không ai thấy, phải chấm lại bằng AI |
| D3. Tự ghép công thức hoặc thêm tiêu chí | Công thức kéo thả | Loại: AI không chấm được tiêu chí mới nếu không sửa code; trái nguyên tắc của `ScoringProfileRegistry` |
| E. Chỉ làm tài liệu hoặc sơ đồ tĩnh | Không làm giao diện | Loại: chắc chắn sẽ lệch khỏi code, báo cáo đối chiếu đã cho thấy điều này |
| Giao diện tự mô tả luật bằng chữ | Frontend viết lại luật chấm | Loại: hai nguồn sự thật sẽ trôi khỏi nhau |

## Hướng người dùng chọn

- Làm cả **A, B, C, D1** trên **vendor-web**.
- **Sửa các điểm lệch so với Pearson cùng đợt.** Giao diện phải hiển thị đúng cách hệ thống chấm thật.
- **Reset DB demo.** `subScores` cũ ở thang 0–100 nên không chuyển đổi.

Kiến trúc thống nhất: **một bản khai báo luật chấm (rubric) có phiên bản là nguồn sự thật duy nhất.**

- AI chỉ trả điểm từng tiêu chí theo thang Pearson.
- Backend tính điểm câu từ rubric, gồm điều kiện chặn, các mức Form và phép gộp `tổng điểm đạt / tổng điểm tối đa`.
- Prompt được dựng từ mô tả các mức trong rubric.
- A, B, C đọc và gọi đúng mã đó.
- D1 chỉ sửa tham số số học và tạo phiên bản mới, gắn vào mẫu đề.

Đánh giá khả thi: **làm được**, khoảng 8–10 phase.
- Backend: model rubric, migration V2, refactor khoảng 10 scorer AI, API giải thích điểm, API mô phỏng.
- Frontend: 3–4 màn hình.

Hướng này khả thi vì công thức vẫn nằm trong code, chỉ tham số nằm trong DB. Thêm nữa, có thể tính lại điểm từ điểm tiêu chí
đã lưu mà không phải gọi AI lại.

## Câu hỏi mở cho /ck:plan

1. Quy trình duyệt khi sửa rubric (D1): sửa xong áp dụng ngay, hay Staff đề xuất rồi Academic Manager duyệt như mẫu đề?
   `ExamDefinitionController` hiện cho `PLATFORM_ADMIN`, `ACADEMIC_MANAGER`, `ACADEMIC_STAFF`, `PLATFORM_AUTHOR` thao tác.
2. Phạm vi rubric: một bộ rubric chung cho nền tảng gắn theo phiên bản vào mẫu đề, hay mẫu đề của trung tâm được tự chọn
   hoặc sửa rubric?
3. Hạn bảo vệ, để xếp thứ tự ưu tiên giữa các phase.
4. Provider `openai-compatible` không có rubric theo task type: dựng prompt từ rubric giống `azure-gemini`, hay ngừng hỗ trợ?
5. Giám khảo (L8): vẫn nhập một điểm tổng 0–100, hay chấm theo từng tiêu chí của rubric (ví dụ chỉ chấm lại Content)?
   Spec đang để ở mức P2.
6. L9 (gộp điểm giữa các câu theo điểm hay theo phần trăm): tài liệu Pearson không quy định; spec giữ cách hiện tại.

## Rủi ro

1. **Phạm vi lớn.** Gộp cả sửa luật chấm (L1–L10) lẫn 4 phần giao diện vào một đợt. Nếu hạn bảo vệ gần, nên làm trước
   rubric, sửa luật chấm và trang A; B, C, D1 làm sau.
2. **LLM trả điểm ngoài thang hoặc không ổn định.** Thang nhỏ (0–6) với mô tả rõ thường ổn định hơn 0–100, nhưng cần chặn
   giá trị ngoài thang và đo độ lặp lại trên một bộ bài mẫu.
3. **Ghim phiên bản.** Nếu rubric không gắn phiên bản vào mẫu đề và snapshot báo cáo, sửa rubric sẽ làm đổi điểm đã công bố,
   đúng loại lỗi mà Score Template đã tránh được.
