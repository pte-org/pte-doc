# Phase 7: tenant-web — Tạo kỳ thi theo skill + assign Class, bỏ luồng cũ

Covers FR-08 (UI chọn skill), FR-15 (bỏ modal chọn blueprint + bỏ hẳn luồng batch-theo-Program), FR-16/FR-17 (UI assign/unassign Class) phía `tenant-web`. Sửa path stale của `requests/scheduling/sessions.ts` vì API tạo-kỳ-thi-theo-skill mới bắt buộc phải gọi đúng path mới chạy được (cùng lý do như Phase 6 với `question`). **Xác nhận (2026-09-17, quyết định "chỉ platform thao tác question bank"):** `tenant-web` chưa từng có màn hình question bank nào — đã grep xác nhận trước khi viết plan này — nên phase này không cần xóa gì thêm cho riêng phần đó, chỉ cần grep lại một lần nữa sau khi migrate xong để chắc chắn không có màn nào mới lỡ gọi `/questions`/blueprint/snapshot (host chỉ còn đúng 1 hành động liên quan question bank: bấm "Tạo kỳ thi").

## Requirements

Host tạo kỳ thi bằng cách chọn 1–4 skill (không còn chọn blueprint, không xem/sửa được câu hỏi nào), thấy lỗi thiếu bank rõ ràng theo từng dạng nếu có; trong màn chi tiết kỳ thi, host assign/unassign được Class (chỉ khi SCHEDULED) thay vì chỉ thêm học sinh thủ công/import roster; luồng "Create Exam for Program" (batch theo Program) bị gỡ hoàn toàn.

## Files

**Sửa**
- `pte-web/packages/api-client/src/requests/scheduling/sessions.ts` — bỏ tiền tố `/api/scheduling` khỏi `SESSION_ENDPOINTS`; đổi `createSession()` nhận body `{name, skills, opensAt, closesAt, examMode, lockdownMode, capacity}` thay vì `snapshotPublicId`.
- `pte-web/apps/tenant-web/features/exams/types/index.ts` — `CreateSessionInput` đổi `blueprintPublicId` → `skills: string[]`; xóa `Blueprint`, `BulkCreateSessionsForProgramInput`, `SessionBatchState`, `SessionBatchStatus`.
- `pte-web/apps/tenant-web/features/exams/api/index.ts` — `useCreateSession()` gọi thẳng `createSession()` mới (bỏ bước `publishBlueprint()`); xóa `useBlueprints()`, `useBulkCreateSessionForProgram()`, `splitIntoBatches()`, `batchSessionName()`; thêm `useAssignedClasses(sessionPublicId)`, `useAssignClass(sessionPublicId)`, `useUnassignClass(sessionPublicId)`.
- `pte-web/apps/tenant-web/features/exams/components/CreateSessionModal.tsx` — thay `Select` chọn blueprint bằng 4 checkbox SPEAKING/WRITING/READING/LISTENING (`skills`); giữ nguyên name/opensAt/closesAt/thêm optional examMode/lockdownMode/capacity nếu form hiện có chỗ cho chúng. Đây là **duy nhất** điểm chạm của host vào question bank kể từ phase này — chọn skill, không chọn câu hỏi.
- `pte-web/apps/tenant-web/features/exams/utils/validateCreateSession.ts` — validate `skills` (1–4 phần tử) thay vì `blueprintPublicId`.
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx` — thêm section "Assigned Classes" (list + assign/unassign) cạnh section "Students" hiện có (giữ nguyên `AddStudentForm`/`RosterImport`/`StudentRosterTable` — đó là luồng thêm-tay-từng-học-sinh, không thuộc phạm vi Plan B).
- `pte-web/apps/tenant-web/features/exams/constants/index.ts` — bỏ `CREATE_SESSION_FOR_PROGRAM_TEXT`/`CREATE_SESSION_FOR_PROGRAM_ERRORS`/`BLUEPRINTS_QUERY_KEY`; sửa `CREATE_SESSION_TEXT`/`EMPTY_CREATE_SESSION`/`CREATE_SESSION_ERRORS` cho `skills`; thêm text cho assign-Class section.
- `pte-web/apps/tenant-web/features/exams/components/index.ts` — bỏ export `CreateSessionForProgramModal`.
- `pte-web/apps/tenant-web/features/programs/components/ProgramDetailView.tsx` — gỡ nút/luồng "Create Exam for Program" (điểm gọi `CreateSessionForProgramModal`/`useBulkCreateSessionForProgram` duy nhất).

**Thêm**
- `pte-web/packages/api-client/src/requests/scheduling/classAssignments.ts` — `listAssignedClasses`, `assignClass`, `unassignClass` gọi `/sessions/{id}/classes` (Phase 4).
- `pte-web/packages/api-client/src/types/scheduling/classAssignment.ts` (hoặc file types tương đương đã có sẵn cho `scheduling`) — `SessionClassAssignmentResponse`.
- `pte-web/apps/tenant-web/features/exams/components/ClassAssignmentSection.tsx` — danh sách Class đã assign + form chọn Class để assign (dùng lại `listClasses` từ `requests/admin/classes` để lấy danh sách Class của tenant).

**Xóa**
- `pte-web/apps/tenant-web/features/exams/components/CreateSessionForProgramModal.tsx`
- `pte-web/packages/api-client/src/requests/authoring/blueprints.ts` (không còn nơi nào trong tenant-web gọi `listBlueprints`/`publishBlueprint` sau phase này — xác nhận bằng grep trước khi xóa; nếu vendor-web `/admin/exams` cũng import cùng file này thì **giữ lại file**, chỉ bỏ import phía tenant-web).

## Steps

1. Sửa `SESSION_ENDPOINTS` bỏ tiền tố `/api/scheduling`; đổi `createSession()` sang body mới theo hợp đồng Phase 3.
2. Thêm request module `classAssignments.ts` + type tương ứng, theo đúng convention path thật `/sessions/{id}/classes` (không tiền tố `/api/...`).
3. Sửa `CreateSessionModal.tsx` + `validateCreateSession.ts` sang chọn skill bằng checkbox thay vì `Select` blueprint; xóa `useBlueprints()` khỏi `api/index.ts`.
4. Thêm `ClassAssignmentSection.tsx` + 3 hook mới (`useAssignedClasses`/`useAssignClass`/`useUnassignClass`) trong `api/index.ts`, gắn vào `SessionDetailView.tsx` cạnh section Students hiện có — disable nút assign/unassign khi `session.status !== "SCHEDULED"`.
5. Gỡ toàn bộ luồng batch-theo-Program: xóa `CreateSessionForProgramModal.tsx`, `useBulkCreateSessionForProgram`/`splitIntoBatches`/`batchSessionName`, điểm gọi trong `ProgramDetailView.tsx`, các type/constant liên quan.
6. Grep `pte-web/apps/tenant-web` xác nhận không còn tham chiếu `Blueprint`/`useBlueprints`/`CreateSessionForProgramModal`/`BulkCreateSessionsForProgramInput` **và** không có bất kỳ import/gọi nào tới `/questions` hay `requests/question` (xác nhận lại quyết định "host không được xem/sửa question bank" — tenant-web chưa từng có màn này, bước này chỉ để chắc chắn không phát sinh mới).
7. Verify `tsc --noEmit`/`eslint`/build sạch cho `tenant-web` + `api-client`.

## Tests

- Không có bộ test UI tự động cho `tenant-web` hôm nay (theo cùng tiền lệ Plan A/Phase 6) — verify bằng `tsc --noEmit`, `eslint`, build.
- Nếu `validateCreateSession.ts` có unit test sẵn (thuần logic, không DOM) thì cập nhật/thêm case: `skills` rỗng → lỗi, `skills` > 4 phần tử → lỗi (nếu UI cho phép chọn quá 4 — checkbox 4 lựa chọn cố định thì trường hợp này không thể xảy ra, chỉ cần test rỗng).

## Success Criteria

- Tạo kỳ thi mới không còn bước chọn blueprint hay chọn câu hỏi — chỉ chọn skill; submit gọi đúng 1 request `POST /sessions` với `skills`.
- Lỗi thiếu bank (422 từ Phase 2) hiển thị được cho host (không crash, không nuốt lỗi âm thầm) — tối thiểu hiển thị `message` chung; hiển thị chi tiết từng dạng thiếu là cải tiến tốt nhưng không bắt buộc để coi phase xong.
- Assign 2 Class có 1 học sinh chung từ UI này phản ánh đúng backend (Phase 4) — verify tay qua roster hiển thị đúng số học sinh distinct.
- `grep -r "CreateSessionForProgramModal\|useBulkCreateSessionForProgram\|useBlueprints" pte-web/apps/tenant-web` → 0 kết quả; `grep -r "/questions" pte-web/apps/tenant-web` → 0 kết quả.
- `tsc --noEmit`/`eslint`/build sạch cho `tenant-web` và `api-client`.

## Risks

- MEDIUM: Sửa `SESSION_ENDPOINTS` ảnh hưởng MỌI hàm trong `sessions.ts` (`listSessions`, `getSession`, `openSession`, `closeSession`) — nếu path cũ vô tình đã "đúng" nhờ một lớp proxy nào đó không được phát hiện trong lúc khảo sát, sửa path có thể làm vỡ các luồng đang chạy được; mitigation: verify path thật bằng cách gọi thử 1 request tới backend thật (hoặc đọc cấu hình proxy/rewrite của `next.config`) trước khi sửa, không chỉ tin vào so sánh tĩnh với `@RequestMapping`.
- LOW: `CREATE_SESSION_FOR_PROGRAM_TEXT`/`ERRORS` có thể được tham chiếu ở nơi khác ngoài `exams` feature (vd `programs` feature import trực tiếp) — grep trước khi xóa, không chỉ xóa theo suy đoán từ tên file.
