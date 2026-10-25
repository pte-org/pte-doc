# Plan: Ngày thi (mục tiêu học tập) trên Trang chủ pte-practice

Status: Completed
Date: 2026-10-25
Mode: Fast (2 phase, pattern quen: một bảng + GET/PUT + một modal)
Test: default
Owner/slug: Hung — `261025-hung-practice-exam-date`
Scope: `pte-api` (module `practice`), `pte-practice`
Related: [spec](./spec.md), [brainstorm](../reports/261025-hung-practice-exam-date-brainstorm.md)

Nhánh `hung/feat/practice-revamp`; không commit khi Hung chưa bảo.

## Phases

- [x] Phase 1: Backend — V135 + API hồ sơ ngày thi — [phase-01-backend-exam-date.md](./phase-01-backend-exam-date.md) [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 2: Frontend — dòng Ngày thi + cây bút + modal, kiểm chứng — [phase-02-frontend-exam-date.md](./phase-02-frontend-exam-date.md) [quality: skipped_by_user; decision: user_confirmed_skip]

## Phase → story
| Phase | Stories | FR |
|---|---|---|
| 1 | Đặt / sửa / xoá ngày thi (P1) phần BE | FR-01, 02, 03 |
| 2 | Đặt / sửa / xoá ngày thi (P1) phần FE + mọi tiêu chí | FR-04, 05, 06 |

## Risks
- Ranh giới Modulith → bảng riêng trong practice, không đụng `users`.
- Lệch ngày do múi giờ → kiểm tra theo `Asia/Ho_Chi_Minh`, truyền `LocalDate` dạng `YYYY-MM-DD`; FE định dạng bằng `Intl.DateTimeFormat` với `timeZone: "UTC"` trên ngày đã parse để không lùi một ngày.
