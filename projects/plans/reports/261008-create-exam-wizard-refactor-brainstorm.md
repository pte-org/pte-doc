# Brainstorm: Create Exam Wizard refactor

**Date:** 2026-10-08

## Ideas Explored

1. **Tách theo bốn phase UI** — mỗi phase sở hữu phần JSX tương ứng: thông tin kỳ
   thi, lịch thi/chính sách, đối tượng dự thi, và review. Cách này làm luồng đọc
   giống với trải nghiệm người dùng.
2. **Tách theo trách nhiệm kỹ thuật** — đưa state, validation, audience queries,
   policy mapping và submit workflow ra hooks/utils riêng. Cách này giảm logic
   trong component nhưng nếu làm đơn độc sẽ khiến việc tìm code theo phase khó hơn.
3. **Hybrid theo phase + trách nhiệm** — giữ một wizard shell mỏng để điều phối,
   tách bốn step component cho UI và tách các nhóm logic dùng chung thành hooks/
   utils. Đây là phương án cân bằng khả năng đọc và khả năng test.
4. **Tách từng input thành component nhỏ** — loại bỏ khỏi phạm vi vì tạo quá nhiều
   abstraction, làm form khó theo dõi và không giải quyết đúng điểm nghẽn hiện tại.

## User's Direction

Người dùng đồng ý với phương án hybrid: `CreateExamWizard.tsx` chỉ điều phối,
trong khi bốn phase UI và các nhóm logic state/validation/audience/policy được
tách thành các file có ownership rõ ràng.

Một agent khác đang làm song song các chức năng FE khác. Refactor này phải chỉ
đụng tới phạm vi Create Exam và không ghi đè, merge ngầm, hay chỉnh sửa các file
không thuộc ownership của task này.

## Open Questions

- Cần xác nhận bằng diff cuối rằng payload, API hooks, validation rule và mutation
  flow không thay đổi.
- Nếu agent song song bắt đầu sửa cùng file trong phạm vi Create Exam, phải dừng
  trước khi ghi đè và báo người dùng.

## Risks

- Tách component có thể vô tình thay đổi thứ tự render, form submit mặc định hoặc
  reset state khi đóng/mở wizard.
- Locale/theme hiện chạy qua component boundary; truyền text hoặc hook sai tầng
  có thể làm VI mặc định hoặc dark mode lệch.
- Các query audience có nhiều trạng thái loading/empty; di chuyển chúng sai
  ownership có thể làm mất search/filter hoặc tạo request thừa.
