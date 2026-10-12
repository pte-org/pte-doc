# Phase 04: Common profile, route and account

**Status:** Completed
**Stories:** US-01, US-05..07, US-09
**Depends on:** Phase01 constraints; integration sau Phase03

## Goal

Learner và Exam Staff cùng presentation system, domain/state vẫn độc lập.

## Work items

1. Audit @pte/ui/current consumers trước tạo component. Extract generic ProfileHeader/ProfileLayout hoặc nhỏ hơn nếu existing components đủ; props là presentation slots, không StudentDetailResponse/Role switch.
2. Migrate Learner header/layout sang common mà không đổi current Overview default, Student-code copy, inline account edit, history/performance contract.
3. Split StudentDetailView/action state và text hook theo responsibility khi chạm; functions <150/files <300, avoid dumping both staff+student logic vào shared component.
4. Staff thin route /host/exam-staff/[staff-id], awaited params theo installed Next docs. loading.tsx reuse loading common, error.tsx installed API plus query retry states.
5. ExamStaffView view-detail router.push same tab, remove modal path riêng staff nhưng không delete AccountDetailsModal nếu còn consumers.
6. Breadcrumb registration scoped pathname, root danh sách không Home; detail Exam Staff > fullName, không extra back link. Common PageHeader/ActionMenu default ellipsis.
7. Header staff fullname/email/role badges/status; student-only metadata không xuất hiện. Profile tabs quyết định trong feature từ entire role set, Overview first.
8. Account read-only DescriptionList; Edit bên phải chuyển editable fields thành common Input cùng vị trí. Save/Cancel/validation/dirty navigation confirmation theo common existing UX.
9. Giữ lifecycle và send credential email common dialogs; account-wide confirmation cho dual roles. Không show password notice/copy student code trong staff.

## Design Constraints

Preflight: @pte/ui already owns Avatar/PageHeader/ActionMenu/Tabs/TabPanel/DescriptionList/Button/Input/ConfirmDialog/loading/error. Extract only domain-neutral profile composition with slots; retain existing visual defaults and Student actions in Student feature. Hooks/state/messages stay feature-owned, same-tab Next navigation and awaited params follow installed Next 16 docs. Components <150 lines/files <300; no new dependencies or visual override exceptions.

Execution: Standard --no-tests --quality --checks-all-phases, automatic continuation authorized; independent review and typechecks retained.

## Files

pte-web: packages/ui/src/components/{ProfileHeader.tsx,ProfileLayout.tsx,ProfileAccountPanel.tsx,index.ts}; apps/tenant-web/features/studentDetail/components/{StudentDetailHeader.tsx,StudentDetailView.tsx,StudentAccountTab.tsx,StudentActionDialogs.tsx}; studentDetail/hooks/useStudentDetailActions.ts. Staff detail components/{StaffDetailView.tsx,StaffProfileHeader.tsx,StaffAccountTab.tsx,StaffAccountDescription.tsx,StaffActionDialogs.tsx,StaffWorkspaceError.tsx}; detail/hooks/{useStaffAccountForm.ts,useStaffAccountActions.ts,useStaffEditGuard.ts}; detail/index.ts. app/(dashboard)/host/exam-staff/[staffPublicId]/{page.tsx,loading.tsx,error.tsx}; features/examStaff/components/{ExamStaffView.tsx,ExamStaffListDialogs.tsx}; features/examStaff/hooks/{useExamStaffListText.ts,useExamStaffListColumns.tsx}. Role work tabs use API-connected placeholders until phases 05–06, not claimed complete.

- User explicitly forbids visual overrides: default fonts/sizes/colors/trigger, no global typography migration.
- Không shared module import feature hooks/DTOs; feature adapter owns mutation/draft.
- Không thêm unsupported profile fields/avatar upload/role editor.
- Không dùng native link làm internal route full reload.

## Focused verification

Scope refinement: staff list now uses existing server-paged useExamStaff and stock DataTable search/dropdowns, no all-pages client filtering. Additional outputs: features/examStaff/constants.ts; components/ExamStaffRowActions.tsx (reuses feature-owned account actions/dialogs; the planned ListDialogs extraction is unnecessary); detail/components/StaffProfileSnapshot.tsx (temporary API-connected overview until role phases). No AccountDetailsModal deletion for unrelated consumers.

Remediation scope also updates detail/api.ts: mutation installs canonical profile response into the exact tenant/target detail cache before re-edit/remount; cancels stale detail fetches and guards the captured auth generation. Phase03 receipt must be refreshed because this shared output changed.

- Focused role-tab composition/account whitelist/input draft/cancel/save mapping helper tests.
- Scoped lint/typechecks @pte/ui/tenant/vendor; Learner affected helper regressions.
- Manual checklist deep link/same-tab/no full reload, keyboard/375px/dark/long names/emails, query errors; user owns UI validation.

## Quality and Testing State

- Implementation: shared presentation and Student migration, staff same-tab route/account/actions, server-filtered list implemented. Role work surfaces remain for phases 05–06.
- Quality: APPROVED after two remediation cycles; both findings resolved. Canonical report and receipt in `quality/phase-04-common-profile-and-account-{quality-report,receipt}.json`; receipt verified VALID. Shared Phase03 mutation output independently re-reviewed and its receipt refreshed VALID.
- Testing: not_started; user declined tests. UI/tenant/vendor typechecks, scoped ESLint and tenant production build passed; remediation lint/tenant tsc also passed. No browser/live API validation.
- User checkpoint: automatic continuation authorized; manual UI review at the end.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

Hai consumers thật dùng common; Learner behaviors preserved; account mutations staff-owned, no UI override shortcuts.
