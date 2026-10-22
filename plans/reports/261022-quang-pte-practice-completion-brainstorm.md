# Brainstorm: hoàn thiện PTEPrep Practice và giải thích Gemini theo rubric

Date: 2026-10-22
Owner: Ngô Đăng Quang
Status: Đề xuất cho kế hoạch triển khai; chưa thay đổi ứng dụng.

## Hướng người dùng yêu cầu

Hoàn thiện `pte-practice` sau khi cập nhật Report 3–6. Dùng Gemini API key đã có trong env cho giải thích AI; kết quả cần nhất quán giữa các lần giải thích và phải có rubric. Người dùng giao agent nghiên cứu, đề xuất cách phù hợp; chưa xác nhận các lựa chọn D01–D03 hoặc thang điểm AI.

Diễn giải “đồng bộ”: cùng bản nộp và cùng bộ phiên bản thì các lần đọc trả cùng bản kết quả đã lưu; các câu trả lời khác nhau được đánh giá theo cùng rubric đã duyệt. Không hứa model trả từng chữ giống nhau khi thực sự gọi lại, hoặc một prompt bảo đảm đánh giá đúng.

## Các hướng đã cân nhắc

1. Gọi Gemini mới mỗi lần bấm giải thích: nhanh cho prototype, nhưng phát sinh kết quả khác, trùng chi phí, thiếu lịch sử. Không đề xuất cho luồng chính.
2. Giải thích chuẩn đã duyệt theo câu hỏi: ổn định và dùng khi AI unavailable; không đủ cá nhân hóa cho câu trả lời của Student.
3. Giải thích cá nhân hóa đã lưu theo bản nộp bất biến, pin rubric/prompt/model: đề xuất chính. GET không tạo AI job. Retry giữ danh tính công việc; regeneration là bản mới có lý do và quyền.
4. Kết hợp hướng 2 và 3: đáp án/giải thích chuẩn do học thuật kiểm soát, AI giải thích câu trả lời cụ thể dựa trên dữ liệu đó. Đề xuất áp dụng.
5. Mở chatbot hoặc RAG/vector database: chưa cần cho giải thích từng câu; tăng phạm vi và khó kiểm soát bằng chứng. Để ngoài lần hoàn thiện này.
6. Cho Gemini tự chấm cả điểm khách quan và phát âm từ transcript: không phù hợp. Dùng evaluator cho đáp án khách quan; nhận xét phát âm cần audio assessor được kiểm định.

## Bằng chứng nguồn hiện tại

- `pte-practice/features/practice/renderer-allowlist.ts` và backend `PracticeConstants`: chỉ 9 renderer được phép chạy, chưa đủ toàn bộ task có trong registry.
- `PracticeQuestionService` đang lấy câu APPROVED/current/SHARED từ enum pool PRACTICE, dùng câu đầu tiên; chưa có hai flag độc lập theo report.
- `PracticeSessionItem` pin prompt/options nhưng chưa pin đủ media, rubric và answer-key phục vụ kết quả. Dữ liệu đáp án đúng phải nằm ở phần server riêng.
- `BlankRenderer.tsx` hardcode số blank; mapper làm mất `blankIndex`. Content contract chưa đủ prompt audio/image và stable option IDs.
- `PracticeSessionView.tsx` có lifecycle và idempotency, nhưng màn hoàn tất chưa có review/explanation. `ProgressView.tsx` và `StudyPackView.tsx` chưa hoàn thiện nghiệp vụ.
- Gemini native client đã có JSON schema, timeout và phân loại lỗi. Bean hiện phụ thuộc `azure-gemini`; tách cấu hình practice khỏi exam trước khi tái sử dụng.
- Kiểm tra tên biến/empty status: `pte-api/.env` có `GEMINI_API_KEY` không rỗng. Compose ánh xạ sang `SCORING_AI_GEMINI_API_KEY`. Chưa gọi provider, chưa xác minh key hợp lệ/quota/model thực tế.

## Đề xuất rubric

Academic Staff soạn rubric theo task, câu trả lời mẫu và giải thích chuẩn; Academic Manager duyệt/publish. Rubric chứa mã tiêu chí, mô tả mức đạt, điều kiện áp dụng, bằng chứng cần có, quy tắc bài rỗng/không hợp lệ, version và lịch sử duyệt. Cấu hình trọng số trong Score Template hiện tại chưa thay thế rubric học thuật đầy đủ.

- Khách quan: evaluator quyết định đáp án, credit/penalty và normalization; Gemini chỉ giải thích kết quả đó.
- Writing: nhận xét nội dung, tổ chức, ngữ pháp/từ vựng theo task và rubric; trích bằng chứng từ bài và nguồn. Điểm ước lượng chỉ bật sau kiểm định.
- Speaking: tách nội dung qua transcript và phát âm/độ trôi chảy qua âm thanh; thiếu bằng chứng thì ghi không đánh giá được.
- Personal Introduction: không gán tổng điểm, chỉ coaching nếu được duyệt.

## Rủi ro và quyết định còn mở

D01 catalog Academic/Core, D02 email/membership context, D03 Study-Pack, quyền xử lý Student content feedback, ngôn ngữ mặc định, AI numeric score và hạn mức phải được ghi là đề xuất/chờ xác nhận. Không để plan mới biến đề xuất cũ thành quyết định.

Rubric nhất quán cần bộ bài chuẩn do học thuật đánh giá và kiểm định model/prompt theo phiên bản. JSON hợp schema không đồng nghĩa nhận xét đúng. Hạ temperature không thay thế lưu kết quả; tham số phải theo model thực tế.

## Bước tiếp theo

Lập plan tại `pte-doc/projects/plans/quang-pte-practice-completion/`. Hoàn thiện contract và nội dung nền trước, rồi kết quả khách quan, workflow AI, giao diện và kiểm định. Không triển khai sản phẩm hoặc gọi live Gemini trong lượt lên plan.
