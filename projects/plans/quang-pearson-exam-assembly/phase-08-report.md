# Phase 8: Báo cáo nghiệp vụ tổ chức đề thi

Phụ thuộc: Phase 1–7 xong
Đầu ra: `pte-doc/plans/reports/YYMMDD-exam-assembly-time-cefr-report.md` (tiếng Việt). Ảnh và dữ liệu đặt ở `pte-doc/plans/reports/assets/<tên-báo-cáo>/`, liên kết tương đối.
Người đọc: hội đồng chấm đồ án và giảng viên hướng dẫn.

## 1. Yêu cầu chung

- Mọi khẳng định về Pearson có trích nguyên văn và nguồn. Mọi khẳng định về hệ thống trỏ tới file hoặc lớp trong code.
- Tách rõ ba loại nội dung: **Pearson nói gì**, **hệ thống làm gì**, **chỗ nào là suy luận hoặc mô phỏng**.
- Số liệu lấy từ chạy thật (20 đề ở Phase 2 và 5), không lấy số minh họa.
- Có ví dụ tính tay cho một đề cụ thể, theo từng bước, đối chiếu được với biên bản lắp đề.

## 2. Dàn ý

1. **Tóm tắt** (1 trang): bài toán, ba tầng phân chia, kết quả đo.
2. **Căn cứ từ Pearson:** bảng P1–P7 kèm trích dẫn và đường dẫn; giải thích "các đề được cân bằng tổng độ dài" (P3) và "lấy mẫu ngẫu nhiên phân tầng" (P4).
3. **Mô hình nghiệp vụ tổ chức kỳ thi:**
   - các vai trò (admin nền tảng, trung tâm, giám khảo, học viên) và quyền;
   - vòng đời: câu hỏi (soạn → gửi duyệt → duyệt kèm CEFR) → mẫu (DRAFT → ACTIVE) → kỳ thi (tạo → sinh đề → thi → chấm);
   - mẫu chuẩn và mẫu trung tâm; quy tắc nhãn "Chuẩn Pearson" (R1–R5).
4. **Cách tính thời gian:**
   - công thức `d(q)`, `D(t, n)`, thời lượng phần, tổng;
   - bảng hiệu chỉnh stimulus và overhead cho 22 dạng bài;
   - so sánh trước và sau mô hình mới với khung Pearson (bảng ở mục 3.1 của plan);
   - phân biệt thời lượng dự kiến (lập kế hoạch) và đồng hồ thi (`examEndTime`, ngân sách Reading).
5. **Cách phân chia số câu:**
   - bài toán ràng buộc; thuật toán liệt kê, ghép, trọng số và rút theo seed;
   - lý do loại cực trị (P3);
   - ví dụ tính tay; phân phối 20 đề thực tế.
6. **Cách phân chia CEFR:**
   - thang, phạm vi đề chuẩn B1–C2 và căn cứ P5;
   - quy trình gắn CEFR: `cefr_level` là trường của câu, người soạn nhập, có hiệu lực khi Academic Manager duyệt câu và lý do giao cho chuyên môn: quản lý học thuật có thâm niên PTE xác nhận, giống bước người soạn và người duyệt của Pearson;
   - vì sao không dùng Table 4 (phân bố thí sinh) làm tỉ lệ câu hỏi;
   - hạn ngạch theo kỹ năng, làm tròn Hamilton, thứ tự lấy bù;
   - tầng thời lượng thật; ví dụ tính tay; phân bố 20 đề thực tế.
7. **Tái lập và kiểm chứng:** seed, phiên bản thuật toán, biên bản lắp đề, cách hội đồng tự kiểm một đề.
8. **So sánh với Pearson:** bảng giống và khác nhau. Pearson dùng IRT và hàm thông tin mục tiêu; hệ thống dùng CEFR do người gắn và tỉ lệ mục tiêu. Kèm lý do và lộ trình.
9. **Giới hạn và hướng phát triển:** IRT/Rasch, equating, đồng hồ theo phần cho Listening.
10. **Câu hỏi hội đồng có thể đặt và câu trả lời**, mỗi câu trả lời trỏ tới mục và số liệu. Danh sách tối thiểu:
    - Vì sao đề có tổng thời gian này? Có vượt 2h15 không?
    - Hai học viên làm hai đề khác nhau, có công bằng không?
    - Vì sao không làm IRT như Pearson?
    - CEFR do người gắn thì có chủ quan không, kiểm soát thế nào?
    - Trung tâm sửa mẫu tùy ý thì còn gọi là chuẩn PTE được không? (R1–R6, vì sao trọng số tính vào chuẩn còn thứ tự thì không)
    - Ngân hàng thiếu câu thì sao?
    - Làm sao chứng minh đề này sinh ra đúng quy trình?
    - Nếu Pearson đổi cấu trúc đề thì hệ thống xử lý thế nào?
11. **Phụ lục:** bảng 22 dạng bài (số câu, prep, response, stimulus, overhead); dữ liệu 20 đề; danh sách endpoint và migration; nguồn tham khảo.

## 3. Xong khi

- Báo cáo đủ 11 mục, mọi số liệu có nguồn (tài liệu Pearson hoặc lần chạy thật được ghi ngày giờ).
- Người dùng đọc duyệt.
