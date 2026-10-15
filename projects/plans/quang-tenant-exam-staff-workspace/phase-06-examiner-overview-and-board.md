# Phase 06: Examiner overview and tracking board

**Status:** Completed
**Stories:** US-02, US-04, US-08, US-09
**Depends on:** Phase02..04; có thể độc lập Phase05

## Goal

Host theo dõi tải/tiến độ chấm theo ca với board/table read-only.

## Work items

1. Examiner overview: session work counts pending/inProgress/completed, assigned attempts và submitted/eligible answers là units riêng; published badge độc lập.
2. Tạo presentation-only Board primitive @pte/ui nếu audit không có: column headings/counts/card slots/loading/empty/error/pagination callbacks. Responsive horizontal board hoặc vertical stacked theo shared layout; keyboard access không DnD.
3. Card feature adapter: exam/session name, schedule/context, workload counts/progress, publication/session status; default common visual controls, no fictional deadline.
4. Supplemental batches gộp một card theo session ID; card/action đi Host session details/read context, không Examiner personal scoring route.
5. Three columns PENDING/IN_PROGRESS/COMPLETED, independent pagination/load-more; totals từ server full filter, show loaded vs total khi chưa tải hết; no grouping one table page pretending full board.
6. Board/table share API projection/base filters và target ID. Status selector chọn visible columns; table uses same workStatus predicate, deterministic sort.
7. Progress null/unavailable/zero-work/inconsistent phải có copy rõ; không giả 0 điểm/100% và không display progress trên 100%. Phân biệt completion kỹ thuật zero eligible với thực sự đã chấm.
8. Filter date/exam/session/workStatus/publication theo phase01/API; Clear reset all column cursors/pages; query errors một cột không biến toàn board thành zero.
9. Board refresh mới mỗi request lifecycle rõ; không polling/realtime dependency tự thêm. Published session vẫn hiển thị history.

## Design Constraints

Preflight: stock DashboardCard/CollapsibleSection/DescriptionList/StatusBadge/ProgressBar/PaginationControls own visuals, with a layout-only generic Board and BoardColumn in @pte/ui (no existing board found). Examiner feature owns DTO adaptation, independent column server predicates, applied filters and nullable progress. Date/session/publication predicates share one base; work-status selector changes visible columns/table predicate, never client official totals. Unavailable has its own paged exception list. No styling overrides, DnD, dependencies or scoring commands.

Execution: Standard --no-tests --quality --checks-all-phases; automatic continuation authorized. Phases 01–05 approved.

## Files

pte-web: packages/ui/src/components/{Board.tsx,index.ts}; apps/tenant-web/features/examStaff/detail/examiner/{ExaminerOverview.tsx,ExaminerProgress.tsx,ExaminerSessionCard.tsx,ExaminerSessionTable.tsx,ExaminerWorkColumn.tsx,ExaminerBoard.tsx,ExaminerTable.tsx,ExaminerTrackingTab.tsx}; detail/components/{StaffProfileSnapshot.tsx,StaffDetailView.tsx}; detail/messages/{en.ts,vi.ts}; detail/{constants.ts,types.ts}; detail/hooks/useStaffWorkspaceFilters.ts. Applied filter revision resets column pages even when Apply/Clear produces the same base query.

- Record unavailable/inconsistent có count và danh sách ngoại lệ read-only; tổng ba cột cộng count ngoại lệ phải khớp totalSessions, không âm thầm bỏ record.
- Danh sách ngoại lệ có page/size/total độc lập qua technical UNAVAILABLE query bucket; ALL table bao gồm nó, không thêm persisted workflow enum.
- Read-only: no drag/drop,status patch,score editing,batch confirm/preview or impersonation.
- Board generic props không scoring status/business queries.
- Eligible/submitted derive backend; không sort/filter/aggregate official totals client.
- Không leak answer contents/scores qua profile tracking.

## Focused verification

- Session aggregation presentation, zero eligible/unavailable/mixed stats mapping, card key dedupe.
- Per-column pages/counts/filter reset/partial error/status selection/table consistency.
- Manual user checks keyboard/375px overflow/light-dark/long card text; Node tests không prove rendered board.

## Quality and Testing State

- Implementation: overview/board/table connected, read-only role adapter and independent server pages complete; US-02/04/08/09 implemented.
- Quality: independent APPROVED, zero blockers; report/receipt in quality/phase-06-examiner-overview-and-board-{quality-report,receipt}.json. Receipt verified VALID.
- Verification: tenant tsc, API-client/UI typecheck, vendor tsc, scoped feature/common lint and tenant production build exit 0. Common lint emits existing Next no-pages warning; no production error.
- Testing: not_started; user declined writing/running tests. Browser/database/manual UI not validated.
- User checkpoint: manual UI pending; automatic continuation authorized.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

Board and table totals/filter agree; no forbidden scoring commands; common primitive audited with actual staff consumer.
