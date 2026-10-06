# Brainstorm: Assign Students → Learner screen with prefill

**Date:** 2026-09-27

## Ideas Explored

1. **Deep-link + URL query params** (đã chọn) — khi click `Assign Students` ở ClassesSection row, navigate sang `/host/students?organizationPublicId=&programPublicId=&classPublicId=`. Students page parse params trong useEffect đầu, set filters, build `Breadcrumb`, auto-open `ManageStudentsModal` với `initialMode="add"`.
2. **SessionStorage handoff** — click Assign Students lưu (orgId, programId, classId) vào sessionStorage, Students page đọc lại và clear. Pros: URL clean. Cons: mất context khi user refresh/shares link, phụ thuộc vào timing read.
3. **Giữ `ImportOrAssignModal` ở Classes feature** — không navigate, làm mọi thứ trong class context. Pros: không rời context. Cons: đã chốt ở round trước là modal này hoạt động kém (đã đi đến learner là use case thực).

## User's Direction

**Chốt**: Deep-link qua query params. Sau khi navigate vào `/host/students`:
- Filters: `organizationPublicId`, `programPublicId`, `classPublicId` pre-fill từ URL
- Auto-open `ManageStudentsModal` với `initialMode="add"` (Add Individually)
- Breadcrumb `← Back to {Class name}` ở đầu page, link về `/host/programs/:programId/classes/:classId?organizationPublicId=...`
- Nếu class INACTIVE/SUSPENDED → block, show inline error thay vì mở modal
- Lock filter (program + class) — nếu user cancel modal, page vẫn giữ filter lock và show banner `Showing students for {class}. Clear filter to add to other classes.` Click banner `Clear filter` mở khóa.
- Duplicate enrollment handling: silent dedupe (server-side, no UI warning)
- Sources: chỉ 2 surface — ClassesSection row + ClassesListView row

Lý do user:
- Bấm Assign Students là có intent "thêm student vào class này cụ thể" → state sẵn là tốt
- Modal bị reopen chỉ 1 lần → giảm friction
- Breadcrumb giúp user quay về chỗ cũ sau khi xong
- Lock filter tránh user vô tình nhầm class khác sau khi cancel

## Open Questions

1. Khi user **tự thay đổi** Program/Class filter trong dropdown (không qua banner "Clear filter"), có nên unlock intent và dismiss banner hay giữ lock + remove filter?

   Gợi ý: nếu user đổi filter thủ công, đó là explicit clear → dismiss banner + reset context. Nhưng đây là UX detail có thể implement trong /ck:plan.

2. Có cần giữ URL params đồng bộ với state không (vd. user thay đổi filter → push URL mới) hay chỉ parse một lần ở mount?

   Gợi ý: chỉ parse once, không replace router state. Đơn giản, không có navigation history bị pollute. Nếu user back qua browser Back button, sẽ quay lại trang trước đó — đúng UX intent.

3. Có cần `assignMode=add` query param để distinguish "auto-open modal" vs "user thường"? Hay set `manageMode` qua React state trong page?

   Gợi ý: không cần query param. Page check khi mount: nếu cả 3 params `programPublicId` + `classPublicId` có giá trị + class status ACTIVE → set `manageMode="add"` trong useEffect. Không cần URL pollution.

## Risks

1. **Class status race**: nếu class bị SUSPENDED ngay sau khi user click Assign Students (trước khi Students page mount) → URL vẫn có classId, page phải re-fetch và hiển thị error. Risk thấp nhưng cần handle.

2. **ManageStudentsModal ở /host/students chỉ có 2 modes** (add, import), không có "Pick Existing". User chọn `add` (Add Individually). Nếu user muốn thêm student đã có sẵn, họ phải đổi sang student thường hoặc dùng UI khác. Có thể gap UX nhưng scope này OK.

3. **Empty roster**: nếu student list sau khi filter class đó = 0 (class mới tạo, chưa có student), modal vẫn mở — user tạo 1 student mới thông qua Add Individually. Behavior này đúng intent.

4. **Cross-org scoping**: Nếu user click Assign Students ở class trong Org A, nhưng page Students mặc định Org B → phải force selectOrg = URL orgId. Trong codebase hiện tại, `useMyOrganizations()` trả list — page tự chọn org đầu. Cần override set `selectedOrganizationPublicId` từ URL ngay khi mount, bằng cách truyền vào page như `?organizationPublicId=...` qua `useEffect`.

5. **Browser refresh**: URL có đầy đủ params → refresh → state vẫn prefill + auto-open modal. Đúng intent. Có thể hơi annoying nếu user đã đóng modal mà refresh sẽ mở lại — nhưng acceptable.
