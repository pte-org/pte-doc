# Phase 1: Ngày thi trong khoảng hợp lệ

Status: Completed

## Requirements

- Nút Lưu bị tắt khi ngày đã chọn nằm ngoài `[bounds.min, bounds.max]`.
- Ngày gõ tay hợp lệ về định dạng nhưng ngoài khoảng: không được nhận làm ngày đã chọn, hiện thông báo rõ ràng (EN và VI).
- Danh sách năm chỉ gồm các năm trong khoảng; chọn năm không làm `selectedDate` rơi ra ngoài khoảng.

## Design Constraints

- Quy tắc nằm trong hàm thuần ở `exam-date.ts`, cùng nguồn `examDateBounds()` với lưới ngày, để hai nơi không lệch nhau.
- Khi gõ tay ngoài khoảng, xóa `selectedDate` thay vì giữ ngày cũ, để Lưu không lưu nhầm ngày không còn hiển thị trong ô.
- Chuỗi hiển thị nằm trong `common/i18n` (types, en, vi).

## Related files

- `pte-practice/features/home/exam-date.ts`
- `pte-practice/features/home/ExamDateLine.tsx`
- `pte-practice/common/i18n/{types,en,vi}.ts`
- `pte-practice/tests/unit/features/home/exam-date.test.ts`

## Steps

1. `isExamDateInBounds(iso, bounds)` và `examDateYears(bounds)`.
2. `ExamDateLine`: dùng chúng cho danh sách năm, `handleManualDateChange`, `handleSelectYear` và điều kiện `disabled` của nút Lưu.
3. Thêm khóa `examDate.outOfRange` và hiển thị dưới ô gõ tay.
4. Test hai hàm thuần.

## Quality/Testing State

- Test đơn vị mới; chạy `tsc`, eslint và toàn bộ test `pte-practice`.
