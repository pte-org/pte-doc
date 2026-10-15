# Phase 05: Proctor overview and schedule

**Status:** Completed
**Stories:** US-02, US-03, US-09
**Depends on:** Phase02..04

## Goal

Host thấy phân công coi thi theo thời gian, không tạo chứng cứ attendance giả.

## Work items

1. Overview dùng common StatCard/Card cho tổng ca được phân công, upcoming/ongoing/ended; canceled/unscheduled riêng theo actual contract. Distinct exams phụ nếu API support.
2. Hiển thị next assigned sessions bằng bounded data; dual-role overview có hai section rõ ràng, không cộng ca Proctor và Examiner thành KPI cùng đơn vị.
3. Lịch coi thi mặc định date-grouped list/table; role/duty, exam/session labels, opensAt/closesAt/status và details action. Không port FullCalendar.
4. Common filter toolbar/date inputs + dropdown exam/session/status lấy tenant API; display zone, Apply/Clear reset page; all filtering server-side.
5. Ca thiếu timestamp show chưa có lịch, date-filter semantics theo contract. Cancelled không gọi hoàn thành nhiệm vụ.
6. Details route Host existing owned session path; validate actual session route segments thay vì hardcode đoán; không link proctor console.
7. Loading/refresh/empty/error/stale states common, paging retains filter; label phạm vi chỉ assignment còn tồn tại.

## Design Constraints

Preflight: existing session list API supplies tenant session options; workload reads remain dedicated bounded staff endpoints. Common CollapsibleSection/StatCard/DataTable/Select/Input/PaginationControls own visuals; feature owns server filters, page-local date grouping and role adapters. Existing Host detail route uses session publicId. Applicable: server-derived totals, lifecycle vs attendance distinction, Apply/reset, half-open UTC bounds and no raw errors. No visual exceptions/new dependencies.

Execution: Standard --no-tests --quality --checks-all-phases, automatic continuation. Next-session preview uses a bounded scheduled, not-yet-ended query and explicitly includes overdue awaiting-open sessions; it does not claim every returned start is in the future (existing date API uses overlap).

## Files

pte-web: packages/api-client/src/requests/scheduling/sessions.ts (optional AbortSignal); features/examStaff/detail/filters/{api.ts,StaffFilterToolbar.tsx}; detail/proctor/{ProctorOverview.tsx,ProctorScheduleTab.tsx,ProctorSessionList.tsx,NextProctorSessions.tsx}; detail/components/{StaffProfileSnapshot.tsx,StaffDetailView.tsx}; detail/messages/{en.ts,vi.ts}; detail/{api.ts,constants.ts}. Tenant session options reuse existing list endpoint; no workload filtering/counting is performed on that option list.

- Không frontend fan-out per session, không client aggregate ca total.
- Không label đã coi nếu chỉ biết session ended.
- Không sửa assignment/scheduling commands hoặc thêm attendance entity.
- No calendar/DnD new dependencies.

## Focused verification

- Schedule DTO to presentation/date grouping/count labels; time boundary/cancelled/null dates.
- Request filter Apply/Clear/page reset và unauthorized query mapping.
- Manual user check timezone labels/details routes/empty/error and mobile readable rows; no claim from Node tests.

## Quality and Testing State

- Implementation: complete; US-02/03/09 connected to bounded server projections and stock common UI.
- Quality: independent APPROVED after preview-time remediation; report/receipt in quality/phase-05-proctor-overview-and-schedule-{quality-report,receipt}.json.
- Verification: tenant tsc --noEmit, scoped eslint features/examStaff, API-client typecheck and git diff --check exit 0. No tests written/run by user choice.
- User checkpoint: manual UI pending; automatic continuation authorized.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

Count/filter/list dùng cùng server semantics và dữ liệu thật; session details ở Host route.
