# Phase 2: Đếm từ theo khoảng trắng như backend

Status: Completed

## Requirements

- `well-known`, `decision-making`, `twenty-five` được tính là 1 từ trên màn hình, giống `FormCheck.countWords` ở backend.
- Văn bản rỗng hoặc chỉ khoảng trắng là 0 từ.

## Design Constraints

- Dùng `split(/\s+/u)` sau `trim()`, không dùng `Intl.Segmenter`, để số hiển thị và số chấm luôn bằng nhau.
- Giữ nguyên chữ ký `countPracticeWords(value: string): number`.

## Related files

- `pte-practice/features/practice/media/text-utils.ts`
- `pte-practice/tests/unit/features/practice/media/text-utils.test.ts`

## Steps

1. Thay thân hàm.
2. Test: từ có gạch nối, nhiều khoảng trắng và xuống dòng, chuỗi rỗng.

## Quality/Testing State

- Test đơn vị; chạy lại toàn bộ test `pte-practice`.
