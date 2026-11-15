# Phase 1: Nhãn 1-based, icon kỹ năng và prop `contentState`

Status: Completed

## Requirements

- Review của `placements` và `selections` hiện nhãn `1.`, `2.`… (ô trống đầu tiên là 1), nhất quán với `blanks` và `order`.
  Key không phải số nguyên giữ nguyên làm nhãn.
- Vòng tiến độ của mỗi nhóm kỹ năng dùng icon của chính kỹ năng đó.
- `HomeView` truyền `contentState` đúng ba giá trị `ready`, `loading`, `error`.

## Design Constraints

- Key trong payload là chỉ số ô trống từ 0 (khớp `{{0}}` trong đề); chỉ đổi cách hiển thị, không đổi dữ liệu lưu.
- Dùng lại `iconForSection`, không thêm bảng icon mới.

## Related files

- `pte-practice/features/practice/review-answer.ts`
- `pte-practice/tests/unit/features/practice/review-answer.test.ts`
- `pte-practice/features/catalog/SkillTaskList.tsx`
- `pte-practice/features/home/HomeView.tsx`

## Steps

1. `review-answer.ts`: nhãn `String(Number(gap) + 1)` khi `gap` là số nguyên không âm, ngược lại giữ `gap`.
2. Sửa test: payload dùng key `"0"`, `"1"` như thật; thêm trường hợp key không phải số.
3. `SkillTaskList`: `<AppIcon name={iconForSection(section.code)} size={16} />` trong `ProgressRing`.
4. `HomeView`: `contentState` theo `catalogStatus`.

## Quality/Testing State

- Test đơn vị cập nhật cho `describeSavedAnswer`; icon và prop kiểm bằng `tsc` và eslint.
