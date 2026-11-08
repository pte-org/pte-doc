# Phân biệt mức CEFR cho AI sinh đề: tài liệu và hướng làm

Ngày: 2026-11-07. Phạm vi: `pte-api` module itembank, `internal/generation` (prompt generator và reviewer).

## Hiện trạng (đã đọc mã)

- Prompt generator chỉ có một dòng `CEFR Level: {cefr}` (`_common-generator.md`). Không có mô tả mức nào.
- Reviewer (`ReviewPromptBuilder`) hỏi "độ khó có phù hợp CEFR mục tiêu không" và để model tự ước lượng `estimated`.
  Comment trong mã nói có "CEFR descriptions" nhưng prompt thực tế chưa đưa mô tả nào vào.
- Cả hai dùng cùng model Capstone, nên không có thang đo độc lập.

## Tài liệu có thể dùng

| Nguồn | Dùng để làm gì | Lưu ý |
|---|---|---|
| [CEFR Companion Volume 2020](https://www.coe.int/en/web/common-european-framework-reference-languages/cefr-descriptors-search) (Council of Europe) | Can-do descriptors cho đọc, nghe, nói theo từng bậc | Công khai, mô tả định tính |
| [CEFR Table 3 – qualitative aspects of spoken language](https://www.coe.int/en/web/common-european-framework-reference-languages/table-3-cefr-3.3-common-reference-levels-qualitative-aspects-of-spoken-language-use) | Range, accuracy, fluency, coherence theo bậc | Dùng cho dạng bài nói |
| [Pearson GSE Teacher Toolkit](https://www.pearson.com/content/dam/one-dot-com/one-dot-com/pearson-languages/en-gb/pdfs/gse/gse-resources/introduction-to-the-global-scale-of-english-teacher-toolkit-new.pdf) | Mục tiêu học, ngữ pháp, từ vựng gán GSE và CEFR; có công cụ phân tích mức văn bản | Cùng hệ với PTE (điểm PTE đặt trên GSE), nên khớp nhất. Điều khoản dùng lại nội dung chưa kiểm tra |
| [Oxford 3000/5000 theo CEFR](https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000) | Danh sách từ theo bậc A1–C1 để đo tỷ lệ từ khó | Bản quyền OUP; bản CSV trên GitHub không rõ giấy phép. Cần xác nhận trước khi đưa vào repo |
| [CEFR-SP](https://aclanthology.org/2022.emnlp-main.416.pdf) (EMNLP 2022, 17k câu gán CEFR) | Dữ liệu đối chiếu và hiệu chỉnh ngưỡng đo | Giấy phép dữ liệu chưa kiểm tra |
| English Vocabulary Profile, CEFR-J wordlist | Từ vựng theo bậc | Chưa kiểm tra điều khoản tải và dùng lại |

Kết luận: có tài liệu chính thống để mô tả từng bậc (CEFR, GSE). Với kiểm tra bằng số thì chưa có bộ ngưỡng
công khai dùng ngay cho từng dạng bài, nên phải tự hiệu chỉnh trên câu hỏi mẫu do giáo viên duyệt.

## Hướng làm

1. Đưa bảng mô tả B1/B2/C1/C2 (độ dài câu, từ vựng, cấu trúc, mức trừu tượng) vào prompt của cả generator và reviewer,
   viết từ CEFR và GSE bằng lời của dự án (không chép nguyên văn tài liệu có bản quyền).
2. Thêm kiểm tra bằng số, không dùng LLM: độ dài câu trung bình, tỷ lệ từ ngoài danh sách tần suất, chỉ số dễ đọc.
   Khoảng chấp nhận theo bậc do giáo viên duyệt, hiệu chỉnh trên câu hỏi mẫu đã có.
3. Tùy chọn: reviewer dùng model khác.

Chưa làm gì trong mã. Chưa kiểm tra giấy phép từng nguồn ở trên.
