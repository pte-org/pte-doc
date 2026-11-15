# Phase 1: Ô transcript nhiều dòng

Status: Completed

## Requirements

- Khi task type cần audio prompt hoặc cần reference answer, ô `referenceAnswerText` là `<textarea>` nhiều dòng, cao tối thiểu như ô prompt.
- Các dạng khác giữ ô một dòng.
- Nhãn, giá trị, dấu "agent đang điền" (`AgentMark`) không đổi.

## Design Constraints

- Dùng lại `fieldClass` và cùng kiểu `<label>` + `<textarea>` của ô `promptText`, không tạo component mới.

## Related files

- `pte-web/apps/vendor-web/features/questionbank/components/QuestionEditorForm.tsx`

## Steps

1. Tính `multilineReference = questionType?.requiresAudioPrompt || questionType?.requiresReferenceAnswer`.
2. Render `<textarea>` hoặc `<Input>` theo biến đó.

## Quality/Testing State

- Không có test giao diện cho form này; kiểm tra bằng `tsc` và eslint.
