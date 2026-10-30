# Spec: Ngày thi (mục tiêu học tập) trên Trang chủ pte-practice

**Date:** 2026-10-25
**Status:** Draft
**Repo:** `pte-api` (module `practice`), `pte-practice`
**Brainstorm:** [../reports/261025-hung-practice-exam-date-brainstorm.md](../reports/261025-hung-practice-exam-date-brainstorm.md)

---

## Problem Statement
Trang chủ luôn hiện "Exam date: Not scheduled" và không có cách đặt. Học viên cần ghi ngày thi của mình để có mục tiêu học tập, giống app PTE tham chiếu ("Ngày thi: 7 tháng 11").

---

## User Stories

- **[P1]** Là học viên, tôi muốn đặt ngày thi của mình ngay trên Trang chủ.
  Accepted when: bấm cây bút cạnh "Ngày thi" → chọn ngày → lưu → dòng hiện "Ngày thi: 7 tháng 11" (vi) / "Exam date: 7 November" (en); tải lại trang hoặc đăng nhập máy khác vẫn thấy cùng ngày.
- **[P1]** Là học viên, tôi muốn sửa hoặc xoá ngày thi.
  Accepted when: bấm bút khi đã có ngày → chọn ngày khác hoặc bấm "Xoá ngày thi" → dòng cập nhật ("Chưa đặt lịch" khi xoá).
- **[P2]** _(sau)_ Đếm ngược số ngày, điểm mục tiêu so với điểm ước lượng.
- **[P3]** _(ngoài phạm vi)_ Trung tâm xem/đặt ngày thi cho học viên.

---

## Functional Requirements

1. FR-01: Migration **V135** `practice_student_profiles` (`id`, `public_id`, audit + `deleted`, `student_public_id uuid unique not null`, `tenant_id uuid not null`, `exam_date date null`, `version`).
2. FR-02: `GET /api/v1/student/practice/profile` → `{ examDate: "YYYY-MM-DD" | null }` (chưa có hàng → null). `PUT` cùng path body `{ examDate: "YYYY-MM-DD" | null }` → lưu (upsert theo học viên), trả cùng dạng. Quyền `hasRole('STUDENT')`, chỉ hồ sơ của chính mình.
3. FR-03: Validate: ngày không được trước hôm nay (theo `Asia/Ho_Chi_Minh` — **[Quyết định của Claude]**) và không quá 2 năm tới; sai → 422 `PRACTICE_EXAM_DATE_INVALID`. `null` = xoá.
4. FR-04: Trang chủ: icon lịch + "Ngày thi: {ngày}" hoặc "Chưa đặt lịch", cây bút (`AppIcon` `edit`) bên cạnh mở `Modal` có `<input type="date">` (min hôm nay, max +2 năm), nút "Lưu", "Xoá ngày thi", "Đóng". Lưu thành công → toast success; lỗi → toast error.
5. FR-05: Định dạng ngày theo locale: vi "7 tháng 11", en "7 November"; khác năm hiện tại thì thêm năm ("7 tháng 11, 2027").
6. FR-06: Chuỗi mới qua i18n (en/vi).

---

## Non-Functional Requirements
- Performance: `GET /profile` p95 < 100 ms local; tải cùng lúc với entitlement, không chặn render Trang chủ.
- Security: chỉ đọc/ghi hồ sơ của `CurrentUser`; không nhận `studentId` từ client.

---

## Success Criteria
- [ ] Đặt 7/11 → Trang chủ hiện "Ngày thi: 7 tháng 11"; DB có 1 hàng cho học viên.
- [ ] Đăng nhập lại (xoá localStorage) → vẫn hiện ngày đó.
- [ ] Chọn ngày quá khứ → 422, toast lỗi, ngày cũ giữ nguyên.
- [ ] Xoá → "Chưa đặt lịch", `exam_date` null.
- [ ] BE test service/controller mới pass; FE tsc/eslint/vitest xanh.

---

## Out of Scope
- Đếm ngược, điểm mục tiêu, nhắc lịch, trung tâm quản lý ngày thi.

## Decisions
- **[Đã chốt]** Chỉ ngày thi, có cây bút để sửa; lưu trên server theo tài khoản.
- **[Quyết định của Claude]** Bảng riêng trong module practice (không sửa bảng `users` của identity) để giữ ranh giới Modulith; múi giờ `Asia/Ho_Chi_Minh` khi kiểm tra "không phải quá khứ"; giới hạn 2 năm.
