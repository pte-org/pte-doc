# Phase 4: CEFR trên câu hỏi

Phụ thuộc: không (song song với Phase 1)
Repo: `pte-api` (itembank), `pte-web` (vendor-web questionbank, api-client)
Migration: `V27__question_cefr.sql`
Căn cứ: P5 (người soạn ghi mức CEFR mục tiêu; người duyệt đánh giá lại; cả hai lưu cùng câu), P6 (lộ trình sang độ khó hiệu chuẩn)

## 1. Thang và phạm vi

- Lưu đủ thang CEFR: `A1, A2, B1, B2, C1, C2`. Trung tâm dạy học viên trình độ thấp có thể cần câu A1–A2 cho đề luyện tập.
- Đề **Chuẩn Pearson** chỉ dùng B1–C2, gần với "upper B1 to lower C2" của P5. Ràng buộc này nằm ở Phase 5 và R5 của Phase 3, không nằm ở câu hỏi.
- Không chia nhỏ B1+/B1−. Thang càng mịn thì ngân hàng càng dễ thiếu câu ở mỗi tầng.

## 2. Dữ liệu (`V27`)

Bảng `questions` thêm **một cột**:

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `cefr_level` | `varchar(2)` nullable, CHECK thuộc `A1, A2, B1, B2, C1, C2` | Mức CEFR của câu |

`cefr_level` là một trường bình thường của câu hỏi, giống `taskTypeKey` hay nội dung: người soạn nhập, người duyệt xem và sửa nếu cần, câu được duyệt thì mức đó có hiệu lực luôn. Không có mức "đề xuất", không có bước xác nhận riêng.

**Vì sao đơn giản như vậy (quyết định 2026-11-03):** hệ thống tin vào người có vai trò chuyên môn. Academic Manager là người có thâm niên giảng dạy và tổ chức thi PTE; khi họ duyệt câu thì toàn bộ câu, kể cả CEFR, được coi là đã kiểm. Pearson cũng giao việc gắn CEFR cho người soạn và người duyệt đã được huấn luyện (P5).

Câu đã có trước migration: `cefr_level = null`, được coi là **"chưa phân loại"**, không mặc định B2 (mặc định sẽ làm sai lệch phân bố mà người dùng không biết). Phase 5 xử lý "chưa phân loại" như một tầng riêng.

Revision mới của câu chép `cefr_level` như mọi trường khác.

## 3. Nghiệp vụ và phân quyền

Không thêm quy tắc phân quyền mới. CEFR đi theo luồng câu hỏi sẵn có (`QuestionController`, `ItembankAccessPolicy`):

| Bước | Ai | CEFR |
|---|---|---|
| Tạo câu | Academic Staff, Academic Manager, Platform Admin | Nhập `cefr_level` |
| Sửa câu nháp | Tác giả (Staff hoặc Manager), hoặc Platform Admin | Sửa `cefr_level` như các trường khác |
| Gửi duyệt | Người soạn | Câu pool EXAM **bắt buộc** có `cefr_level`; lỗi `QUESTION_CEFR_REQUIRED` |
| Duyệt / từ chối | Academic Manager, Platform Admin (không tự duyệt câu mình) | Duyệt là chấp nhận cả `cefr_level`. Muốn đổi mức thì sửa câu hoặc từ chối kèm lý do, như với mọi trường khác |
| Sửa câu đã duyệt | Theo quy tắc revision hiện có | Không có đường riêng cho CEFR |

Câu pool PRACTICE: CEFR không bắt buộc.

## 4. Thay đổi code

**Backend**

- `Question.cefrLevel` (enum `CefrLevel` trong `itembank/domain/enums`, package có `@NamedInterface`, assessment dùng được).
- `QuestionResponse.cefrLevel`; `CreateQuestionRequest` và `UpdateQuestionRequest` nhận `cefrLevel`.
- `submitApproval` kiểm tra bắt buộc với câu EXAM.
- Bộ lọc danh sách câu hỏi nhận `cefr` (cho phép `UNCLASSIFIED`).
- `ItembankService` (API công khai cho assessment):
  - `countPublishedByTaskTypeAndCefr(...)` cho readiness;
  - `publishedIdsByTaskTypeAndCefr(...)` cho Phase 5.
- Hằng số và thông báo trong `ItembankConstants`.

**Web (vendor-web)**

- Form soạn và sửa câu: Select CEFR (component chung, 6 mức).
- Chi tiết câu, danh sách câu hỏi và thẻ Kanban: chip CEFR (`Chip`, tone theo mức).
- Bộ lọc CEFR ở danh sách câu hỏi.
- Chuỗi trong constants, bản dịch Việt trong `adminCopy.ts`.

## 5. Kiểm thử

- Migration: câu cũ null; CHECK chặn giá trị ngoài 6 mức.
- Tạo và sửa câu lưu đúng `cefrLevel`.
- Gửi duyệt câu EXAM không có CEFR thì lỗi `QUESTION_CEFR_REQUIRED`; câu PRACTICE thì không.
- Revision mới chép `cefr_level`.
- Bộ lọc `cefr`, kể cả `UNCLASSIFIED`.
- Web: Select trong form, chip, bộ lọc (unit test).

## 6. Xong khi

- Test backend và web xanh, container healthy.
- Seed local (`seed-local-doc-question-bank.mjs` hoặc SQL) gắn CEFR cho câu mẫu để Phase 5 có dữ liệu thử.
